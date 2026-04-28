import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../vault/domain/entities/note_entity.dart';
import '../../../vault/domain/usecases/get_notes.dart';
import '../../domain/suggested_prompts.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
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
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('TANYA ASISTENMU', style: eyebrowStyle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, size: 20),
            tooltip: 'Mulai ulang',
            onPressed: () => context.read<ChatBloc>().add(ChatCleared()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listenWhen: (a, b) => a.messages.length != b.messages.length,
                listener: (_, __) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scroll.hasClients) {
                      _scroll.animateTo(_scroll.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut);
                    }
                  });
                },
                builder: (_, state) {
                  if (state.messages.isEmpty) return const _EmptyChat();
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    itemCount: state.messages.length,
                    itemBuilder: (_, i) =>
                        MessageBubble(message: state.messages[i]),
                  );
                },
              ),
            ),
            const ThinDivider(),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + kEditorialNavBarOverlay,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceStroke),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tanya tentang catatanmu…',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textTertiary,
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
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: disabled
                                    ? AppColors.bgTertiary
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                disabled
                                    ? Icons.hourglass_top_rounded
                                    : Icons.arrow_upward_rounded,
                                color: Colors.white,
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
  /// Cached prompts keyed by `yyyy-MM-dd` (UTC). Lives for the app's lifetime
  /// so navigating in/out of chat doesn't re-fetch within the same day.
  static String? _cacheDay;
  static List<String>? _cachePrompts;

  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPrompts();
  }

  Future<List<String>> _loadPrompts() async {
    final today = _todayKey();
    if (_cacheDay == today && _cachePrompts != null) {
      return _cachePrompts!;
    }

    List<NoteEntity> notes = const [];
    try {
      final result = await sl<GetNotes>()(const NoParams());
      notes = result.fold((_) => const [], (n) => n);
    } catch (_) {
      notes = const [];
    }

    final prompts = SuggestedPromptsBuilder.build(notes);
    _cacheDay = today;
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        Text('Tanya\nasistenmu.', style: pageTitleStyle(size: 38)),
        const SizedBox(height: 12),
        Text(
          'AI akan mencari di seluruh catatan yang sudah kamu simpan dan menjawab dengan referensi langsung.',
          style: context.textStyles.bodyMedium,
        ),
        const SizedBox(height: 36),
        const SectionHeader(label: 'COBA TANYA'),
        const SizedBox(height: 8),
        FutureBuilder<List<String>>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.textTertiary,
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
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_outward_rounded,
                                size: 14, color: AppColors.textTertiary),
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
