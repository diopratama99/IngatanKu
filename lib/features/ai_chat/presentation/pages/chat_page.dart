import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../vault/domain/entities/note_entity.dart';
import '../../../vault/domain/usecases/get_notes.dart';
import '../../domain/answer_parts.dart';
import '../../domain/suggested_prompts.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/message_bubble.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../companion/data/pet_store.dart';
import '../../../companion/presentation/pet_labels.dart';
import '../../../companion/presentation/widgets/pet_activities.dart';
import '../../../companion/presentation/widgets/pet_offline.dart';
import '../../domain/entities/message_entity.dart';

/// The answer's words are coming in (past the thinking-while-you-wait bit).
bool _answering(ChatState state) {
  final last = state.messages.isEmpty ? null : state.messages.last;
  return state.isStreaming &&
      last != null &&
      last.role == MessageRole.assistant &&
      last.content.isNotEmpty;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.online.addListener(_onNetwork);
    // A conversation picked up from last time opens at its end.
    _messageCount = context.read<ChatBloc>().state.messages.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd());
  }

  /// Down to the newest message (twice: the list only knows how long it
  /// is once it has laid out its end).
  void _toEnd([bool again = true]) {
    if (!mounted || !_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
    if (again) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd(false));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.getNotifier(context);
    if (visible != _visible) {
      _visible?.removeListener(_syncTyping);
      _visible = visible..addListener(_syncTyping);
      _syncTyping();
    }
  }

  @override
  void dispose() {
    ConnectivityService.instance.online.removeListener(_onNetwork);
    _visible?.removeListener(_syncTyping);
    SoundService.instance.setLoop(SfxLoop.typing, false);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Keys click softly while an answer comes in — only while this page is
  /// the one on screen (not when you've gone to another tab).
  bool _typing = false;
  ValueListenable<bool>? _visible;

  void _syncTyping() => SoundService.instance
      .setLoop(SfxLoop.typing, _typing && (_visible?.value ?? false));

  /// Messages on screen, to tell a new one from an answer growing.
  int _messageCount = 0;

  /// A question was asked while offline: the pet says it needs the
  /// internet (until the phone is back online).
  bool _askedOffline = false;

  void _onNetwork() {
    if (_askedOffline && ConnectivityService.instance.hasNetwork && mounted) {
      setState(() => _askedOffline = false);
    }
  }

  void _send() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    if (!ConnectivityService.instance.hasNetwork) {
      // The question stays in the box for when it's back online.
      SoundService.instance.chatter(
          AppLocalizations.of(context)!.offlineLine(OnlineFeature.assistant));
      setState(() => _askedOffline = true);
      return;
    }
    if (_askedOffline) setState(() => _askedOffline = false);
    context.read<ChatBloc>().add(ChatQuestionSent(q));
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 400,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read above the Scaffold: inside its body the keyboard inset is
    // already taken out. The nav bar hides while typing, so the composer
    // drops down to the keyboard.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        // The assistant is the pet: "Tanya Bolubi".
        title: ListenableBuilder(
          listenable: sl<PetStore>(),
          builder: (context, _) {
            final l10n = AppLocalizations.of(context)!;
            return SpacedTitle(l10n.chatTitle(l10n.petName(sl<PetStore>())));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, size: 20),
            tooltip: AppLocalizations.of(context)!.chatResetTooltip,
            onPressed: () => context.read<ChatBloc>().add(ChatCleared()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // The pet across the table: thinks while you wait, says the
            // opening line of its answer out loud while the rest comes into
            // the card below (keys typing along), and reacts once it's done.
            BlocConsumer<ChatBloc, ChatState>(
              listenWhen: (a, b) => _answering(a) != _answering(b),
              listener: (context, state) {
                _typing = _answering(state);
                _syncTyping();
              },
              builder: (context, state) {
                final l10n = AppLocalizations.of(context)!;
                final last =
                    state.messages.isEmpty ? null : state.messages.last;
                final answer =
                    last?.role == MessageRole.assistant ? last : null;
                final parts = answer == null ? null : AnswerParts.of(answer);
                // Its first sentence still on its way: still thinking.
                final pending = parts?.pending ?? false;
                final talking = _answering(state) && !pending;
                final waiting = state.isStreaming && !talking;
                final String speech;
                if (_askedOffline ||
                    (state.error != null && isOfflineError(state.error))) {
                  speech = l10n.offlineLine(OnlineFeature.assistant);
                } else if (state.error != null) {
                  speech = l10n.chatPetError;
                } else if (parts?.opener != null) {
                  speech = parts!.opener!;
                } else if (talking) {
                  speech = l10n.chatPetAnswering;
                } else if (answer != null) {
                  speech = l10n.chatPetDone;
                } else {
                  speech = l10n.chatPetIdle;
                }
                final answered = state.messages
                    .where((m) =>
                        m.role == MessageRole.assistant &&
                        !m.streaming &&
                        m.content.isNotEmpty)
                    .length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PetChatCorner(
                    speech: speech,
                    thinking: waiting,
                    talking: talking,
                    compact: keyboard,
                    answered: answered,
                    found: answer != null && citedSources(answer).isNotEmpty,
                  ),
                );
              },
            ),
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                // A new message, or the answer growing as it comes in.
                listenWhen: (a, b) =>
                    a.messages.length != b.messages.length ||
                    (b.isStreaming &&
                        a.messages.isNotEmpty &&
                        b.messages.isNotEmpty &&
                        a.messages.last.content != b.messages.last.content),
                listener: (_, state) {
                  final added = state.messages.length != _messageCount;
                  _messageCount = state.messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_scroll.hasClients) return;
                    final p = _scroll.position;
                    // Follow a growing answer only if you're down there
                    // (not while you've scrolled up to read).
                    if (!added && p.maxScrollExtent - p.pixels > 160) return;
                    _scroll.animateTo(p.maxScrollExtent,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut);
                  });
                },
                builder: (_, state) {
                  if (state.messages.isEmpty) return const _EmptyChat();
                  final lastIndex = state.messages.length - 1;
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    itemCount: state.messages.length,
                    itemBuilder: (_, i) => MessageBubble(
                      message: state.messages[i],
                      // The latest answer's opening line is the pet's to say
                      // (an error stays whole in its card).
                      spoken: i == lastIndex && state.error == null,
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              minimum: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                keyboard ? 10 : 12 + kEditorialNavBarOverlay,
              ),
              child: Container(
                decoration: softCard(context, radius: 26),
                padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: AppFonts.body(
                          fontSize: 14,
                          color: context.palette.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.chatInputHint(
                              AppLocalizations.of(context)!
                                  .petName(sl<PetStore>())),
                          hintStyle: AppFonts.body(
                            color: context.palette.textTertiary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<ChatBloc, ChatState>(
                      builder: (_, state) {
                        final disabled = state.isStreaming;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: disabled ? null : _send,
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: disabled
                                    ? context.palette.bgTertiary
                                    : context.palette.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                disabled
                                    ? Icons.hourglass_top_rounded
                                    : Icons.arrow_upward_rounded,
                                color: disabled
                                    ? context.palette.textTertiary
                                    : context.palette.onPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatefulWidget {
  const _EmptyChat();

  @override
  State<_EmptyChat> createState() => _EmptyChatState();
}

class _EmptyChatState extends State<_EmptyChat> {
  /// Cached prompts keyed by `yyyy-MM-dd` (UTC) and language. Lives for the
  /// app's lifetime so navigating in/out of chat doesn't re-fetch within the
  /// same day.
  static String? _cacheKey;
  static List<String>? _cachePrompts;

  Future<List<String>>? _future;
  String? _futureLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Again if the language changed.
    final l10n = AppLocalizations.of(context)!;
    if (_futureLocale != l10n.localeName) {
      _futureLocale = l10n.localeName;
      _future = _loadPrompts(l10n);
    }
  }

  Future<List<String>> _loadPrompts(AppLocalizations l10n) async {
    final key = '${_todayKey()}|${l10n.localeName}';
    if (_cacheKey == key && _cachePrompts != null) {
      return _cachePrompts!;
    }

    List<NoteEntity> notes = const [];
    try {
      final result = await sl<GetNotes>()(const NoParams());
      notes = result.fold((_) => const [], (n) => n);
    } catch (_) {
      notes = const [];
    }

    final prompts = SuggestedPromptsBuilder.build(notes, l10n: l10n);
    _cacheKey = key;
    _cachePrompts = prompts;
    return prompts;
  }

  String _todayKey() {
    final n = DateTime.now().toUtc();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        SectionHeader(label: l10n.chatTrySection),
        const SizedBox(height: 8),
        FutureBuilder<List<String>>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: context.palette.textTertiary,
                    ),
                  ),
                ),
              );
            }
            final prompts = snap.data ?? const <String>[];
            return Column(
              children: List.generate(prompts.length, (i) {
                return Column(
                  children: [
                    InkWell(
                      onTap: () => context
                          .read<ChatBloc>()
                          .add(ChatQuestionSent(prompts[i])),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.bolt_rounded,
                                size: 16, color: AppColors.accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                prompts[i],
                                style: AppFonts.display(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: context.palette.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.arrow_outward_rounded,
                                size: 14, color: context.palette.textTertiary),
                          ],
                        ),
                      ),
                    ),
                    if (i != prompts.length - 1) const ThinDivider(),
                  ],
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
