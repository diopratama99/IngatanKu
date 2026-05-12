import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NeonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final bool loading;
  final double radius;
  final EdgeInsets padding;
  final bool fullWidth;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient = AppColors.primaryGradient,
    this.loading = false,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.fullWidth = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.fullWidth ? double.infinity : null,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.bgTertiary
              : (_pressed ? AppColors.primaryDark : AppColors.primary),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        child: Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else if (widget.icon != null) ...[
              Icon(widget.icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              widget.loading ? 'Memuat…' : widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
