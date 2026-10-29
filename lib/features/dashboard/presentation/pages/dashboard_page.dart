import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/app_pause.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/share_intent_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/coachmark.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../companion/data/pet_store.dart';
import '../../../companion/domain/companion_style.dart';
import '../../../companion/domain/pet_state.dart';
import '../../../companion/presentation/pet_labels.dart';
import '../../../companion/presentation/widgets/blob_mascot.dart';
import '../../../companion/data/pet_inbox.dart';
import '../../../companion/data/pet_sync.dart';
import '../../../companion/presentation/widgets/pet_host.dart';
import '../../../companion/presentation/widgets/pet_inbox_sheet.dart';
import '../../../companion/presentation/widgets/pet_naming_sheet.dart';
import '../../../companion/presentation/widgets/pet_offline.dart';
import '../../../companion/presentation/widgets/pet_profile_sheet.dart';
import '../../../companion/presentation/widgets/pet_wardrobe_sheet.dart';
import '../../../vault/data/datasources/metadata_remote_datasource.dart';
import '../../../vault/data/models/url_metadata.dart';
import '../../../vault/domain/entities/note_entity.dart';
import '../../../vault/domain/repositories/auto_summarize_repository.dart';
import '../../../vault/domain/usecases/add_note.dart';
import '../../../vault/domain/usecases/auto_summarize.dart';
import '../../../vault/presentation/bloc/vault_bloc.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/note_draft.dart';
import '../bloc/dashboard_cubit.dart';
import '../widgets/coin_drop.dart';
import '../widgets/meal_bubble.dart';
import '../widgets/mosquito_hunt.dart';
import '../widgets/pet_scene.dart';
import '../widgets/pet_visitor.dart';
import '../widgets/quick_save_bar.dart';
import '../widgets/scribe_review_sheet.dart';

part 'dashboard_widgets.dart';

/// Beranda — a calm corner where the pet lives.
///
/// Paste a link and it's saved on the spot; the pet eats it (saved
/// knowledge is its food), which keeps it full and growing from egg to
/// sage. Between visits it naps on its cushion, wanders a little, and
/// fans out today's saves when you tap the index card.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  final _blob = BlobController();
  final _store = sl<PetStore>();
  final _rng = math.Random();
  // Both made in initState, not on first use: dispose() must never be what
  // makes one, since that looks up the (by then deactivated) context.
  late final AnimationController _walk;

  /// How far back towards the wall it has walked (0 on the rug).
  late final AnimationController _depth;

  DashboardData? _data;

  /// What the pet just said in reaction to something; wins over the mood
  /// line while it lasts.
  String? _status;
  Timer? _statusTimer;

  /// The mood line ("Kenyang dan senang") only pops up now and then — on
  /// arrival, when the mood changes, and every so often — so the pet
  /// isn't talking non-stop.
  bool _idleVisible = true;
  Timer? _idleTimer;
  Timer? _chatter;
  CompanionMood? _lastMood;

  Timer? _clock;
  Timer? _wander;
  DateTime _lastPetLine = DateTime(0);

  /// A friend dropping by now and then (an easter egg), and when the next
  /// one might.
  VisitPlan? _friendVisit;
  Timer? _visitTimer;

  /// A mosquito buzzing in now and then (another easter egg): the pet
  /// chases it and gobbles it up.
  MosquitoPlan? _mosquito;
  Timer? _mosquitoTimer;

  /// Rolling off one side of the room and back in from the other.
  bool _rolling = false;

  bool _resting = false;
  bool _walking = false;
  bool _saving = false;

  /// Up in your hand, or still dizzy / sulking after being dropped.
  bool _held = false;

  /// Its pocket money, spilled on the floor when it's shaken about.
  final _coins = CoinController();

  /// It has already cried out about its coins while being held this time.
  bool _coinsSaid = false;
  bool _grumpy = false;

  /// Bumped on every pick-up so lines queued after a drop don't play if
  /// it's been picked up again since.
  int _liftGen = 0;

  /// Link this page asked VaultBloc to save, so we know the result is ours.
  String? _pendingLink;

  bool _fanOpen = false;
  int _fanPage = 0;

  /// The link bar's text — links shared from other apps land here.
  final _linkCtrl = TextEditingController();
  final _linkFocus = FocusNode();

  /// What the first-visit tours light up.
  final _saveBarKey = GlobalKey();
  final _mealKey = GlobalKey();
  final _feastKey = GlobalKey();
  final _stripKey = GlobalKey();

  /// The pet's inbox — the bell up top, and whether this week's quiz is
  /// still new (the calendar's dot).
  final _petInbox = sl<PetInbox>();
  final _inbox = ShareIntentService.instance.forHome;

  /// A link shared while the pet was busy writing another one up.
  String? _queuedShare;

  /// The pet writing a link up (or showing you the page), and what it
  /// wrote.
  ScribePhase? _scribe;
  NoteDraft? _draft;

  /// This week's quiz hasn't been opened yet — the calendar shows a dot.
  SharedPreferences? _prefs;
  static const _kQuizNudged = 'quiz.nudgedOn';

  @override
  void initState() {
    super.initState();
    _walk = AnimationController.unbounded(vsync: this);
    _depth = AnimationController(vsync: this);
    _inbox.addListener(_takeSharedLink);
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeSharedLink());
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      _prefs = prefs;
      _nudgeQuiz();
      _nudgeFeast();
    });
    context.read<DashboardCubit>().load();
    _clock = AppTimer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _catchUp();
    });
    _scheduleIdle();
    _later(const Duration(milliseconds: 1500), _howTo);
    _later(const Duration(milliseconds: 1200), _coachTour);
    _petInbox.addListener(_announceNews);
    _later(const Duration(milliseconds: 1800), _announceNews);
    _idleTimer = AppTimer(const Duration(seconds: 8), _hideIdle);
    _scheduleChatter();
    _scheduleVisit(first: true);
    _scheduleMosquito(first: true);
    _blob.crying.addListener(_onCrying);
    ConnectivityService.instance.online.addListener(_onNetwork);
    AppPause.instance.addListener(_onAppPause);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Whether Beranda is on screen. The tabs stay alive in the background,
    // so the pet only eats, chats and the bell only rings while you can
    // see it.
    final visible = TickerMode.getNotifier(context);
    if (visible != _visible) {
      _visible?.removeListener(_onShown);
      _visible = visible..addListener(_onShown);
    }
  }

  ValueListenable<bool>? _visible;

  bool get _onScreen => (_visible?.value ?? true) && !AppPause.instance.paused;

  /// Back from the background: the clock catches up, and the pet eats
  /// whatever was saved meanwhile.
  void _onAppPause() {
    if (!mounted || AppPause.instance.paused) return;
    setState(() {});
    _onShown();
  }

  /// Back on Beranda: it eats whatever was saved while you were away.
  void _onShown() {
    if (mounted && _onScreen) {
      _catchUp();
      _nameWaits = 0;
      _later(const Duration(milliseconds: 900), _coachTour);
    }
  }

  /// News the bell has already rung for (this session), so it rings once
  /// per new thing — not every time you come back to Beranda.
  static final _rungFor = <String>{};

  /// Rings the bell when something new lands in the pet's inbox while
  /// Beranda is showing.
  void _announceNews() {
    if (!mounted || !(_visible?.value ?? false)) return;
    final fresh = _petInbox.unreadIds(DateTime.now()).difference(_rungFor);
    if (fresh.isEmpty) return;
    _rungFor.addAll(fresh);
    SoundService.instance.play(Sfx.bell);
  }

  @override
  void dispose() {
    _petInbox.removeListener(_announceNews);
    _blob.crying.removeListener(_onCrying);
    ConnectivityService.instance.online.removeListener(_onNetwork);
    AppPause.instance.removeListener(_onAppPause);
    _visible?.removeListener(_onShown);
    _inbox.removeListener(_takeSharedLink);
    _linkCtrl.dispose();
    _linkFocus.dispose();
    _statusTimer?.cancel();
    _idleTimer?.cancel();
    _chatter?.cancel();
    _clock?.cancel();
    _wander?.cancel();
    _visitTimer?.cancel();
    _mosquitoTimer?.cancel();
    _walk.dispose();
    _depth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => curr is AuthProfileUpdateSuccess,
          listener: (_, __) => context.read<DashboardCubit>().load(),
        ),
        BlocListener<DashboardCubit, DashboardState>(
          listener: (_, state) {
            if (state is DashboardReady) _catchUp();
          },
        ),
        BlocListener<VaultBloc, VaultState>(
          listenWhen: (prev, curr) =>
              curr is VaultNoteAddSuccess || curr is VaultError,
          listener: (context, state) {
            if (state is VaultNoteAddSuccess) {
              // A little chime when it's the link saved from here.
              if (_pendingLink != null) {
                SoundService.instance.play(Sfx.noteSaved);
              }
              setState(() {
                _saving = false;
                _pendingLink = null;
              });
              // Out of sight, it eats this when you're back (_onShown).
              if (_onScreen) _feed([state.newNote], l10n);
              context.read<DashboardCubit>().load();
            } else if (state is VaultError && _pendingLink != null) {
              setState(() {
                _saving = false;
                _pendingLink = null;
              });
              _blob
                ..shake()
                ..express(BlobExpression.sad,
                    duration: const Duration(milliseconds: 2600));
              _setStatus(l10n.petStatusSaveFailed);
              context.showSnack(state.message, error: true);
            }
          },
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (_, state) {
            if (state is DashboardReady) _data = state.data;
            return ListenableBuilder(
              listenable: Listenable.merge([_store, _petInbox]),
              builder: (context, _) => _page(context, l10n, keyboard),
            );
          },
        ),
      ),
    );
  }

  /// [keyboard] comes from above this page's Scaffold: inside its body the
  /// keyboard inset has already been taken out.
  Widget _page(BuildContext context, AppLocalizations l10n, bool keyboard) {
    final palette = context.palette;
    final mq = MediaQuery.of(context);
    final now = DateTime.now();
    final pet = _store.state;
    final stage = pet.stage;
    final mood = _resting ? CompanionMood.sleepy : pet.moodAt(now);
    final name = l10n.petName(_store);
    final today = _todayNotes(now);
    final fanSlice = _fanOpen && today.isNotEmpty
        ? today.skip(_fanPage * 3).take(3).toList()
        : null;
    if (_lastMood != mood) {
      final first = _lastMood == null;
      _lastMood = mood;
      if (!first) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showIdle());
      }
    }
    // The egg keeps explaining how to hatch it; a hatched pet speaks up
    // only when it has something to say.
    final speech = fanSlice != null
        ? null
        : _status ??
            (_friendVisit == null && (_idleVisible || !pet.hatched)
                ? _moodLine(l10n, pet, mood)
                : null);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // A quiet greeting and whose place this is (tap for the pet's
            // profile).
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 14, 0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showPetProfile(context),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting(l10n, now)},',
                              style: AppFonts.body(
                                fontSize: 13,
                                color: palette.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              l10n.homeHouseTitle(name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.display(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ShopButton(onTap: () => context.push(Routes.shop)),
                  KeyedSubtree(
                    key: _feastKey,
                    child: _FeastButton(
                      pending: _feastPending(now),
                      onTap: () => _onFeast(l10n),
                    ),
                  ),
                  _Bell(
                    unread: _petInbox.hasUnread(now),
                    onTap: () => _openInbox(l10n),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: PetScene(
                        controller: _blob,
                        walk: _walk,
                        depth: _depth,
                        color: _store.color,
                        accessory: _store.accessory,
                        outfit: _store.outfit,
                        stage: stage,
                        mood: mood,
                        sleeping: mood == CompanionMood.sleepy &&
                            !_held &&
                            _scribe == null,
                        semanticsLabel: l10n.petSemantics(name),
                        todayCount: today.length,
                        fan: fanSlice,
                        onPet: () => _onPet(l10n, mood),
                        onPlay: () =>
                            _setStatus(l10n.petStatusPlayed, voice: false),
                        onBonk: (run) => _onBonk(run, l10n),
                        onGecko: () => _onGecko(l10n),
                        onAllCollections: () => context.push(Routes.tags),
                        onTodayTap: () => _toggleFan(l10n, today.length),
                        onFanCardTap: (n) =>
                            context.push('/vault/${n.id}', extra: n),
                        speech: speech,
                        canLift: pet.hatched &&
                            _scribe == null &&
                            !_rolling &&
                            !_blob.crying.value,
                        scribe: _scribe,
                        scribeTitle: _draft?.title,
                        scribeTags: _draft?.tags ?? const [],
                        onCalendarTap: () => _setStatus(l10n.homeCalendarToday(
                            MaterialLocalizations.of(context)
                                .formatFullDate(DateTime.now()))),
                        onLifted: () => _onLifted(l10n),
                        onLanded: (hard) => _onLanded(hard, l10n),
                        coins: _coins,
                        onCoinDropped: () => _onCoinDropped(l10n),
                        onSettled: (v) => _walk.value = v,
                        visit: _friendVisit,
                        // Off it goes if the pet gets busy or you start typing.
                        visitInterrupted: _visitBusy || keyboard,
                        onHostSay: (line, hold) => _setStatus(line, hold: hold),
                        onVisitDone: _visitDone,
                        mosquito: _mosquito,
                        mosquitoInterrupted: _visitBusy || keyboard,
                        onMosquitoChase: _chase,
                        onMosquitoDone: _mosquitoDone,
                      ),
                    ),
                  ),
                  // Today's meal: a bubble over the vitals (hunger, happiness,
                  // growth) at the bottom left.
                  if (_mealState(now) case final meal?
                      when !keyboard && !_fanOpen)
                    Positioned(
                      left: 20,
                      bottom: 2,
                      child: MealBubble(
                        key: _mealKey,
                        state: meal,
                        notes: _data?.totalNotes ?? 0,
                        needNotes: _mealsNeedNotes,
                        refused: _mealRefused,
                        onTap: () => _onMealBubble(meal, l10n),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            KeyedSubtree(
              key: _stripKey,
              child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _fanOpen && today.isNotEmpty
                  ? _FanControls(
                      key: const ValueKey('fan'),
                      page: _fanPage,
                      total: today.length,
                      onPrev: _fanPage > 0
                          ? () => setState(() => _fanPage--)
                          : null,
                      onNext: (_fanPage + 1) * 3 < today.length
                          ? () => setState(() => _fanPage++)
                          : null,
                      onClose: () => setState(() => _fanOpen = false),
                      onLibrary: () => context.go(Routes.vault),
                    )
                  : keyboard
                      ? const SizedBox(key: ValueKey('none'))
                      : _StatusStrip(
                          key: const ValueKey('status'),
                          name: name,
                          stage: l10n.stageLabel(stage),
                          hatched: pet.hatched,
                          fullness: pet.fullnessAt(now) / 100,
                          happiness: pet.happinessAt(now) / 100,
                          growth: stage.progress(pet.growth),
                          resting: _resting,
                          onProfile: () => showPetProfile(context),
                          onWardrobe: () => showPetWardrobe(context),
                          onToggleRest: () => _toggleRest(l10n),
                        ),
              ),
            ),
            SizedBox(height: keyboard ? 12 : 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: QuickSaveBar(
                key: _saveBarKey,
                controller: _linkCtrl,
                focusNode: _linkFocus,
                saving: _saving,
                onSubmit: (raw) => _scribeLink(raw, l10n),
                onClipboardEmpty: () =>
                    _setStatus(l10n.petStatusClipboardEmpty),
              ),
            ),
            SizedBox(
              height: keyboard
                  ? 12
                  : kEditorialNavBarOverlay +
                      math.max(mq.padding.bottom, 10) +
                      8,
            ),
          ],
        ),
      ),
    );
  }

  // ─── data ─────────────────────────────────────────────────────────────

  List<NoteEntity> _todayNotes(DateTime now) => [
        for (final n in _data?.recentNotes ?? const <NoteEntity>[])
          if (n.createdAt.year == now.year &&
              n.createdAt.month == now.month &&
              n.createdAt.day == now.day)
            n,
      ];

  /// Notes saved since the pet was born that it hasn't eaten yet (saved
  /// from another screen, or while it was too full) — eat them now.
  void _catchUp() {
    // The daily quiz opens once there are a few notes to ask about.
    final total = _data?.totalNotes;
    if (total != null) _petInbox.mealsUnlocked = total >= _mealsNeedNotes;
    if (!_onScreen) return;
    final born = _store.state.bornAt;
    final pending = [
      for (final n in _data?.recentNotes ?? const <NoteEntity>[])
        if (n.createdAt.isAfter(born) && !_store.state.hasEaten(n.id)) n,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (pending.isNotEmpty) {
      _feed(pending, AppLocalizations.of(context)!);
    }
  }

  // ─── pet ──────────────────────────────────────────────────────────────

  String _greeting(AppLocalizations l10n, DateTime now) {
    final h = now.hour;
    if (h >= 4 && h < 10) return l10n.greetingMorning;
    if (h >= 10 && h < 15) return l10n.greetingAfternoon;
    if (h >= 15 && h < 18) return l10n.greetingEvening;
    return l10n.homeGreetNight;
  }

  String _moodLine(AppLocalizations l10n, PetState pet, CompanionMood mood) {
    if (!pet.hatched) return l10n.petStatusEgg;
    return switch (mood) {
      CompanionMood.sleepy => l10n.petStatusResting,
      CompanionMood.hungry => l10n.petStatusHungry,
      CompanionMood.lonely => l10n.petStatusLonely,
      CompanionMood.happy => l10n.petStatusHappy,
      CompanionMood.content => l10n.petStatusReady,
    };
  }

  /// Shows [text] in the pet's bubble for [hold]. With [voice] the pet
  /// babbles it — off where the moment already has its own sound (a squeak,
  /// a chomp, a fanfare).
  void _setStatus(String text,
      {Duration hold = const Duration(seconds: 4), bool voice = true}) {
    _statusTimer?.cancel();
    if (voice && text != _status) SoundService.instance.chatter(text);
    setState(() => _status = text);
    _statusTimer = AppTimer(hold, () {
      if (mounted) setState(() => _status = null);
    });
  }

  void _showIdle({Duration hold = const Duration(seconds: 7)}) {
    if (!mounted) return;
    _idleTimer?.cancel();
    // It says how it's doing out loud — unless it's asleep, or something
    // else is already in the bubble.
    final pet = _store.state;
    final mood = _resting ? CompanionMood.sleepy : pet.moodAt(DateTime.now());
    if (_status == null && !_fanOpen && mood != CompanionMood.sleepy) {
      SoundService.instance
          .chatter(_moodLine(AppLocalizations.of(context)!, pet, mood));
    }
    setState(() => _idleVisible = true);
    _idleTimer = AppTimer(hold, _hideIdle);
  }

  void _hideIdle() {
    if (mounted) setState(() => _idleVisible = false);
  }

  /// Every so often the pet volunteers how it's feeling.
  void _scheduleChatter() {
    _chatter?.cancel();
    _chatter = AppTimer(Duration(seconds: 35 + _rng.nextInt(25)), () {
      if (!mounted) return;
      if (_onScreen &&
          _status == null &&
          !_walking &&
          !_fanOpen &&
          _friendVisit == null &&
          _mosquito == null &&
          !_blob.crying.value) {
        _showIdle(hold: const Duration(seconds: 6));
      }
      _scheduleChatter();
    });
  }

  void _later(Duration delay, VoidCallback fn) => AppTimer(delay, () {
        if (mounted) fn();
      });

  void _onPet(AppLocalizations l10n, CompanionMood mood) {
    _store.pet();
    // In tears: each stroke soothes it a little (see _onCrying for when
    // it stops).
    if (_blob.crying.value) {
      _setStatus(l10n.petStatusCrySoothe,
          hold: const Duration(minutes: 10), voice: false);
      return;
    }
    // Busy writing: the bubble keeps showing how that's going.
    if (!_store.state.hatched || _scribe != null) return;
    final now = DateTime.now();
    if (now.difference(_lastPetLine) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastPetLine = now;
    _setStatus(
        mood == CompanionMood.sleepy
            ? l10n.petStatusWoke
            : l10n.petStatusPetted,
        voice: false);
  }

  /// Picked up: it stops whatever it was doing and panics.
  void _onLifted(AppLocalizations l10n) {
    _liftGen++;
    _held = true;
    _grumpy = false;
    _coinsSaid = false;
    _walking = false;
    _walk.stop();
    _depth.stop();
    _blob.walk(0);
    if (_resting) setState(() => _resting = false);
    if (_fanOpen) setState(() => _fanOpen = false);
    _setStatus(l10n.petStatusLifted,
        hold: const Duration(minutes: 1), voice: false);
  }

  /// Shaken while it's held: its coins fall out — it cries out once.
  void _onCoinDropped(AppLocalizations l10n) {
    if (_coinsSaid) return;
    _coinsSaid = true;
    _setStatus(l10n.petStatusCoinsFalling,
        hold: const Duration(minutes: 1), voice: false);
  }

  /// Back on the floor: dizzy if it fell far, then a sulk, then it
  /// waddles back to its cushion — or, if it was shaken and its coins are
  /// all over the floor, it gathers them up first and tells you off.
  void _onLanded(bool hard, AppLocalizations l10n) {
    final gen = _liftGen;
    _held = false;
    _grumpy = true;
    void after(Duration d, VoidCallback fn) => _later(d, () {
          if (gen == _liftGen) fn();
        });
    if (_coins.count > 0) {
      if (hard) {
        _setStatus(l10n.petStatusDizzy,
            hold: BlobController.dizzyFor + const Duration(milliseconds: 300),
            voice: false);
      }
      after(hard ? BlobController.dizzyFor : const Duration(milliseconds: 600),
          () => _collectCoins(l10n));
      return;
    }
    if (hard) {
      _setStatus(l10n.petStatusDizzy,
          hold: BlobController.dizzyFor + const Duration(milliseconds: 300),
          voice: false);
      after(BlobController.dizzyFor, () {
        _setStatus(l10n.petStatusGrumpy,
            hold: BlobController.grumpyFor, voice: false);
      });
      after(BlobController.dizzyFor + BlobController.grumpyFor, _walkHome);
    } else {
      _setStatus(l10n.petStatusPutDown,
          hold: BlobController.softGrumpyFor + const Duration(seconds: 1),
          voice: false);
      after(BlobController.softGrumpyFor, _walkHome);
    }
  }

  /// Picks its coins up off the floor, one spot at a time — in a panic,
  /// scurrying from one to the next — then turns to you, cross: hands off
  /// its money. Stops if it's picked up again (the coins stay where they
  /// are until next time).
  Future<void> _collectCoins(AppLocalizations l10n) async {
    if (!mounted || _held) return;
    final gen = _liftGen;
    bool still() => mounted && gen == _liftGen && !_held;
    _grumpy = false;
    _walking = true;
    _setStatus(l10n.petStatusCoinsGather,
        hold: const Duration(minutes: 1), voice: false);
    // Wide eyes, a sweat drop, trembling: its money's all over the floor.
    _blob.express(BlobExpression.scared);
    var got = 0;
    var gathered = false;
    try {
      for (var tries = 0; still() && _coins.count > 0 && tries < 40; tries++) {
        final spot = _coins.nearest(_walk.value);
        if (spot == null) {
          // Some are still falling.
          await AppPause.delay(const Duration(milliseconds: 200));
          continue;
        }
        await _walkTo(spot, 0, pace: 1.7);
        if (!still()) return;
        _blob.focus(const Offset(0, 1));
        await AppPause.delay(const Duration(milliseconds: 180));
        if (!still()) return;
        got += _coins.pickUp(_walk.value);
        await AppPause.delay(const Duration(milliseconds: 260));
        _blob.focus(null);
      }
      gathered = true;
    } on TickerCanceled {
      // Something else needed it on the way; the coins can wait.
      return;
    } finally {
      if (mounted) {
        _blob
          ..walk(0)
          ..focus(null);
        if (gen == _liftGen && !_held) _walking = false;
        // Called away part-way: no more panicking.
        if (!gathered) _blob.express(null);
      }
    }
    if (!still() || got == 0) {
      _blob.express(null);
      if (still()) _walkHome();
      return;
    }
    // Turns to you: hands off.
    final lines = [
      l10n.petStatusCoinsCounted(got),
      l10n.petStatusCoinsMine,
      l10n.petStatusCoinsSavings,
    ];
    _blob
      ..focus(Offset.zero)
      ..express(BlobExpression.angry,
          duration: const Duration(milliseconds: 3200));
    SoundService.instance.play(Sfx.grumpy);
    _setStatus(lines[_rng.nextInt(lines.length)],
        hold: const Duration(seconds: 4));
    _grumpy = true;
    _later(const Duration(milliseconds: 3200), () {
      if (gen != _liftGen) return;
      _blob.focus(null);
      _walkHome();
    });
  }

  /// Walks back to the cushion from wherever it was put down.
  Future<void> _walkHome() async {
    _grumpy = false;
    if (!mounted ||
        _held ||
        (_walk.value.abs() < 0.05 && _depth.value < 0.05)) {
      return;
    }
    _walking = true;
    try {
      await _walkTo(0, 0);
    } on TickerCanceled {
      // Picked up again (or something else needed it) on the way.
    } finally {
      if (mounted && !_held) {
        _blob.walk(0);
        _walking = false;
      }
    }
  }

  /// Smacked: it complains — crosser after a few in a row. A napping pet
  /// is woken up by it.
  void _onBonk(int run, AppLocalizations l10n) {
    if (_scribe != null) return;
    if (_resting) setState(() => _resting = false);
    _stopWalk();
    if (_blob.crying.value) {
      _setStatus(l10n.petStatusCry,
          hold: const Duration(minutes: 10), voice: false);
      return;
    }
    _setStatus(run >= 3 ? l10n.petStatusBonkAngry : l10n.petStatusBonk,
        voice: false, hold: const Duration(milliseconds: 2600));
  }

  /// Smacked too many times it cries (and everything else waits) until
  /// it's been petted enough; then it says thanks.
  void _onCrying() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (_blob.crying.value) {
      _stopWalk();
      setState(() => _fanOpen = false);
      _setStatus(l10n.petStatusCry,
          hold: const Duration(minutes: 10), voice: false);
    } else {
      _setStatus(l10n.petStatusComforted,
          hold: const Duration(seconds: 4), voice: false);
    }
  }

  /// The gecko came out — sometimes the pet says so.
  void _onGecko(AppLocalizations l10n) {
    if (_status != null || _held || _scribe != null || _rng.nextBool()) {
      return;
    }
    _setStatus(l10n.petStatusGecko, hold: const Duration(seconds: 3));
  }

  void _toggleRest(AppLocalizations l10n) {
    _stopWalk();
    SoundService.instance.play(Sfx.lampClick);
    setState(() => _resting = !_resting);
    if (!_resting) _setStatus(l10n.petStatusWoke);
  }

  void _toggleFan(AppLocalizations l10n, int count) {
    if (count == 0) {
      _setStatus(l10n.petStatusNothingToday);
      return;
    }
    setState(() {
      _fanOpen = !_fanOpen;
      _fanPage = 0;
    });
  }

  /// Eats [notes] in order until the pet is full. Animates the last bite
  /// (or the hatching), and celebrates a new life stage.
  /// New notes are snacks: a little filling (only so much a day — its
  /// real meal is the daily quiz).
  void _feed(List<NoteEntity> notes, AppLocalizations l10n) {
    var ate = 0;
    var hatched = false;
    PetStage? grown;
    FoodKind? last;
    var refused = false;
    var filled = 0.0;
    for (final n in notes) {
      final kind = FoodKind.fromSource(n.sourceType);
      final out = _store.snack(noteId: n.id, food: kind);
      if (out.result == FeedResult.alreadyEaten) continue;
      if (out.result == FeedResult.full) {
        refused = true;
        break;
      }
      ate++;
      last = kind;
      filled += out.filled;
      hatched |= out.hatched;
      grown = out.evolvedTo ?? grown;
    }
    if (ate == 0) {
      if (refused) _setStatus(l10n.petStatusFull);
      return;
    }
    _stopWalk();
    if (_resting) setState(() => _resting = false);
    if (hatched) {
      _blob.hatch(last!);
      _setStatus(l10n.petStatusNewLink, voice: false);
      _later(const Duration(milliseconds: 1300), () {
        _setStatus(l10n.petStatusHatched(l10n.petName(_store)),
            hold: const Duration(seconds: 6));
      });
      // Once it has said hello, where its meals and vitals are.
      _later(const Duration(milliseconds: 7800), _coachTour);
      return;
    }
    _blob.eat(last!, snack: true);
    _setStatus(
        filled <= 0
            // Past the day's snacks: it keeps room for its quiz meal.
            ? l10n.petStatusSnackEnough
            : ate > 1
                ? l10n.petStatusAteMany(ate)
                : l10n.petStatusAte,
        voice: false);
    final stage = grown;
    if (stage != null) {
      _later(const Duration(milliseconds: 1400), () {
        _blob.celebrate();
        _setStatus(l10n.petStatusEvolved(l10n.stageLabel(stage)),
            hold: const Duration(seconds: 6), voice: false);
      });
    }
  }

  /// The first visits: the egg points at the link bar and how to share
  /// from other apps; the hatched pet at its meals and vitals (and the
  /// link bar, if the egg's tour was never seen). Each once; waits while
  /// something else is going on.
  Future<void> _coachTour() async {
    if (!mounted ||
        _touring ||
        // Not over the sign-in page (Beranda is built for a moment at start).
        sl<SupabaseService>().currentUserId == null ||
        !(ModalRoute.of(context)?.isCurrent ?? true) ||
        !_onScreen ||
        _scribe != null ||
        _fanOpen ||
        _held ||
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      return;
    }
    _touring = true;
    try {
      await _tourNow();
    } finally {
      _touring = false;
    }
  }

  /// One tour (or naming) at a time: opening the app can ask twice.
  bool _touring = false;

  Future<void> _tourNow() async {
    // First, a name for a pet that has none yet.
    if (!await _askName() || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final name = l10n.petName(_store);
    final saveBar = CoachStep(
      target: _saveBarKey,
      text: _store.state.hatched ? l10n.homeCoachSave(name) : l10n.homeCoachEgg,
    );
    // Sharing straight from the other app — no copying the link.
    final share = CoachStep(
      target: null,
      text: l10n.homeCoachShare,
      art: const _ShareHowTo(),
    );
    if (!_store.state.hatched) {
      await Coachmark.showOnce(context,
          id: 'home.egg', steps: [saveBar, share]);
      return;
    }
    final sawEgg = await Coachmark.seen('home.egg');
    if (!mounted) return;
    await Coachmark.showOnce(context, id: 'home.pet', steps: [
      CoachStep(target: _mealKey, text: l10n.homeCoachMeal(name)),
      CoachStep(
          target: _feastKey,
          text: l10n.homeCoachFeast(name),
          circle: true,
          padding: 2),
      CoachStep(target: _stripKey, text: l10n.homeCoachVitals(name)),
      if (!sawEgg) ...[saveBar, share],
    ]);
  }

  /// A pet nobody has named — an account that came in without the welcome
  /// story (Google, with the email of an older account), or one from
  /// before it asked — gets asked here, once per account. Only once the
  /// account's own pet has come down, so a name given on another phone
  /// isn't asked for again. False while that's still on its way (the
  /// tours wait for it too).
  Future<bool> _askName() async {
    final user = sl<SupabaseService>().currentUserId;
    if (user == null ||
        _store.customName != null ||
        _store.namingAskedFor(user)) {
      return true;
    }
    if (!sl<PetSync>().ready) {
      // Try again in a moment (for half a minute; offline, it waits for
      // the next visit).
      if (_nameWaits++ < 15) {
        _later(const Duration(seconds: 2), _coachTour);
      }
      return false;
    }
    _store.markNamingAsked(user);
    await showPetNaming(context);
    return true;
  }

  int _nameWaits = 0;

  /// While the pet is new (barely petted yet), it tells you what you can
  /// do with it — the hint that used to sit under the room.
  void _howTo() {
    final pet = _store.state;
    if (!pet.hatched || pet.petCount >= 3 || _status != null) return;
    _setStatus(AppLocalizations.of(context)!.petStatusHowTo,
        hold: const Duration(seconds: 6));
  }

  // ─── meals: the daily quiz and the weekly feast ───────────────────────

  /// Notes needed before the daily quiz opens (it asks about them).
  static const _mealsNeedNotes = 3;

  /// Notes saved in the last week — the weekly feast asks about those, so
  /// it needs a few.
  int _notesLastWeek(DateTime now) => [
        for (final n in _data?.recentNotes ?? const <NoteEntity>[])
          if (now.difference(n.createdAt.toLocal()) < const Duration(days: 7))
            n,
      ].length;

  bool _feastAvailable(DateTime now) => _notesLastWeek(now) >= _mealsNeedNotes;

  /// This week's feast is there to be had.
  bool _feastPending(DateTime now) =>
      _store.state.hatched &&
      !_petInbox.feastDoneFor(now) &&
      _feastAvailable(now);

  /// Once a day, while today's meal is waiting, the pet asks for it.
  void _nudgeQuiz() {
    final prefs = _prefs;
    if (prefs == null || !_petInbox.mealReadyAt(DateTime.now())) return;
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    if (prefs.getString(_kQuizNudged) == today) return;
    prefs.setString(_kQuizNudged, today);
    _later(const Duration(seconds: 3), () {
      if (_status != null || _scribe != null || _held || _fanOpen) return;
      _setStatus(AppLocalizations.of(context)!.petStatusQuizReady,
          hold: const Duration(seconds: 6));
    });
  }

  /// Once a day, while this week's feast hasn't been had, the pet points
  /// out that it's how it grows up fast (a while after arriving, so it
  /// doesn't talk over the meal reminder).
  void _nudgeFeast() {
    final prefs = _prefs;
    if (prefs == null || !_feastPending(DateTime.now())) return;
    final today = PetState.dayKey(DateTime.now());
    if (prefs.getString(_kFeastNudged) == today) return;
    _later(const Duration(seconds: 16), () {
      if (_status != null ||
          _scribe != null ||
          _held ||
          _fanOpen ||
          _friendVisit != null ||
          !_feastPending(DateTime.now())) {
        return;
      }
      prefs.setString(_kFeastNudged, today);
      _setStatus(AppLocalizations.of(context)!.petStatusFeastNudge,
          hold: const Duration(seconds: 6));
    });
  }

  static const _kFeastNudged = 'quiz.feastNudgedOn';

  void _openMeal() {
    if (!ConnectivityService.instance.hasNetwork) {
      _needOnline(OnlineFeature.mealQuiz);
      return;
    }
    context.push(Routes.dailyQuiz);
  }

  /// Offline: the pet frets that it needs the internet for [feature].
  void _needOnline(OnlineFeature feature) {
    _stopWalk();
    if (_resting) setState(() => _resting = false);
    _blob.express(BlobExpression.sad,
        duration: const Duration(milliseconds: 2600));
    _setStatus(AppLocalizations.of(context)!.offlineLine(feature),
        hold: const Duration(seconds: 6));
  }

  /// Whether the app was online the last time it changed.
  bool _wasOnline = ConnectivityService.instance.isOnline;

  /// The pet mentions it when the app goes offline or comes back.
  void _onNetwork() {
    final online = ConnectivityService.instance.isOnline;
    if (online == _wasOnline) return;
    _wasOnline = online;
    if (!mounted || !_onScreen || _scribe != null) return;
    final l10n = AppLocalizations.of(context)!;
    _setStatus(online ? l10n.petStatusBackOnline : l10n.petStatusWentOffline,
        hold: const Duration(seconds: 5));
  }

  /// Bumped when the pet turns its meal down (the bubble wobbles).
  int _mealRefused = 0;

  /// The onigiri over the vitals: today's meal. Once it has eaten today it
  /// shakes its head — it's full, though a snack (a new note) would do.
  void _onMealBubble(MealState meal, AppLocalizations l10n) {
    switch (meal) {
      case MealState.locked:
        _setStatus(l10n.petStatusMealLocked(_mealsNeedNotes));
      case MealState.ready:
        _openMeal();
      case MealState.done:
        _stopWalk();
        if (_resting) setState(() => _resting = false);
        setState(() => _mealRefused++);
        _blob.shake();
        SoundService.instance.play(Sfx.refuse);
        _setStatus(l10n.petStatusFullRefuse,
            hold: const Duration(seconds: 4), voice: false);
        // …and glances down at the link bar, where snacks come from.
        _later(const Duration(milliseconds: 700),
            () => _blob.focus(const Offset(0, 1)));
        _later(const Duration(milliseconds: 2200), () => _blob.focus(null));
    }
  }

  /// The weekly feast button by the bell.
  void _onFeast(AppLocalizations l10n) {
    final now = DateTime.now();
    if (!_store.state.hatched) {
      _setStatus(l10n.petStatusEgg);
    } else if (_petInbox.feastDoneFor(now) || _feastAvailable(now)) {
      if (!ConnectivityService.instance.hasNetwork) {
        _needOnline(OnlineFeature.feastQuiz);
        return;
      }
      context.push(Routes.weeklyQuiz);
    } else {
      _setStatus(l10n.petStatusFeastLocked(_mealsNeedNotes));
    }
  }

  MealState? _mealState(DateTime now) {
    if (!_store.state.hatched) return null;
    if (!_petInbox.mealsUnlocked) return MealState.locked;
    if (!_petInbox.mealDoneOn(now)) return MealState.ready;
    return MealState.done;
  }

  // ─── inbox ────────────────────────────────────────────────────────────

  /// Opens the bell's inbox and follows a tapped note where it points.
  Future<void> _openInbox(AppLocalizations l10n) async {
    final notice = await showPetInbox(context);
    if (!mounted || notice == null) return;
    switch (notice.kind) {
      case PetNoticeKind.hungry:
      case PetNoticeKind.unfed:
        if (_petInbox.mealReadyAt(DateTime.now())) {
          // Its meal is waiting: straight to today's quiz.
          _openMeal();
        } else {
          // Nothing to quiz on yet: a snack, through the link bar.
          _linkFocus.requestFocus();
          _setStatus(l10n.petStatusFeedMe, hold: const Duration(seconds: 5));
        }
      case PetNoticeKind.lonely:
        _setStatus(l10n.petStatusLonely, hold: const Duration(seconds: 5));
      case PetNoticeKind.quiz:
        _openMeal();
      case PetNoticeKind.hatched:
      case PetNoticeKind.evolved:
      case PetNoticeKind.streak:
        showPetProfile(context);
    }
  }

  // ─── writing a link up ────────────────────────────────────────────────

  /// A link shared from another app lands in the bar, ready to write up.
  void _takeSharedLink() {
    final url = _inbox.value;
    if (url == null || !mounted) return;
    _inbox.value = null;
    if (_saving) {
      _queuedShare = url;
      return;
    }
    _fillBar(url);
  }

  void _fillBar(String url) {
    final l10n = AppLocalizations.of(context)!;
    _linkCtrl
      ..text = url
      ..selection = TextSelection.collapsed(offset: url.length);
    _stopWalk();
    if (_resting) setState(() => _resting = false);
    _setStatus(l10n.petStatusSharedLink, hold: const Duration(seconds: 10));
  }

  /// The check on the link bar. The pet takes its notebook out, puts its
  /// glasses on and writes the note up (title, summary, tags) while the
  /// auto-fill runs, holds the page up to show you, then opens it for you
  /// to check. Saving it feeds the pet. True when the link was saved (the
  /// bar clears); cancelling keeps the link in the bar.
  Future<bool> _scribeLink(String raw, AppLocalizations l10n) async {
    final link = extractLink(raw);
    if (link == null) {
      _blob.shake();
      _setStatus(l10n.petStatusNotLink);
      return false;
    }
    if (_scribe != null) return false;
    try {
      _stopWalk();
      setState(() {
        _resting = false;
        _fanOpen = false;
        _saving = true;
        _draft = null;
        _scribe = ScribePhase.writing;
      });
      // Offline it can't read the link: it just writes the address down.
      _wroteOffline = !ConnectivityService.instance.hasNetwork;
      _setStatus(
          _wroteOffline ? l10n.petStatusOfflineSaved : l10n.petScribeStart,
          hold: const Duration(minutes: 2));
      // Let it write for a moment even when the summary comes back fast.
      final done = await Future.wait([
        _writeUp(link, l10n),
        AppPause.delay(Duration(milliseconds: _wroteOffline ? 1200 : 2600)),
      ]);
      final draft = done.first as NoteDraft;
      if (!mounted) return false;

      setState(() {
        _draft = draft;
        _scribe = ScribePhase.presenting;
      });
      _blob.beam(duration: const Duration(milliseconds: 2200));
      _setStatus(
          draft.summarized
              ? l10n.petScribeDone
              : _wroteOffline
                  ? l10n.petStatusOfflineSaved
                  : draft.outOfQuota
                      ? l10n.petScribeOutOfQuota
                      : l10n.petScribePartial,
          hold: const Duration(minutes: 2));
      await AppPause.delay(const Duration(milliseconds: 1400));
      if (!mounted) return false;

      final checked = await showScribeReview(context,
          draft: draft, petName: l10n.petName(_store));
      if (!mounted) return false;
      setState(() => _scribe = null);
      if (checked == null) {
        setState(() => _saving = false);
        _setStatus(l10n.petScribeCancelled);
        return false;
      }
      _setStatus(l10n.petStatusNewLink, hold: const Duration(seconds: 8));
      _pendingLink = link;
      final title = checked.title?.trim();
      context.read<VaultBloc>().add(VaultNoteAdded(AddNoteParams(
            url: link,
            title: title == null || title.isEmpty ? null : title,
            manualNotes: checked.notes,
            tags: checked.tags,
            sourceType: checked.sourceType,
            thumbnailUrl: checked.thumbnailUrl,
            inQuiz: checked.inQuiz,
          )));
      return true;
    } finally {
      // Something went wrong part-way: put the notebook away.
      if (mounted && _scribe != null) {
        setState(() {
          _scribe = null;
          _saving = false;
        });
      }
      final queued = _queuedShare;
      if (queued != null) {
        _queuedShare = null;
        // After the bar has cleared the link it just took.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fillBar(queued);
        });
      }
    }
  }

  /// The link being written up couldn't be read for want of the internet.
  bool _wroteOffline = false;

  /// The auto-fill for [link]: the source's details, and a summary (title
  /// plus notes) from the auto-summarize function — its progress shows in
  /// the pet's bubble. Tags are picked from what it wrote. Offline, just
  /// the link.
  Future<NoteDraft> _writeUp(String link, AppLocalizations l10n) async {
    final source = link.sourceFromUrl;
    if (_wroteOffline) {
      return NoteDraft(url: link, sourceType: source, summarized: false);
    }
    final metaFuture = sl<MetadataRemoteDataSource>()
        .fetch(link)
        .timeout(const Duration(seconds: 10))
        .then<UrlMetadata?>((m) => m, onError: (_) => null);

    final markdown = StringBuffer();
    // Video posts get transcribed first — a much richer summary.
    final transcribe =
        source == 'instagram' || source == 'tiktok' || source == 'x';
    const hold = Duration(minutes: 2);
    var outOfQuota = false;
    var picked = const <String>[];
    try {
      final events = sl<AutoSummarize>()(
        url: link,
        transcribe: transcribe,
        locale: AppSettingsService.instance.resolvedLocale.languageCode,
      ).timeout(const Duration(seconds: 75));
      await for (final e in events) {
        if (!mounted) break;
        if (e is AutoSummarizeMeta) {
          _setStatus(l10n.petScribeFound(e.contentLabel),
              hold: hold, voice: false);
        } else if (e is AutoSummarizeStage) {
          _setStatus(e.label, hold: hold, voice: false);
        } else if (e is AutoSummarizeToken) {
          markdown.write(e.token);
        } else if (e is AutoSummarizeTags) {
          picked = e.tags;
        } else if (e is AutoSummarizeError) {
          outOfQuota = e.outOfQuota;
          break;
        } else if (e is AutoSummarizeDone) {
          break;
        }
      }
    } catch (e) {
      // Timed out or offline — the note keeps whatever came through.
      if (isOfflineError(e)) _wroteOffline = true;
    }

    final meta = await metaFuture;
    final (aiTitle, notes) = splitMarkdownTitle(markdown.toString());
    final title = aiTitle ?? meta?.title;
    final caption =
        [meta?.title, meta?.description].whereType<String>().join(' ');
    return NoteDraft(
      url: link,
      title: title,
      notes: notes,
      tags: suggestTags(
        [title, caption, notes].whereType<String>().join('\n'),
        hashtagSource: caption,
        picked: picked,
        known: (_data?.topTags ?? const <TagCount>[]).map((t) => t.tag),
        common: AppConstants.suggestedTags,
      ),
      sourceType: source,
      thumbnailUrl: meta?.image,
      sourceTitle: meta?.title,
      siteName: meta?.siteName,
      summarized: notes.isNotEmpty,
      outOfQuota: outOfQuota && notes.isEmpty,
    );
  }

  // ─── idling ───────────────────────────────────────────────────────────

  /// Every so often, when nothing else is going on, the pet does
  /// something on its own: a stroll, a look at the TV or the bookshelf, or
  /// one of its idle moves.
  void _scheduleIdle() {
    _wander?.cancel();
    _wander = AppTimer(Duration(seconds: 12 + _rng.nextInt(12)), _idleOnce);
  }

  Future<void> _idleOnce() async {
    if (!mounted) return;
    final pet = _store.state;
    final mood = pet.moodAt(DateTime.now());
    final busy = _resting ||
        _walking ||
        _held ||
        _grumpy ||
        _fanOpen ||
        _saving ||
        _scribe != null ||
        _friendVisit != null ||
        _mosquito != null ||
        _blob.crying.value ||
        !pet.hatched ||
        mood == CompanionMood.sleepy ||
        !TickerMode.of(context);
    if (busy) {
      _scheduleIdle();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    // Coins left on the floor (it was called away while gathering them):
    // those come first.
    if (_coins.count > 0) {
      await _collectCoins(l10n);
      if (mounted) _scheduleIdle();
      return;
    }
    // A hungry or lonely pet isn't up for dancing.
    final low = mood == CompanionMood.hungry || mood == CompanionMood.lonely;
    final now = DateTime.now();
    final fullAndHappy =
        pet.fullnessAt(now) >= 75 && pet.happinessAt(now) >= 65;
    final roll = _rng.nextInt(100);
    try {
      if (fullAndHappy && roll < 18) {
        await _contentBurp(l10n);
      } else if (roll < 36) {
        await _tour(l10n);
      } else if (roll < 46 && !low) {
        // Up to the TV to watch for a bit — and it's all boring.
        await _visit(PetScene.tvSpot.walk,
            depth: PetScene.tvSpot.depth,
            look: const Offset(0.12, -0.95),
            line: l10n.petIdleTv,
            stay: const Duration(seconds: 4), then: () async {
          _blob
            ..focus(null)
            ..express(BlobExpression.serious,
                duration: const Duration(milliseconds: 2600));
          _setStatus(l10n.petIdleTvAfter,
              hold: const Duration(milliseconds: 3400));
          await AppPause.delay(const Duration(milliseconds: 2000));
        });
      } else if (roll < 56) {
        // Over to the bookshelf, eyes running along the books — it'll
        // wait for you to read them.
        await _visit(PetScene.shelfSpot.walk,
            depth: PetScene.shelfSpot.depth,
            look: const Offset(-0.5, -0.8),
            scan: true,
            line: l10n.petIdleShelf,
            stay: const Duration(seconds: 4), then: () async {
          _blob
            ..focus(Offset.zero)
            ..beam(duration: const Duration(milliseconds: 1800));
          SoundService.instance.play(Sfx.giggle);
          _setStatus(l10n.petIdleShelfAfter,
              hold: const Duration(milliseconds: 3400));
          await AppPause.delay(const Duration(milliseconds: 2000));
          _blob.focus(null);
        });
      } else if (roll < 63 && !low) {
        await _roll(l10n);
      } else {
        final moves = low
            ? const [BlobIdle.lookAround, BlobIdle.stretch, BlobIdle.doze]
            : BlobIdle.values;
        _playIdle(moves[_rng.nextInt(moves.length)], l10n);
      }
    } finally {
      if (mounted) _scheduleIdle();
    }
  }

  /// One idle move, with a word now and then — unless the pet is already
  /// saying something.
  void _playIdle(BlobIdle move, AppLocalizations l10n) {
    _blob.idle(move);
    final line = switch (move) {
      BlobIdle.wave => l10n.petIdleWave,
      BlobIdle.stretch => l10n.petIdleYawn,
      BlobIdle.dance => l10n.petIdleDance,
      BlobIdle.sneeze => l10n.petIdleSneeze,
      BlobIdle.hum => l10n.petIdleHum,
      _ => null,
    };
    if (line != null && _status == null) {
      _setStatus(line, hold: const Duration(milliseconds: 2400), voice: false);
    }
  }

  /// Far enough either side of the cushion (in walk units) that the pet is
  /// right out of the room.
  static const _offstage = 3.4;

  /// Curls up and rolls off to the right, out of the room — and comes
  /// rolling back in from the left to its cushion.
  Future<void> _roll(AppLocalizations l10n) async {
    _walking = true;
    _rolling = true;
    setState(() {});
    try {
      if (_depth.value > 0.02) await _walkTo(_walk.value, 0);
      if (!mounted || !_rolling) return;
      _setStatus(l10n.petIdleRoll,
          hold: const Duration(milliseconds: 2400), voice: false);
      _blob.roll(true);
      await AppPause.delay(const Duration(milliseconds: 300));
      if (!mounted || !_rolling) return;
      // Off to the right, picking up speed…
      await _walk
          .animateTo(_offstage,
              duration: Duration(
                  milliseconds:
                      ((_offstage - _walk.value) / 2.2 * 1000).round()),
              curve: Curves.easeIn)
          .orCancel;
      // …round the back, and in again from the left.
      _walk.value = -_offstage;
      await AppPause.delay(const Duration(milliseconds: 700));
      if (!mounted || !_rolling) return;
      _blob.roll(true);
      await _walk
          .animateTo(0,
              duration: const Duration(milliseconds: 2100),
              curve: Curves.easeOutCubic)
          .orCancel;
      _blob.roll(false);
      _setStatus(l10n.petIdleRollBack,
          hold: const Duration(milliseconds: 2200), voice: false);
      await AppPause.delay(const Duration(milliseconds: 500));
    } on TickerCanceled {
      // Interrupted — _stopWalk brings it back.
    } finally {
      if (mounted) {
        _blob.roll(false);
        _rolling = false;
        _walking = false;
        setState(() {});
      }
    }
  }

  /// How long a walk from where it is to ([walk], [depth]) takes, at an
  /// easy pace (the floor's about as deep as it is wide in these units).
  Duration _legTo(double walk, double depth) {
    final dx = walk - _walk.value;
    final dd = depth - _depth.value;
    final distance = math.sqrt(dx * dx + dd * dd);
    return Duration(
        milliseconds: (distance / 0.9 * 1900).round().clamp(400, 3600));
  }

  /// Walks to ([walk], [depth]) on the floor, hopping the way it's going
  /// ([pace] times as fast as a stroll). Throws [TickerCanceled] if it's
  /// interrupted.
  Future<void> _walkTo(double walk, double depth, {double pace = 1}) async {
    final dx = walk - _walk.value;
    if (dx.abs() < 0.01 && (depth - _depth.value).abs() < 0.01) return;
    final leg = _legTo(walk, depth) * (1 / pace);
    _blob.walk(dx.abs() < 0.03 ? 1 : (dx > 0 ? 1 : -1));
    try {
      await Future.wait([
        _walk.animateTo(walk, duration: leg, curve: Curves.easeInOut).orCancel,
        _depth
            .animateTo(depth, duration: leg, curve: Curves.easeInOut)
            .orCancel,
      ]);
    } finally {
      if (mounted) _blob.walk(0);
    }
  }

  /// Walks to [target] (a [walk] value) and [depth] (how far back towards
  /// the wall), stays a moment — looking at [look] if given, sweeping along
  /// it with [scan] — does [then] (says what it thought), and walks back
  /// to the cushion.
  Future<void> _visit(double target,
      {double depth = 0,
      Offset? look,
      bool scan = false,
      String? line,
      Duration stay = const Duration(seconds: 3),
      Future<void> Function()? then}) async {
    _walking = true;
    if (line != null) _setStatus(line, hold: _legTo(target, depth) + stay);
    try {
      await _walkTo(target, depth);
      if (look != null) _blob.focus(look, scan: scan);
      await AppPause.delay(stay);
      if (look != null) _blob.focus(null);
      if (!mounted || !_walking) return;
      // What it makes of it, before it heads back.
      if (then != null) {
        await then();
        if (!mounted || !_walking) return;
      }
      await _walkTo(0, 0);
    } on TickerCanceled {
      // Interrupted (eating, resting, page gone) — _stopWalk tidies up.
    } finally {
      if (mounted) {
        if (look != null) _blob.focus(null);
        _blob.walk(0);
        _walking = false;
      }
    }
  }

  /// A proper look round the room: along the front, past the bookshelf,
  /// by the wall, over by the armchair — this way round or that — stopping
  /// here and there to look about, then home to its cushion.
  Future<void> _tour(AppLocalizations l10n) async {
    _walking = true;
    double nudge() => (_rng.nextDouble() - 0.5) * 0.16;
    var stops = [
      (-0.95 + nudge(), 0.12),
      (-0.78 + nudge(), 0.62),
      (-0.15 + nudge(), 0.82),
      (0.55 + nudge(), 0.72),
      (1.0 + nudge(), 0.25),
    ];
    if (_rng.nextBool()) stops = stops.reversed.toList();
    _setStatus(l10n.petIdleTour, hold: const Duration(seconds: 3));
    try {
      for (var i = 0; i < stops.length; i++) {
        final (walk, depth) = stops[i];
        await _walkTo(walk, depth);
        if (!mounted || !_walking) return;
        if (_rng.nextDouble() < 0.65) {
          // A look about.
          _blob.focus(Offset(
              _rng.nextBool() ? -0.7 : 0.7, -0.4 + _rng.nextDouble() * 0.5));
          if (i == stops.length ~/ 2 && _status == null) {
            _setStatus(l10n.petIdleTourLook,
                hold: const Duration(milliseconds: 2200), voice: false);
          }
          await AppPause.delay(Duration(milliseconds: 700 + _rng.nextInt(700)));
          _blob.focus(null);
        } else {
          await AppPause.delay(const Duration(milliseconds: 250));
        }
        if (!mounted || !_walking) return;
      }
      await _walkTo(0, 0);
      if (!mounted || !_walking) return;
      _blob.beam(duration: const Duration(milliseconds: 1400));
      _setStatus(l10n.petIdleTourDone, hold: const Duration(seconds: 3));
    } on TickerCanceled {
      // Interrupted (eating, resting, page gone) — _stopWalk tidies up.
    } finally {
      if (mounted) {
        _blob
          ..focus(null)
          ..walk(0);
        _walking = false;
      }
    }
  }

  /// Full and happy: a little burp, then a big pleased smile.
  Future<void> _contentBurp(AppLocalizations l10n) async {
    _blob.burp();
    await AppPause.delay(BlobController.burpLength);
    if (!mounted) return;
    _blob.beam(duration: const Duration(milliseconds: 2200));
    _setStatus(l10n.petIdleFull, hold: const Duration(milliseconds: 2800));
  }

  /// Hurry back to the cushion (something needs the pet's attention).
  void _stopWalk() {
    if (!_walking && _walk.value == 0 && _depth.value == 0) return;
    _walking = false;
    _blob.walk(0);
    _walk.stop();
    _depth.stop();
    _walk.animateTo(0,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    _depth.animateTo(0,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  // ─── a friend dropping by ─────────────────────────────────────────────

  /// Something has the pet's attention, so a friend wouldn't stay.
  bool get _visitBusy =>
      _held ||
      _grumpy ||
      _saving ||
      _scribe != null ||
      _fanOpen ||
      _resting ||
      _blob.crying.value;

  /// Now and then — not often, it's a little surprise — one of the pet's
  /// friends comes by to say hi.
  void _scheduleVisit({bool first = false}) {
    _visitTimer?.cancel();
    _visitTimer = AppTimer(
      first
          ? Duration(seconds: 40 + _rng.nextInt(50))
          : Duration(seconds: 150 + _rng.nextInt(150)),
      _maybeVisit,
    );
  }

  void _maybeVisit() {
    if (!mounted) return;
    final pet = _store.state;
    final free = !_visitBusy &&
        !_walking &&
        _mosquito == null &&
        _status == null &&
        pet.hatched &&
        pet.moodAt(DateTime.now()) != CompanionMood.sleepy &&
        MediaQuery.viewInsetsOf(context).bottom == 0 &&
        TickerMode.of(context);
    if (!free) {
      // Try again a little later.
      _visitTimer =
          AppTimer(Duration(seconds: 20 + _rng.nextInt(20)), _maybeVisit);
      return;
    }
    if (_rng.nextDouble() > 0.7) return _scheduleVisit();
    final l10n = AppLocalizations.of(context)!;
    _stopWalk();
    setState(() {
      _idleVisible = false;
      _friendVisit = VisitPlan(
        friend: VisitorPet.pick(_rng, _store.color),
        fromLeft: _rng.nextBool(),
        hostName: l10n.petName(_store),
        todayCount: _todayNotes(DateTime.now()).length,
      );
    });
  }

  void _visitDone() {
    if (!mounted) return;
    setState(() => _friendVisit = null);
    _scheduleVisit();
  }

  // ─── a mosquito ───────────────────────────────────────────────────────

  /// Every few minutes, maybe, a mosquito buzzes in.
  void _scheduleMosquito({bool first = false}) {
    _mosquitoTimer?.cancel();
    _mosquitoTimer = AppTimer(
      first
          ? Duration(seconds: 70 + _rng.nextInt(90))
          : Duration(seconds: 240 + _rng.nextInt(240)),
      _maybeMosquito,
    );
  }

  void _maybeMosquito() {
    if (!mounted) return;
    final pet = _store.state;
    final free = !_visitBusy &&
        !_walking &&
        _friendVisit == null &&
        _status == null &&
        pet.hatched &&
        pet.moodAt(DateTime.now()) != CompanionMood.sleepy &&
        MediaQuery.viewInsetsOf(context).bottom == 0 &&
        TickerMode.of(context);
    if (!free) {
      _mosquitoTimer =
          AppTimer(Duration(seconds: 20 + _rng.nextInt(20)), _maybeMosquito);
      return;
    }
    if (_rng.nextDouble() > 0.6) return _scheduleMosquito();
    _stopWalk();
    setState(() {
      _idleVisible = false;
      _mosquito = MosquitoPlan(fromLeft: _rng.nextBool());
    });
  }

  /// Hops after the mosquito, to [walk].
  Future<void> _chase(double walk) async {
    if (!mounted || _held) return;
    _walking = true;
    try {
      await _walkTo(walk, 0);
    } on TickerCanceled {
      // Something needed the pet; the mosquito leaves.
    }
  }

  /// Eaten, or flown off: back to the cushion.
  void _mosquitoDone() {
    if (!mounted) return;
    setState(() => _mosquito = null);
    _walking = false;
    _walkHome();
    _scheduleMosquito();
  }
}

// ════════════════════════════════════════════════════════════════════════
