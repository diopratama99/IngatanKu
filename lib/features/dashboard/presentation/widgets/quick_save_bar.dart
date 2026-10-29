import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Pulls the first http(s) URL out of whatever the user pasted ("lihat
/// ini https://…" still works). Bare domains like `youtu.be/abc` get an
/// https:// prefix. Returns null when nothing link-shaped is found.
String? extractLink(String raw) {
  final text = raw.trim();
  final match = RegExp(r'https?://\S+', caseSensitive: false).firstMatch(text);
  if (match != null) return match.group(0);
  if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
  final candidate = 'https://$text';
  final uri = Uri.tryParse(candidate);
  if (uri == null || !uri.host.contains('.')) return null;
  return candidate;
}

/// The big "paste a link" pill on Beranda. Once a link is in, it shows as
/// a domain chip with a check button; saving happens right here.
class QuickSaveBar extends StatefulWidget {
  final bool saving;

  /// Return true to clear the field (link accepted).
  final Future<bool> Function(String raw) onSubmit;
  final VoidCallback onClipboardEmpty;

  /// Lets the page put a link in (one shared from another app). The bar
  /// makes its own when null.
  final TextEditingController? controller;

  /// Lets the page put the cursor in the bar. Made here when null.
  final FocusNode? focusNode;
  const QuickSaveBar({
    super.key,
    required this.saving,
    required this.onSubmit,
    required this.onClipboardEmpty,
    this.controller,
    this.focusNode,
  });

  @override
  State<QuickSaveBar> createState() => _QuickSaveBarState();
}

class _QuickSaveBarState extends State<QuickSaveBar> {
  late final _ctrl = widget.controller ?? TextEditingController();
  late final _focus = widget.focusNode ?? FocusNode();

  void _changed() => setState(() {});

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_changed);
    if (widget.controller == null) _ctrl.dispose();
    _focus.removeListener(_changed);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.saving || _ctrl.text.trim().isEmpty) return;
    _focus.unfocus();
    final accepted = await widget.onSubmit(_ctrl.text);
    if (mounted && accepted) _ctrl.clear();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      widget.onClipboardEmpty();
      return;
    }
    _ctrl.text = text;
    _ctrl.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final link = extractLink(_ctrl.text);
    // Show the link as a tidy chip once it's recognised and the field
    // isn't being edited.
    final chip = link != null && !_focus.hasFocus;
    final host = link == null
        ? ''
        : (Uri.tryParse(link)?.host ?? link).replaceFirst('www.', '');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 62,
      padding: const EdgeInsets.only(left: 18, right: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(
          color: _focus.hasFocus
              ? palette.primary.withValues(alpha: 0.5)
              : palette.surfaceStroke,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.add_rounded, size: 24, color: palette.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Opacity(
                  opacity: chip ? 0 : 1,
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    enabled: !widget.saving,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    onSubmitted: (_) => _submit(),
                    style:
                        AppFonts.body(fontSize: 15, color: palette.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.homeQuickSaveHint,
                      hintStyle: AppFonts.body(
                          fontSize: 15, color: palette.textTertiary),
                      filled: false,
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                if (chip)
                  GestureDetector(
                    onTap: () => _focus.requestFocus(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_rounded,
                              size: 15, color: palette.textSecondary),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 170),
                            child: Text(
                              host,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: _ctrl.text.trim().isNotEmpty || widget.saving
                ? _Round(
                    key: const ValueKey('save'),
                    filled: true,
                    tooltip: l10n.homeQuickSaveSend,
                    onTap: widget.saving ? null : _submit,
                    child: widget.saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.palette.onPrimary),
                          )
                        : Icon(Icons.check_rounded,
                            size: 22, color: context.palette.onPrimary),
                  )
                : _Round(
                    key: const ValueKey('paste'),
                    filled: false,
                    tooltip: l10n.homeQuickSavePaste,
                    onTap: _paste,
                    child: Icon(Icons.content_paste_rounded,
                        size: 18, color: palette.textTertiary),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Round extends StatelessWidget {
  final bool filled;
  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;
  const _Round({
    super.key,
    required this.filled,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? palette.primary : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 46, height: 46, child: Center(child: child)),
        ),
      ),
    );
  }
}
