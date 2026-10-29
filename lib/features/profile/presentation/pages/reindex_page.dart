import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/env.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../vault/presentation/bloc/vault_bloc.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../companion/presentation/widgets/pet_offline.dart';

/// Maintenance page for re-embedding the user's notes.
///
/// Why this exists: when the embedding model on the backend changes
/// (different provider / different dimension count), notes saved with
/// the old model become silently unsearchable — the cosine similarity
/// against the new query embeddings is noise. The fix is to clear the
/// `embedding` column for every owned note and re-run the
/// `reembed-missing` Edge Function, which picks up `WHERE embedding IS
/// NULL` rows and refills them with the current model.
///
/// Two-step UX so the action is deliberate:
///   1. "Reset embedding" — confirms + nulls the column for all notes.
///   2. "Jalankan re-embed" — fires the edge function and shows a
///      tally of how many notes were processed.
///
/// We deliberately don't merge the two into one button: in the rare
/// case the function fails midway the user can re-run step 2 without
/// re-nulling state.
class ReindexPage extends StatefulWidget {
  const ReindexPage({super.key});

  @override
  State<ReindexPage> createState() => _ReindexPageState();
}

class _ReindexPageState extends State<ReindexPage> {
  final SupabaseService _service = sl<SupabaseService>();

  bool _resetting = false;
  bool _running = false;

  /// How many notes the user owns and how many of those are missing
  /// embeddings. Re-checked on every page load and after each action.
  int _total = 0;
  int _missing = 0;

  /// Notes without an embedding that have nothing to embed (no title, no
  /// text — e.g. a link saved before its auto-fill came through). The
  /// function skips them, so they don't count as [_missing].
  int _empty = 0;
  bool _statsLoading = true;
  String? _lastResult;

  /// Raw response body / error stack from the last edge function call
  /// — surfaced under the result banner when present so we can debug
  /// silent "0 processed" cases (usually a schema mismatch on the
  /// server side).
  String? _lastResultDetail;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    if (!mounted) return;
    setState(() => _statsLoading = true);
    try {
      final userId = _service.currentUserId;
      if (userId == null) return;
      final total = await _service.db
          .from(AppConstants.tContentVault)
          .count();
      final missingRows = await _service.db
          .from(AppConstants.tContentVault)
          .select('id, title, manual_notes')
          .eq('user_id', userId)
          .filter('embedding', 'is', null);
      // The same text `reembed-missing` embeds: title and notes.
      bool hasText(Map<String, dynamic> r) =>
          '${r['title'] ?? ''}${r['manual_notes'] ?? ''}'.trim().isNotEmpty;
      final embeddable = missingRows.where(hasText).length;
      if (!mounted) return;
      setState(() {
        _total = total;
        _missing = embeddable;
        _empty = missingRows.length - embeddable;
        _statsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsLoading = false;
      });
    }
  }

  /// Step 1 — null out every embedding. Confirmation gated.
  Future<void> _resetEmbeddings() async {
    if (!await ensureOnline(context, OnlineFeature.reindex) || !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirm(
      title: l10n.reindexResetDialogTitle,
      body: l10n.reindexResetDialogBody,
      destructiveLabel: l10n.reindexResetDialogConfirm,
    );
    if (!ok || !mounted) return;
    setState(() => _resetting = true);
    try {
      final userId = _service.currentUserId;
      if (userId == null) {
        throw StateError(l10n.reindexNotLoggedIn);
      }
      // Update every row owned by the current user — RLS makes sure
      // we don't accidentally touch anyone else's data.
      await _service.db
          .from(AppConstants.tContentVault)
          .update({'embedding': null})
          .eq('user_id', userId);
      if (!mounted) return;
      setState(() {
        _resetting = false;
        _lastResult = l10n.reindexResetDoneNudge;
      });
      await _refreshStats();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resetting = false;
        _lastResult = l10n.reindexResetFailed(e.toString());
      });
    }
  }

  /// Step 2 — call `reembed-missing` which iterates over
  /// `embedding IS NULL` rows and fills them with fresh vectors using
  /// whatever model the backend currently has configured.
  Future<void> _runReembed() async {
    if (!await ensureOnline(context, OnlineFeature.reindex) || !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _running = true;
      _lastResult = null;
      _lastResultDetail = null;
    });
    try {
      final token = await _service.ensureFreshAccessToken();
      if (token == null) throw StateError(l10n.reindexNotLoggedIn);

      // Use Dio so we get a clean status code + JSON body. The
      // function follows the same shape as the other edge calls.
      final dio = Dio();
      final res = await dio.post<Map<String, dynamic>>(
        '${Env.supabaseUrl}/functions/v1/${AppConstants.fnReembedMissing}',
        data: const {},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'apikey': Env.supabaseAnonKey,
            'Content-Type': 'application/json',
          },
          // Some re-embed runs take >30s with many notes — bump the
          // total timeout to 5 minutes; backend is already streaming
          // with internal batching.
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
          validateStatus: (_) => true,
        ),
      );

      if (!mounted) return;
      if (res.statusCode != 200) {
        final body = res.data ?? const <String, dynamic>{};
        final msg = body['error'] as String? ?? 'HTTP ${res.statusCode}';
        setState(() {
          _running = false;
          _lastResult = l10n.reindexRunFailed(msg);
          _lastResultDetail = res.data?.toString();
        });
        return;
      }
      final body = res.data ?? const <String, dynamic>{};
      // `processed` / `skipped` come per table ({ content_vault: N,
      // personal_notes: M, … }); older versions sent a plain number.
      int? tally(Object? v) => switch (v) {
            num n => n.toInt(),
            Map m => m.values
                .whereType<num>()
                .fold<int>(0, (sum, n) => sum + n.toInt()),
            _ => null,
          };
      final processed = tally(body['processed']) ?? tally(body['count']);
      final skipped = tally(body['skipped']) ?? 0;
      final errors = (body['errors'] as List?) ?? const [];
      setState(() {
        _running = false;
        _lastResult = [
          processed == null
              ? l10n.reindexRunDone
              : l10n.reindexRunDoneCount(processed),
          if (skipped > 0) l10n.reindexRunSkipped(skipped),
          if (errors.isNotEmpty) l10n.reindexRunErrors(errors.length),
        ].join(' ');
        // What went wrong, for the ones that failed.
        _lastResultDetail = errors.isEmpty
            ? null
            : [
                for (final e in errors)
                  if (e is Map) '${e['table']} ${e['id']}: ${e['reason']}',
              ].join('\n');
      });
      await _refreshStats();
      // Tell VaultBloc to refresh — once embeddings are back the chat
      // assistant can find them again. Force a list reload so any UI
      // tied to embedding presence is in sync.
      if (mounted) {
        context.read<VaultBloc>().add(const VaultLoadRequested());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _lastResult = l10n.reindexRunFailed(e.toString());
        _lastResultDetail = null;
      });
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String destructiveLabel,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final res = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.palette.surfaceStroke, width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 14, 12),
        title: Text(
          title,
          style: AppFonts.display(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: context.palette.textPrimary,
          ),
        ),
        content: Text(
          body,
          style: AppFonts.body(
            fontSize: 14,
            height: 1.55,
            color: context.palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style:
                TextButton.styleFrom(foregroundColor: context.palette.textTertiary),
            child: Text(l10n.reindexConfirmCancel,
                style: AppFonts.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textTertiary,
                )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(destructiveLabel,
                style: AppFonts.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                )),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = _resetting || _running;
    return Scaffold(
      appBar: PageTopBar(title: l10n.reindexAppBarTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
          children: [
            Text(l10n.reindexTitle, style: pageTitleStyle(context: context, size: 30)),
            const SizedBox(height: 6),
            Text(
              l10n.reindexSubtitle,
              style: AppFonts.body(
                fontSize: 13,
                color: context.palette.textTertiary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 22),

            // ── Stats ──────────────────────────────────────────
            _StatsCard(
              total: _total,
              missing: _missing,
              empty: _empty,
              loading: _statsLoading,
              onRefresh: _refreshStats,
            ),
            const SizedBox(height: 28),

            // ── Step 1 — Reset embeddings ─────────────────────
            SectionHeader(label: l10n.reindexStep1Eyebrow),
            const SizedBox(height: 10),
            Text(
              l10n.reindexStep1Title,
              style: AppFonts.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.reindexStep1Description,
              style: AppFonts.body(
                fontSize: 13,
                color: context.palette.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 14),
            _ActionButton(
              label: _resetting
                  ? l10n.reindexStep1Busy
                  : l10n.reindexStep1Action,
              icon: Icons.restart_alt_rounded,
              danger: true,
              busy: _resetting,
              enabled: !busy && _total > 0,
              onPressed: _resetEmbeddings,
            ),
            const SizedBox(height: 32),

            // ── Step 2 — Run re-embed ─────────────────────────
            SectionHeader(label: l10n.reindexStep2Eyebrow),
            const SizedBox(height: 10),
            Text(
              l10n.reindexStep2Title,
              style: AppFonts.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.reindexStep2Description,
              style: AppFonts.body(
                fontSize: 13,
                color: context.palette.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 14),
            _ActionButton(
              label: _running
                  ? l10n.reindexStep2Busy
                  : l10n.reindexStep2Action,
              icon: Icons.auto_awesome_outlined,
              busy: _running,
              enabled: !busy && _missing > 0,
              onPressed: _runReembed,
            ),

            if (_lastResult != null) ...[
              const SizedBox(height: 22),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.palette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.palette.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: context.palette.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _lastResult!,
                            style: AppFonts.body(
                              fontSize: 13,
                              color: context.palette.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_lastResultDetail != null) ...[
                      const SizedBox(height: 10),
                      // Raw response from the edge function — handy
                      // when "0 processed" looks suspicious. Mono
                      // font + selectable so the user can paste it
                      // into a debug session.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.palette.bgPrimary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.palette.surfaceStroke,
                          ),
                        ),
                        child: SelectableText(
                          _lastResultDetail!,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: context.palette.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int total;
  final int missing;
  final int empty;
  final bool loading;
  final VoidCallback onRefresh;
  const _StatsCard({
    required this.total,
    required this.missing,
    required this.empty,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: context.palette.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.surfaceStroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.reindexStatusEyebrow, style: eyebrowStyle(context: context)),
                const SizedBox(height: 6),
                if (loading)
                  Text(
                    l10n.reindexStatusLoading,
                    style: AppFonts.body(
                      fontSize: 13,
                      color: context.palette.textSecondary,
                    ),
                  )
                else
                  Text(
                    missing == 0
                        ? l10n.reindexStatusReady(total - empty)
                        : l10n.reindexStatusMissing(missing, total),
                    style: AppFonts.body(
                      fontSize: 14,
                      color: context.palette.textPrimary,
                      height: 1.45,
                    ),
                  ),
                if (!loading && empty > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.reindexStatusEmpty(empty),
                    style: AppFonts.body(
                      fontSize: 12.5,
                      color: context.palette.textTertiary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.reindexRefreshTooltip,
            onPressed: loading ? null : onRefresh,
            icon: Icon(Icons.refresh_rounded,
                size: 18, color: context.palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool busy;
  final bool enabled;
  final bool danger;
  final VoidCallback onPressed;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.enabled,
    required this.onPressed,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // A soft pill: cream for the everyday action, a pink tint for the
    // destructive one.
    final color = danger ? palette.danger : palette.primary;
    final fill = danger
        ? Color.alphaBlend(palette.danger.withValues(alpha: 0.1), palette.bgPrimary)
        : palette.primarySoft;
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.6, color: color),
              )
            : Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: AppFonts.body(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: fill,
          disabledBackgroundColor: palette.bgTertiary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
