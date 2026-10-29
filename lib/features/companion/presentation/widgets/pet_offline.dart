import 'package:flutter/material.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../notes/presentation/widgets/note_paper.dart';
import 'blob_mascot.dart';
import 'pet_host.dart';
import 'pet_speech_bubble.dart';

/// What can't be done without the internet — the AI and everything else
/// that happens on the server. For what the pet says about it.
enum OnlineFeature {
  assistant,
  mealQuiz,
  feastQuiz,
  summary,
  preview,
  video,
  download,
  reindex,
  account,
  signIn,
  signUp,
}

extension OnlineFeatureLabel on AppLocalizations {
  /// "to …": what the pet needs the internet for.
  String offlineWhat(OnlineFeature f) => switch (f) {
        OnlineFeature.assistant => offlineWhatAssistant,
        OnlineFeature.mealQuiz => offlineWhatMealQuiz,
        OnlineFeature.feastQuiz => offlineWhatFeastQuiz,
        OnlineFeature.summary => offlineWhatSummary,
        OnlineFeature.preview => offlineWhatPreview,
        OnlineFeature.video => offlineWhatVideo,
        OnlineFeature.download => offlineWhatDownload,
        OnlineFeature.reindex => offlineWhatReindex,
        OnlineFeature.account => offlineWhatAccount,
        OnlineFeature.signIn => offlineWhatSignIn,
        OnlineFeature.signUp => offlineWhatSignUp,
      };

  /// The pet's line: it needs the internet to do [f].
  String offlineLine(OnlineFeature f) => offlineNeedInternet(offlineWhat(f));
}

/// Whether [error] means there was no connection (rather than the server
/// saying no) — or the phone is offline anyway.
bool isOfflineError(Object? error) =>
    !ConnectivityService.instance.hasNetwork ||
    (error != null && ConnectivityService.isNetworkError(error));

/// Whether the phone is online. If it isn't, the pet pops up to say
/// [feature] needs the internet — and this is true only if the phone
/// comes back online while it's up and the user carries on.
Future<bool> ensureOnline(BuildContext context, OnlineFeature feature) async {
  if (ConnectivityService.instance.hasNetwork) return true;
  return showPetOffline(context, feature);
}

/// For a button that needs the internet: false when the phone is offline
/// (and the pet pops up to say so).
bool canGoOnline(BuildContext context, OnlineFeature feature) {
  if (ConnectivityService.instance.hasNetwork) return true;
  showPetOffline(context, feature);
  return false;
}

/// The pet, in a sheet, saying [feature] needs the internet (also after a
/// request failed for want of one). True when the user carries on once
/// the phone is back online.
Future<bool> showPetOffline(BuildContext context, OnlineFeature feature) async {
  // On a network that doesn't reach the internet: it's offline all the
  // same, until a request gets through or the network changes.
  final net = ConnectivityService.instance;
  if (net.isOnline) net.reportFailure();
  final carryOn = await showModalBottomSheet<bool>(
    context: context,
    // Above the shell so the floating nav bar doesn't cover it.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _PetOfflineSheet(feature),
  );
  return carryOn ?? false;
}

class _PetOfflineSheet extends StatefulWidget {
  final OnlineFeature feature;
  const _PetOfflineSheet(this.feature);

  @override
  State<_PetOfflineSheet> createState() => _PetOfflineSheetState();
}

class _PetOfflineSheetState extends State<_PetOfflineSheet> {
  final _net = ConnectivityService.instance;
  final _pet = BlobController();

  /// Back online since the sheet came up.
  bool _online = false;

  /// "Still offline…" after a retry that didn't help.
  bool _stillOffline = false;

  @override
  void initState() {
    super.initState();
    _net.online.addListener(_onNetwork);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SoundService.instance
          .chatter(AppLocalizations.of(context)!.offlineLine(widget.feature));
    });
  }

  @override
  void dispose() {
    _net.online.removeListener(_onNetwork);
    super.dispose();
  }

  void _onNetwork() {
    if (!mounted || _online == _net.isOnline) return;
    setState(() {
      _online = _net.isOnline;
      _stillOffline = false;
    });
    if (_online) _pet.celebrate(sound: Sfx.happyJump);
  }

  void _retry() {
    if (_net.hasNetwork) {
      Navigator.of(context).pop(true);
      return;
    }
    _pet.shake();
    SoundService.instance.play(Sfx.refuse);
    setState(() => _stillOffline = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final line = _online
        ? l10n.offlineBackOnline
        : _stillOffline
            ? l10n.offlineStill
            : l10n.offlineLine(widget.feature);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.surfaceStroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 22),
          PetOfflineScene(
            line: line,
            controller: _pet,
            happy: _online,
          ),
          const SizedBox(height: 18),
          _SafeNote(text: l10n.offlineSafeNote),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.offlineOk),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _retry,
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child:
                      Text(_online ? l10n.offlineContinue : l10n.offlineRetry),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The pet with what it says beside it: worried while offline, cheerful
/// once back ([happy]).
class PetOfflineScene extends StatelessWidget {
  final String line;
  final BlobController? controller;
  final bool happy;
  const PetOfflineScene({
    super.key,
    required this.line,
    this.controller,
    this.happy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PetHost(
          height: 92,
          controller: controller,
          idle: false,
          expression: happy ? null : BlobExpression.sad,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 34),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PetSpeechBubble(text: line, tailLeft: true, maxWidth: 240),
            ),
          ),
        ),
      ],
    );
  }
}

/// A page's own "needs the internet" state (where the page itself is the
/// online feature): the pet, its line, and a button to try again.
class PetOfflineView extends StatelessWidget {
  final OnlineFeature feature;
  final VoidCallback onRetry;
  const PetOfflineView({
    super.key,
    required this.feature,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PetOfflineScene(line: l10n.offlineLine(feature)),
            const SizedBox(height: 18),
            _SafeNote(text: l10n.offlineSafeNote),
            const SizedBox(height: 22),
            Center(
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: Text(l10n.offlineRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Your notes are safe…": a slip of the notepaper with a strip of tape.
class _SafeNote extends StatelessWidget {
  final String text;
  const _SafeNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          decoration: notePaperDecoration(context, radius: 14),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 20, color: context.palette.textTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: AppFonts.body(
                    fontSize: 13,
                    height: 1.45,
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -9,
          left: 14,
          child: TapeLabel(
            text: l10n.offlineTag,
            color: const Color(0xFFBFD8E8),
          ),
        ),
      ],
    );
  }
}
