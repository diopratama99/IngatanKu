import 'package:flutter/material.dart';
import '../../../../core/services/voice_input_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Compact mic button. Tap = start, tap again = stop. Shows pulsing glow while active.
class VoiceInputButton extends StatefulWidget {
  final VoiceInputService service;

  /// Called with the partial transcript on every update; final flag indicates session end.
  final void Function(String text, bool isFinal) onTranscript;

  /// Optional locale override (e.g. 'id_ID', 'en_US'). Leave null to use
  /// the service's auto-resolved best locale (defaults to Bahasa Indonesia
  /// when available on the device).
  final String? localeId;

  /// Fires once when the listening session starts.
  final VoidCallback? onStart;

  const VoiceInputButton({
    super.key,
    required this.service,
    required this.onTranscript,
    this.localeId,
    this.onStart,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  bool _listening = false;

  @override
  void dispose() {
    widget.service.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await widget.service.stop();
      setState(() => _listening = false);
      return;
    }
    widget.onStart?.call();
    setState(() => _listening = true);
    await widget.service.listen(
      localeId: widget.localeId,
      onResult: (text, isFinal) {
        widget.onTranscript(text, isFinal);
        if (isFinal && mounted) setState(() => _listening = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _listening ? AppColors.danger : AppColors.primary,
        ),
        child: Icon(
          _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
