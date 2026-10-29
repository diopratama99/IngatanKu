import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../companion/presentation/widgets/pet_offline.dart';
import '../bloc/auth_bloc.dart';

/// "Continue with Google", on Login and Sign up: signs in, or makes the
/// account the first time. Hidden while the app has no Google client to
/// sign in with ([Env.googleWebClientId]).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (Env.googleWebClientId.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => EditorialButton(
        label: l10n.authContinueGoogle,
        leading: Image.asset('assets/auth/google_g.png', width: 18, height: 18),
        primary: false,
        fullWidth: true,
        loading: state is AuthGoogleLoading,
        onPressed: state is AuthLoading
            ? null
            : () {
                if (!canGoOnline(context, OnlineFeature.signIn)) return;
                context.read<AuthBloc>().add(AuthGoogleSignInRequested());
              },
      ),
    );
  }
}

/// A hairline with "OR" in the middle, between ways in.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final line = Expanded(
      child: Container(height: 1, color: palette.surfaceStroke),
    );
    return Row(
      children: [
        line,
        const SizedBox(width: 12),
        Text(
          AppLocalizations.of(context)!.loginDivider,
          style: AppFonts.body(
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
            color: palette.textTertiary,
          ),
        ),
        const SizedBox(width: 12),
        line,
      ],
    );
  }
}
