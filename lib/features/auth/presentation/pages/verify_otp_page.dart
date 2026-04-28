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

class VerifyOtpPage extends StatefulWidget {
  final String email;
  const VerifyOtpPage({super.key, required this.email});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _resendTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    // Autofocus on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _secondsLeft = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _verify(String code) {
    if (code.length != 6) return;
    context.read<AuthBloc>().add(
          AuthOtpVerificationRequested(email: widget.email, token: code),
        );
  }

  void _resend() {
    if (_secondsLeft > 0) return;
    context.read<AuthBloc>().add(AuthOtpResendRequested(widget.email));
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
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

    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthError) {
          context.showSnack(state.message, error: true);
          _ctrl.clear();
          _focus.requestFocus();
        } else if (state is Authenticated) {
          // Fresh sign-up: ride through the welcome/onboarding slides
          // before landing on the dashboard. Returning users sign in via
          // LoginPage which routes them straight to /dashboard.
          context.go(Routes.onboarding);
        } else if (state is AuthOtpResent) {
          context.showSnack('Kode baru sudah dikirim ke email-mu');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: BackButton(onPressed: () => context.pop()),
          title: Text('VERIFIKASI', style: eyebrowStyle()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Cek\nemailmu.', style: pageTitleStyle(size: 44)),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Kami mengirim 6 digit kode ke\n'),
                      TextSpan(
                        text: widget.email,
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
                const SizedBox(height: 40),
                Text('KODE OTP', style: eyebrowStyle()),
                const SizedBox(height: 10),
                Pinput(
                  length: 6,
                  controller: _ctrl,
                  focusNode: _focus,
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
                  onCompleted: _verify,
                  keyboardType: TextInputType.number,
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                ),
                const SizedBox(height: 32),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (_, state) => EditorialButton(
                    label: 'Verifikasi',
                    icon: Icons.arrow_forward_rounded,
                    fullWidth: true,
                    loading: state is AuthLoading,
                    onPressed: () => _verify(_ctrl.text),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _secondsLeft > 0 ? null : _resend,
                    child: Text(
                      _secondsLeft > 0
                          ? 'Kirim ulang dalam ${_secondsLeft}s'
                          : 'Kirim ulang kode',
                      style: GoogleFonts.inter(
                        color: _secondsLeft > 0
                            ? AppColors.textTertiary
                            : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
