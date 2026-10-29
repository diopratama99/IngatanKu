import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/app_pause.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/coachmark.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../companion/data/pet_inbox.dart';
import '../../../companion/data/pet_store.dart';
import '../../../companion/domain/companion_style.dart';
import '../../../companion/domain/pet_state.dart';
import '../../../companion/presentation/widgets/blob_mascot.dart';
import '../../../companion/presentation/pet_labels.dart';
import '../../../companion/presentation/widgets/food_painter.dart';
import '../../../companion/presentation/widgets/pet_host.dart';
import '../../../companion/presentation/widgets/pet_offline.dart';
import '../../domain/entities/weekly_quiz.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../cubit/quiz_cubit.dart';

/// A quiz hosted by the pet — and its food: [QuizKind.daily] is today's
/// meal (three questions), [QuizKind.weekly] the weekly feast. It reads
/// out each question in its reading glasses and eats every answer as it's
/// revealed (a bento for a right one, a sandwich for a wrong one), then
/// cheers or sulks.
class QuizPage extends StatelessWidget {
  final QuizKind kind;
  const QuizPage({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizCubit(
        sl<QuizRepository>(),
        kind: kind,
        onAnswer: (quiz, index, correct) => sl<PetStore>().meal(
          key: 'quiz:${quiz.id}:$index',
          correct: correct,
          feast: kind == QuizKind.weekly,
        ),
        onFinished: (_) => kind == QuizKind.daily
            ? sl<PetInbox>().markMealDone()
            : sl<PetInbox>().markFeastDone(),
      )..load(),
      child: const _WeeklyQuizScaffold(),
    );
  }
}

/// What one answer gives the pet: fullness for a daily meal, growth for
/// the weekly feast.
int _gain(QuizKind kind, bool correct) => kind == QuizKind.daily
    ? (correct ? PetState.mealRight : PetState.mealWrong)
    : (correct ? PetState.feastRightGrowth : PetState.feastWrongGrowth);

/// "CHECK" → "Check": button labels in sentence case, like the rest of
/// the app's buttons.
String _sentence(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

class _WeeklyQuizScaffold extends StatelessWidget {
  const _WeeklyQuizScaffold();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daily = context.read<QuizCubit>().kind == QuizKind.daily;
    return Scaffold(
      appBar: PageTopBar(
        title: daily ? l10n.quizMealTitle : l10n.quizFeastTitle,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<QuizCubit, QuizState>(
          builder: (context, state) {
            if (state is QuizInitial || state is QuizLoading) {
              return const _LoadingView();
            }
            if (state is QuizError) {
              if (isOfflineError(state.message)) {
                return PetOfflineView(
                  feature:
                      daily ? OnlineFeature.mealQuiz : OnlineFeature.feastQuiz,
                  onRetry: () => context.read<QuizCubit>().load(),
                );
              }
              return _ErrorView(message: state.message);
            }
            if (state is QuizActive) {
              if (state.submitted) {
                return _ResultView(state: state);
              }
              return _QuestionView(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ─── Loading ─────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Busy writing questions.
            const PetHost(
              height: 96,
              glasses: true,
              expression: BlobExpression.serious,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: context.palette.primarySoft,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.read<QuizCubit>().kind == QuizKind.daily
                  ? l10n.quizMealLoading
                  : l10n.weeklyQuizLoadingMessage,
              textAlign: TextAlign.center,
              style: AppFonts.body(
                fontSize: 13.5,
                height: 1.5,
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error ───────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PetHost(height: 88, expression: BlobExpression.sad),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.body(
                fontSize: 14,
                height: 1.5,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.read<QuizCubit>().load(),
              style: FilledButton.styleFrom(shape: const StadiumBorder()),
              child: Text(_sentence(
                  AppLocalizations.of(context)!.weeklyQuizErrorRetryCta)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Question view ───────────────────────────────────────────────────
class _QuestionView extends StatefulWidget {
  final QuizActive state;
  const _QuestionView({required this.state});

  @override
  State<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<_QuestionView> {
  final _petKey = GlobalKey();
  final _optionsKey = GlobalKey();
  final _stepsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // The first daily meal: what it is and how it goes, once.
    if (context.read<QuizCubit>().kind == QuizKind.daily &&
        !widget.state.isReadonly) {
      AppTimer(const Duration(milliseconds: 900), _coach);
    }
  }

  void _coach() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final name = l10n.petName(sl<PetStore>());
    Coachmark.showOnce(context, id: 'quiz.daily', steps: [
      CoachStep(target: _petKey, text: l10n.quizCoachFeed(name), circle: true),
      CoachStep(target: _optionsKey, text: l10n.quizCoachAnswer),
      CoachStep(target: _stepsKey, text: l10n.quizCoachSteps(name)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = AppLocalizations.of(context)!;
    final q = state.quiz.questions[state.currentIndex];
    final selected = state.selections[state.currentIndex];
    final revealed = state.revealed;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.weeklyQuizQuestionProgress(
                      state.currentIndex + 1,
                      state.quiz.questions.length,
                    ),
                    style: eyebrowStyle(context: context),
                  ),
                  const Spacer(),
                  if (state.isReadonly)
                    Text(l10n.weeklyQuizReviewBadge,
                        style: eyebrowStyle(context: context)),
                ],
              ),
              const SizedBox(height: 10),
              _ProgressSteps(
                key: _stepsKey,
                count: state.quiz.questions.length,
                current: state.currentIndex,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            children: [
              // The pet reads the question out (and has things to say).
              _QuizStage(
                index: state.currentIndex,
                total: state.quiz.questions.length,
                question: q.question,
                selected: selected,
                revealed: revealed,
                correct: selected == q.correctIndex,
                eats: !state.isReadonly,
                kind: context.read<QuizCubit>().kind,
                petKey: _petKey,
              ),
              const SizedBox(height: 22),
              Column(
                key: _optionsKey,
                children: List.generate(q.options.length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: i < q.options.length - 1 ? 10 : 0),
                    child: _OptionTile(
                      text: q.options[i],
                      index: i,
                      isSelected: selected == i,
                      isCorrect: revealed && i == q.correctIndex,
                      isWrong: revealed && selected == i && i != q.correctIndex,
                      onTap: state.isReadonly || revealed
                          ? null
                          : () {
                              SoundService.instance.play(Sfx.quizSelect);
                              context.read<QuizCubit>().selectOption(i);
                            },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              if (revealed) ...[
                const SizedBox(height: 10),
                _ExplanationBox(
                  correct: selected == q.correctIndex,
                  explanation: q.explanation,
                  kind:
                      state.isReadonly ? null : context.read<QuizCubit>().kind,
                ),
                // Self-rating chips — only when user can still mutate
                // (not in readonly review of a completed quiz from a
                // previous session).
                if (!state.isReadonly) ...[
                  const SizedBox(height: 18),
                  _SelfRatingRow(state: state),
                ],
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _BottomCTA(state: state),
        ),
      ],
    );
  }
}

/// One pill per question: done in walnut, the current one in cream.
class _ProgressSteps extends StatelessWidget {
  final int count;
  final int current;
  const _ProgressSteps({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i < current
                    ? palette.primary
                    : i == current
                        ? palette.primaryMuted
                        : palette.primarySoft,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The pet beside the question, in its reading glasses, with a line of its
/// own over its head now and then: hello, "hurry up, I'm hungry!" when
/// you dawdle, the last bite… It eats every answer as it's revealed — a
/// tasty one for a right answer, a funny-tasting one for a wrong one — and
/// burps once it's full.
class _QuizStage extends StatefulWidget {
  final int index;
  final int total;
  final String question;
  final int? selected;
  final bool revealed;
  final bool correct;

  /// Answering now (not reviewing a finished quiz): it eats each answer.
  final bool eats;
  final QuizKind kind;

  /// On the pet, for the first meal's coachmark to find it.
  final GlobalKey? petKey;
  const _QuizStage({
    required this.index,
    required this.total,
    required this.question,
    required this.selected,
    required this.revealed,
    required this.correct,
    required this.eats,
    required this.kind,
    this.petKey,
  });

  @override
  State<_QuizStage> createState() => _QuizStageState();
}

class _QuizStageState extends State<_QuizStage> {
  final _pet = BlobController();
  final _rng = math.Random();
  String? _line;
  Timer? _lineTimer;
  Timer? _hurry;
  int _hurries = 0;

  /// Its own line over its head for a moment.
  void _say(String line, {int ms = 2600}) {
    if (!mounted) return;
    _lineTimer?.cancel();
    setState(() => _line = line);
    _lineTimer = AppTimer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _line = null);
    });
  }

  void _later(int ms, VoidCallback fn) =>
      AppTimer(Duration(milliseconds: ms), () {
        if (mounted) fn();
      });

  @override
  void initState() {
    super.initState();
    if (widget.eats) {
      _later(450, () {
        final l10n = AppLocalizations.of(context)!;
        _say(widget.kind == QuizKind.daily
            ? l10n.quizPetStart
            : l10n.quizPetFeastStart);
      });
      _waitForAnswer();
    }
  }

  @override
  void didUpdateWidget(_QuizStage old) {
    super.didUpdateWidget(old);
    if (!widget.eats) return;
    final l10n = AppLocalizations.of(context)!;
    if (widget.index != old.index && !widget.revealed) {
      // A new question.
      _hurries = 0;
      _waitForAnswer();
      if (widget.index == widget.total - 1) _say(l10n.quizPetLast);
    } else if (widget.selected != null &&
        old.selected == null &&
        !widget.revealed) {
      _hurry?.cancel();
      if (_rng.nextDouble() < 0.35) _say(l10n.quizPetPicked, ms: 1800);
    }
    if (widget.revealed && !old.revealed) _answered(l10n);
  }

  /// Dawdle over a question and it gets impatient.
  void _waitForAnswer() {
    _hurry?.cancel();
    _hurry = AppTimer(Duration(seconds: _hurries == 0 ? 8 : 14), () {
      if (!mounted || widget.revealed || widget.selected != null) return;
      // Not while it's being shown around.
      if (Coachmark.showing.value) return _waitForAnswer();
      final l10n = AppLocalizations.of(context)!;
      _pet.express(BlobExpression.hungry,
          duration: const Duration(milliseconds: 2800));
      _say(_hurries == 0 ? l10n.quizPetHurry : l10n.quizPetHurryAgain);
      _hurries++;
      if (_hurries < 2) _waitForAnswer();
    });
  }

  /// It eats the answer: savours a right one, pulls a face at a wrong one,
  /// and burps if that filled it up.
  void _answered(AppLocalizations l10n) {
    _hurry?.cancel();
    final right = widget.correct;
    SoundService.instance.play(right ? Sfx.quizCorrect : Sfx.quizWrong);
    _pet.eat(FoodKind.meal(feast: widget.kind == QuizKind.weekly),
        tasty: right);
    _later(1050, () => _say(right ? l10n.quizPetYum : l10n.quizPetYuck));
    final eatMs = BlobController.eatLength.inMilliseconds + (right ? 150 : 650);
    if (sl<PetStore>().state.fullnessAt(DateTime.now()) >= _burpAbove) {
      _later(eatMs, () {
        _pet.burp();
        _say(l10n.quizPetBurp);
      });
    }
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    _hurry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expression = !widget.revealed
        ? BlobExpression.serious
        : widget.correct
            ? null
            : BlobExpression.sad;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room for its line, the tail pointing down at its head.
        SizedBox(
          height: 46,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 2),
              child: _PetLine(text: _line),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            PetHost(
              key: widget.petKey,
              height: 70,
              glasses: true,
              expression: expression,
              controller: _pet,
              // Its face follows your answers; no idle moves mid-quiz.
              idle: false,
            ),
            const SizedBox(width: 4),
            Expanded(child: _QuestionBubble(text: widget.question)),
          ],
        ),
      ],
    );
  }
}

/// Full enough to burp.
const _burpAbove = 92.0;

/// A fresh result: the fanfare, then what the pet got pops in (just as
/// the fanfare fades), then the pet has its say.
Duration _chipsAt(bool feast) => Duration(milliseconds: feast ? 1800 : 1400);
const _petAfterChips = Duration(milliseconds: 600);

/// The pet over the results: a good meal and it's full (a burp, "so
/// full!"), or still a bit peckish and keen to study more.
class _ResultHost extends StatefulWidget {
  final bool good;

  /// Just finished (not an old quiz looked back at).
  final bool fresh;

  /// The weekly feast rather than the daily meal: a bigger fanfare.
  final bool feast;
  const _ResultHost(
      {required this.good, required this.fresh, required this.feast});

  @override
  State<_ResultHost> createState() => _ResultHostState();
}

class _ResultHostState extends State<_ResultHost> {
  final _pet = BlobController();
  String? _line;

  @override
  void initState() {
    super.initState();
    if (!widget.fresh) return;
    SoundService.instance.play(widget.feast ? Sfx.quizFeast : Sfx.quizComplete);
    AppTimer(_chipsAt(widget.feast) + _petAfterChips, () {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final full = sl<PetStore>().state.fullnessAt(DateTime.now()) >=
          PetState.refuseAbove - 10;
      if (widget.good && full) {
        _pet.burp();
        setState(() => _line = l10n.quizPetFull);
      } else if (widget.good) {
        _pet.beam(duration: const Duration(milliseconds: 1600));
        setState(() => _line = l10n.quizPetDoneGood);
      } else {
        setState(() => _line = l10n.quizPetDoneMeh);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _PetLine(text: _line, centered: true),
          ),
        ),
        Center(
          child: PetHost(
            height: 104,
            expression: widget.good ? null : BlobExpression.sad,
            controller: _pet,
            idle: false,
          ),
        ),
      ],
    );
  }
}

/// A short line from the pet in a little bubble, its tail pointing down
/// at the pet ([centered] for a pet right below it, else bottom-left).
class _PetLine extends StatelessWidget {
  final String? text;
  final bool centered;
  const _PetLine({required this.text, this.centered = false});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final line = text;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(anim),
          alignment: centered ? Alignment.bottomCenter : Alignment.bottomLeft,
          child: child,
        ),
      ),
      child: line == null
          ? const SizedBox(key: ValueKey('none'))
          : Column(
              key: ValueKey(line),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: centered
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
                  decoration: softCard(context, radius: 14),
                  child: Text(
                    line,
                    style: AppFonts.body(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: centered ? 0 : 14),
                  child: CustomPaint(
                    size: const Size(12, 6),
                    painter: _DownTailPainter(
                      fill: palette.surface,
                      stroke: palette.surfaceStroke,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DownTailPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  _DownTailPainter({required this.fill, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, -1)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, -1);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = stroke,
    );
    canvas.drawRect(
        Rect.fromLTWH(1, -2, size.width - 2, 2), Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_DownTailPainter old) =>
      old.fill != fill || old.stroke != stroke;
}

/// The question in a speech bubble, its tail pointing at the pet.
class _QuestionBubble extends StatelessWidget {
  final String text;
  const _QuestionBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: softCard(context, radius: 22),
            child: Text(
              text,
              style: AppFonts.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                height: 1.35,
                color: palette.textPrimary,
              ),
            ),
          ),
          Positioned(
            left: -8,
            bottom: 14,
            child: CustomPaint(
              size: const Size(10, 16),
              painter: _TailPainter(
                fill: palette.surface,
                stroke: palette.surfaceStroke,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  _TailPainter({required this.fill, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width + 1, 0)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.75, 0, size.height)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.9, size.width + 1,
          size.height * 0.6);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Hide the stroke where the tail meets the bubble.
    canvas.drawRect(
      Rect.fromLTWH(size.width - 0.5, 0.5, 2, size.height * 0.6 - 1),
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) =>
      old.fill != fill || old.stroke != stroke;
}

// One answer card.
class _OptionTile extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.text,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    var border = palette.surfaceStroke;
    var bg = palette.surface;
    var disc = palette.primarySoft;
    var discInk = palette.primary;
    IconData? trailing;
    var trailingColor = palette.textSecondary;
    var width = 1.0;

    if (isCorrect) {
      border = palette.success;
      bg = Color.alphaBlend(
          palette.success.withValues(alpha: 0.1), palette.surface);
      disc = palette.success;
      discInk = Colors.white;
      trailing = Icons.check_circle_rounded;
      trailingColor = palette.success;
      width = 1.6;
    } else if (isWrong) {
      border = palette.danger;
      bg = Color.alphaBlend(
          palette.danger.withValues(alpha: 0.08), palette.surface);
      disc = palette.danger;
      discInk = Colors.white;
      trailing = Icons.cancel_rounded;
      trailingColor = palette.danger;
      width = 1.6;
    } else if (isSelected) {
      border = palette.primary;
      bg = Color.alphaBlend(
          palette.primarySoft.withValues(alpha: 0.7), palette.surface);
      disc = palette.primary;
      discInk = palette.onPrimary;
      width = 1.6;
    }

    final letter = String.fromCharCode(65 + index); // A, B, C, D

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      child: SoftButton(
        onTap: onTap,
        color: bg,
        bordered: false,
        shadow: !isSelected && !isCorrect && !isWrong,
        radius: 18,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: width),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: disc),
                child: Text(
                  letter,
                  style: AppFonts.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: discInk,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: AppFonts.body(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, size: 20, color: trailingColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Why the answer is what it is, shown after it's revealed.
class _ExplanationBox extends StatelessWidget {
  final bool correct;
  final String explanation;

  /// While answering: what the pet just ate for it (null when reviewing).
  final QuizKind? kind;
  const _ExplanationBox({
    required this.correct,
    required this.explanation,
    this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final accent = correct ? palette.success : palette.warning;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withValues(alpha: 0.1), palette.surface),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct
                    ? Icons.celebration_rounded
                    : Icons.lightbulb_outline_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                correct
                    ? l10n.weeklyQuizCorrectBadge
                    : l10n.weeklyQuizWrongBadge,
                style: eyebrowStyle(color: accent),
              ),
              const Spacer(),
              if (kind != null) _MealChip(kind: kind!, correct: correct),
            ],
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              explanation,
              style: AppFonts.body(
                fontSize: 14,
                height: 1.55,
                color: palette.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "+20 full" with the dish the pet just ate (or "+14 growth" at the
/// weekly feast).
class _MealChip extends StatelessWidget {
  final QuizKind kind;
  final bool correct;
  const _MealChip({required this.kind, required this.correct});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final gain = _gain(kind, correct);
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FoodIcon(
              kind: FoodKind.meal(feast: kind == QuizKind.weekly), size: 20),
          const SizedBox(width: 4),
          Text(
            kind == QuizKind.daily
                ? l10n.quizGainFull(gain)
                : l10n.quizGainGrowth(gain),
            style: AppFonts.body(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom CTA: changes label/behaviour based on state.
class _BottomCTA extends StatelessWidget {
  final QuizActive state;
  const _BottomCTA({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<QuizCubit>();

    // Layout: Prev button on the left when not on the first question, plus
    // a primary button on the right whose label depends on phase.
    final showPrev = state.currentIndex > 0;
    String primaryLabel;
    VoidCallback? primaryAction;

    if (state.isReadonly) {
      // Review mode for already-completed quiz.
      primaryLabel = state.isLastQuestion
          ? l10n.weeklyQuizFinishCta
          : l10n.weeklyQuizNextCta;
      primaryAction =
          state.isLastQuestion ? () => context.pop() : cubit.nextQuestion;
    } else if (!state.revealed) {
      // Active answering — show "Periksa" once a selection is made.
      primaryLabel = l10n.weeklyQuizCheckCta;
      primaryAction = state.hasSelection ? cubit.revealAnswer : null;
    } else if (!state.isLastQuestion) {
      primaryLabel = l10n.weeklyQuizNextCta;
      primaryAction = cubit.nextQuestion;
    } else {
      primaryLabel = state.submitting
          ? l10n.weeklyQuizSubmittingCta
          : l10n.weeklyQuizSubmitCta;
      primaryAction = state.submitting ? null : cubit.submit;
    }

    final palette = context.palette;
    return Row(
      children: [
        if (showPrev) ...[
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: _sentence(l10n.weeklyQuizPrevCta),
            onTap: cubit.previousQuestion,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: FilledButton(
            onPressed: primaryAction,
            style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(52),
              disabledBackgroundColor: palette.primarySoft,
              disabledForegroundColor: palette.textTertiary,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.submitting) ...[
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: palette.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(_sentence(primaryLabel)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Self-rating chips ───────────────────────────────────────────────
//
// Setelah user reveal jawaban, kasih 3 chip (Mudah / Pas / Sulit)
// untuk drive cooldown spaced-repetition. Default-nya null (tidak
// di-rate); kalau user lanjut tanpa milih, server akan derive
// difficulty dari implicit signal (correctness + response time).
class _SelfRatingRow extends StatelessWidget {
  final QuizActive state;
  const _SelfRatingRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final picked = state.selfRatings[state.currentIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quizSelfRatingPrompt,
          style: AppFonts.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _RatingChip(
              label: l10n.quizSelfRatingEasy,
              selected: picked == QuizSelfRating.easy,
              accent: context.palette.success,
              onTap: () =>
                  context.read<QuizCubit>().rateCurrent(QuizSelfRating.easy),
            ),
            const SizedBox(width: 8),
            _RatingChip(
              label: l10n.quizSelfRatingMedium,
              selected: picked == QuizSelfRating.medium,
              accent: context.palette.primary,
              onTap: () =>
                  context.read<QuizCubit>().rateCurrent(QuizSelfRating.medium),
            ),
            const SizedBox(width: 8),
            _RatingChip(
              label: l10n.quizSelfRatingHard,
              selected: picked == QuizSelfRating.hard,
              accent: context.palette.warning,
              onTap: () =>
                  context.read<QuizCubit>().rateCurrent(QuizSelfRating.hard),
            ),
          ],
        ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _RatingChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.16), context.palette.surface)
            : context.palette.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? accent.withValues(alpha: 0.6)
                : context.palette.surfaceStroke,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
            child: Center(
              child: Text(
                label,
                style: AppFonts.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Color.lerp(accent, context.palette.textPrimary, 0.3)
                      : context.palette.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Result view ─────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final QuizActive state;
  const _ResultView({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final score = state.quiz.score ?? state.score;
    final total = state.quiz.questions.length;
    final perfect = score == total;
    final good = perfect || score / total >= 0.6;
    final kind = context.read<QuizCubit>().kind;
    final daily = kind == QuizKind.daily;
    // What the pet got out of it: every answer, right or wrong.
    var fed = 0;
    for (var i = 0; i < total; i++) {
      fed += _gain(
          kind, state.selections[i] == state.quiz.questions[i].correctIndex);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            children: [
              // The pet's verdict, then the score.
              _ResultHost(good: good, fresh: !state.isReadonly, feast: !daily),
              const SizedBox(height: 14),
              Center(
                child: Text(
                    daily
                        ? l10n.quizMealScoreEyebrow
                        : l10n.weeklyQuizScoreEyebrow,
                    style: eyebrowStyle(context: context)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: AppFonts.display(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 1,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '/ $total',
                      style: AppFonts.display(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: palette.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                perfect
                    ? l10n.weeklyQuizResultPerfect
                    : score >= 3
                        ? l10n.weeklyQuizResultGood
                        : l10n.weeklyQuizResultRetry,
                textAlign: TextAlign.center,
                style: AppFonts.body(
                  fontSize: 15,
                  height: 1.55,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // What the pet ate.
              _PopIn(
                at: state.isReadonly ? null : _chipsAt(!daily),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ResultChip(
                      icon:
                          daily ? Icons.restaurant_rounded : Icons.spa_rounded,
                      color: daily ? palette.accent : palette.success,
                      text: daily
                          ? l10n.quizGainFull(fed)
                          : l10n.quizGainGrowth(fed),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                daily
                    ? (state.hardCarryOverNext == 0
                        ? l10n.quizResultHardCarryNoneDaily
                        : l10n
                            .quizResultHardCarryDaily(state.hardCarryOverNext))
                    : (state.hardCarryOverNext == 0
                        ? l10n.quizResultHardCarryNone
                        : l10n.quizResultHardCarry(state.hardCarryOverNext)),
                textAlign: TextAlign.center,
                style: AppFonts.body(
                  fontSize: 12.5,
                  height: 1.5,
                  color: palette.textTertiary,
                ),
              ),
              const SizedBox(height: 26),
              Text(l10n.weeklyQuizSummaryEyebrow,
                  style: eyebrowStyle(context: context)),
              const SizedBox(height: 10),
              Container(
                decoration: softCard(context, radius: 20),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < total; i++)
                      Builder(builder: (context) {
                        final correct = state.selections[i] ==
                            state.quiz.questions[i].correctIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          child: Row(
                            children: [
                              Icon(
                                correct
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 18,
                                color:
                                    correct ? palette.success : palette.danger,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  state.quiz.questions[i].question,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.body(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(_sentence(l10n.weeklyQuizCloseCta)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => context.read<QuizCubit>().reviewAnswers(),
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(_sentence(l10n.weeklyQuizReviewCta)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small rounded tag on the results: what the pet ate, or XP.
class _ResultChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _ResultChip({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppFonts.display(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color.lerp(color, palette.textPrimary, 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pops [child] in at [at] with a little "XP" chime; there from the start
/// when [at] is null (an old quiz looked back at).
class _PopIn extends StatefulWidget {
  final Duration? at;
  final Widget child;
  const _PopIn({required this.at, required this.child});

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.at == null ? 1 : 0,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final at = widget.at;
    if (at == null) return;
    _timer = AppTimer(at, () {
      if (!mounted) return;
      SoundService.instance.play(Sfx.quizXp);
      _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
        child: widget.child,
      ),
    );
  }
}
