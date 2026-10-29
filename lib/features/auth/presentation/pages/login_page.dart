import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/google_sign_in_button.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../companion/presentation/widgets/pet_host.dart';
import '../../../companion/presentation/widgets/pet_offline.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (!canGoOnline(context, OnlineFeature.signIn)) return;
    context.read<AuthBloc>().add(
          AuthSignInRequested(_email.text.trim(), _password.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          context.showSnack(
              state.message == kGoogleSignInFailed
                  ? l10n.authGoogleFailed
                  : state.message,
              error: true);
        } else if (state is AuthNewAccount) {
          // Made just now with Google: the welcome story first.
          context.go(Routes.onboarding);
        } else if (state is Authenticated) {
          context.go(Routes.dashboard);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.loginEyebrow,
                      style: eyebrowStyle(context: context)),
                  const SizedBox(height: 20),
                  // Your pet is waiting on the other side of this form.
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: PetHost(height: 110),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.loginTitle,
                    style: pageTitleStyle(context: context, size: 44),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.loginSubtitle,
                    style: AppFonts.body(
                      fontSize: 14,
                      color: context.palette.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Email field ────────────────────────────────
                  Text(l10n.loginEmailLabel, style: eyebrowStyle(context: context)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      hintText: l10n.loginEmailHint,
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? l10n.loginEmailInvalid
                        : null,
                  ),
                  const SizedBox(height: 22),

                  // ── Password field with inline LUPA? link ─────
                  Row(
                    children: [
                      Text(l10n.loginPasswordLabel, style: eyebrowStyle(context: context)),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.push(Routes.forgotPassword),
                        child: Text(
                          l10n.loginPasswordForgot,
                          style: AppFonts.body(
                            fontSize: 11,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                            color: context.palette.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      hintText: l10n.loginPasswordHint,
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
                    validator: (v) => (v == null || v.length < 6)
                        ? l10n.loginPasswordTooShort
                        : null,
                  ),
                  const SizedBox(height: 32),

                  // ── Submit ────────────────────────────────────
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (_, state) => EditorialButton(
                      label: l10n.loginSubmit,
                      icon: Icons.arrow_forward_rounded,
                      fullWidth: true,
                      // Google's own button spins for Google.
                      loading:
                          state is AuthLoading && state is! AuthGoogleLoading,
                      onPressed: state is AuthGoogleLoading ? null : _submit,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Divider, Google, Sign-up link ─────────────
                  const AuthOrDivider(),
                  const SizedBox(height: 18),
                  const GoogleSignInButton(),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push(Routes.signup),
                      child: RichText(
                        text: TextSpan(
                          style: AppFonts.body(
                            fontSize: 14,
                            color: context.palette.textSecondary,
                          ),
                          children: [
                            TextSpan(text: l10n.loginNoAccount),
                            TextSpan(
                              text: l10n.loginSignUpAction,
                              style: AppFonts.body(
                                color: context.palette.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
