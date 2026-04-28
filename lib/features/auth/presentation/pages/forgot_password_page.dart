import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../bloc/auth_bloc.dart';

/// Three-step in-app password reset:
///   1. [_Step.email]       — collect email and send recovery OTP
///   2. [_Step.otp]          — verify the 6-digit recovery code
///   3. [_Step.newPassword] — pick a new password & submit
///
/// Step transitions are driven by [AuthBloc] state — this widget just
/// listens and animates the [AnimatedSwitcher].
enum _Step { email, otp, newPassword }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _otpFocus = FocusNode();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();

  _Step _step = _Step.email;
  String _email = '';
  bool _obscure = true;
  bool _obscureConfirm = true;

  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _otpFocus.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────

  void _sendCode() {
    if (!_emailFormKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    context.read<AuthBloc>().add(AuthPasswordResetRequested(email));
  }

  void _resendCode() {
    if (_resendCooldown > 0) return;
    context.read<AuthBloc>().add(AuthPasswordResetRequested(_email));
  }

  void _verifyCode(String code) {
    if (code.length != 6) return;
    context.read<AuthBloc>().add(
          AuthPasswordResetVerifyRequested(email: _email, token: code),
        );
  }

  void _submitNewPassword() {
    if (!_passwordFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthPasswordUpdateRequested(_passCtrl.text));
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthError) {
          context.showSnack(state.message, error: true);
          if (_step == _Step.otp) {
            _otpCtrl.clear();
            _otpFocus.requestFocus();
          }
        } else if (state is AuthPasswordResetCodeSent) {
          setState(() {
            _email = state.email;
            _step = _Step.otp;
          });
          _startCooldown();
          // Re-focus the OTP input on next frame so the keyboard pops.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _otpFocus.requestFocus();
          });
        } else if (state is AuthPasswordResetVerified) {
          setState(() => _step = _Step.newPassword);
        } else if (state is Authenticated) {
          context.go(Routes.dashboard);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: BackButton(onPressed: _onBack),
          title: Text('LUPA KATA SANDI', style: eyebrowStyle()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepIndicator(step: _step),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onBack() {
    // From OTP step → back to email step (don't pop the page).
    // From newPassword → back to OTP isn't safe (recovery already used the
    // OTP), so we go straight back to login.
    if (_step == _Step.otp) {
      setState(() => _step = _Step.email);
      return;
    }
    context.pop();
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.email:
        return _emailStep();
      case _Step.otp:
        return _otpStep();
      case _Step.newPassword:
        return _newPasswordStep();
    }
  }

  // ── Step 1: Email ────────────────────────────────────────────────────

  Widget _emailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Atur ulang\nkata sandi.', style: pageTitleStyle(size: 40)),
          const SizedBox(height: 14),
          Text(
            'Masukkan email akunmu — kami akan kirim kode 6 digit '
            'untuk verifikasi.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          Text('EMAIL', style: eyebrowStyle()),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(hintText: 'kamu@example.com'),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
          ),
          const SizedBox(height: 28),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (_, state) => EditorialButton(
              label: 'Kirim kode reset',
              icon: Icons.mail_outline_rounded,
              fullWidth: true,
              loading: state is AuthLoading,
              onPressed: _sendCode,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: OTP ─────────────────────────────────────────────────────

  Widget _otpStep() {
    final defaultPin = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceFill,
        border: Border.all(color: AppColors.surfaceStroke),
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Cek\nemailmu.', style: pageTitleStyle(size: 40)),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Kode 6 digit dikirim ke\n'),
              TextSpan(
                text: _email,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Text('KODE OTP', style: eyebrowStyle()),
        const SizedBox(height: 10),
        Pinput(
          length: 6,
          controller: _otpCtrl,
          focusNode: _otpFocus,
          autofocus: true,
          defaultPinTheme: defaultPin,
          focusedPinTheme: defaultPin.copyBorderWith(
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          submittedPinTheme: defaultPin.copyWith(
            decoration: defaultPin.decoration!.copyWith(
              color: AppColors.bgTertiary,
              border: Border.all(color: AppColors.primary),
            ),
          ),
          onCompleted: _verifyCode,
          keyboardType: TextInputType.number,
          pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
        ),
        const SizedBox(height: 28),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (_, state) => EditorialButton(
            label: 'Verifikasi',
            icon: Icons.arrow_forward_rounded,
            fullWidth: true,
            loading: state is AuthLoading,
            onPressed: () => _verifyCode(_otpCtrl.text),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: _resendCooldown > 0 ? null : _resendCode,
            child: Text(
              _resendCooldown > 0
                  ? 'Kirim ulang dalam ${_resendCooldown}s'
                  : 'Kirim ulang kode',
              style: GoogleFonts.inter(
                color: _resendCooldown > 0
                    ? AppColors.textTertiary
                    : AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: New password ────────────────────────────────────────────

  Widget _newPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Buat\nsandi baru.', style: pageTitleStyle(size: 40)),
          const SizedBox(height: 14),
          Text(
            'Pilih kata sandi minimal 6 karakter. Setelah disimpan kamu '
            'langsung masuk ke akunmu.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Text('KATA SANDI BARU', style: eyebrowStyle()),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              hintText: 'Minimal 6 karakter',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
          ),
          const SizedBox(height: 20),
          Text('KONFIRMASI', style: eyebrowStyle()),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passConfirmCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Ketik ulang kata sandi',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Konfirmasi sandi';
              if (v != _passCtrl.text) return 'Sandi tidak sama';
              return null;
            },
          ),
          const SizedBox(height: 28),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (_, state) => EditorialButton(
              label: 'Simpan & masuk',
              icon: Icons.check_rounded,
              fullWidth: true,
              loading: state is AuthLoading,
              onPressed: _submitNewPassword,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three-dot progress indicator with growing pill on the active step.
class _StepIndicator extends StatelessWidget {
  final _Step step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final activeIndex = _Step.values.indexOf(step);
    return Row(
      children: List.generate(_Step.values.length, (i) {
        final isActive = i == activeIndex;
        final isPast = i < activeIndex;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: 4,
              decoration: BoxDecoration(
                color: isActive || isPast
                    ? AppColors.primary
                    : AppColors.surfaceStroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
