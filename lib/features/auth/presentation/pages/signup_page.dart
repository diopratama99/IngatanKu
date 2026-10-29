import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
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

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (!canGoOnline(context, OnlineFeature.signUp)) return;
    context.read<AuthBloc>().add(
          AuthSignUpRequested(
            _email.text.trim(),
            _password.text,
            _username.text.trim(),
          ),
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
        }
        if (state is AuthAwaitingOtp) {
          context.push(Routes.verifyOtp, extra: state.email);
        }
        if (state is AuthNewAccount) {
          // Made just now with Google: the welcome story first.
          context.go(Routes.onboarding);
        } else if (state is Authenticated) {
          context.go(Routes.dashboard);
        }
      },
      child: Scaffold(
        appBar: PageTopBar(
          title: l10n.signupAppBarTitle,
          onBack: () => context.pop(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A fresh egg greets new users.
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: PetHost(height: 100),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.signupTitle,
                      style: pageTitleStyle(context: context, size: 44)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.signupSubtitle,
                    style: AppFonts.body(
                      fontSize: 14,
                      color: context.palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  Text(l10n.signupUsernameLabel,
                      style: eyebrowStyle(context: context)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _username,
                    decoration: InputDecoration(
                      hintText: l10n.signupUsernameHint,
                    ),
                    validator: (v) => (v == null || v.length < 3)
                        ? l10n.signupUsernameTooShort
                        : null,
                  ),
                  const SizedBox(height: 24),

                  Text(l10n.signupEmailLabel,
                      style: eyebrowStyle(context: context)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: l10n.signupEmailHint,
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? l10n.signupEmailInvalid
                        : null,
                  ),
                  const SizedBox(height: 24),

                  Text(l10n.signupPasswordLabel,
                      style: eyebrowStyle(context: context)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: l10n.signupPasswordHint,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? l10n.signupPasswordTooShort
                        : null,
                  ),
                  const SizedBox(height: 32),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (_, state) => EditorialButton(
                      label: l10n.signupSubmit,
                      icon: Icons.arrow_forward_rounded,
                      fullWidth: true,
                      // Google's own button spins for Google.
                      loading:
                          state is AuthLoading && state is! AuthGoogleLoading,
                      onPressed: state is AuthGoogleLoading ? null : _submit,
                    ),
                  ),
                  if (Env.googleWebClientId.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const AuthOrDivider(),
                    const SizedBox(height: 18),
                    const GoogleSignInButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
