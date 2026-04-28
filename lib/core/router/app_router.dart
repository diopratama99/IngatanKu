import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_chat/presentation/pages/chat_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/gamification/presentation/pages/badges_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/vault/domain/entities/note_entity.dart';
import '../../features/vault/presentation/pages/add_note_page.dart';
import '../../features/vault/presentation/pages/note_detail_page.dart';
import '../../features/vault/presentation/pages/shared_note_page.dart';
import '../../features/vault/presentation/pages/tags_page.dart';
import '../../features/vault/presentation/pages/vault_page.dart';
import '../theme/app_colors.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter build(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: Routes.dashboard,
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final loggedIn = authBloc.state is Authenticated;
        final loc = state.uri.path;
        // Root → punt to dashboard; the rest of the redirect logic kicks in next pass.
        if (loc == '/' || loc.isEmpty) {
          return loggedIn ? Routes.dashboard : Routes.login;
        }
        final atAuth = loc == Routes.login ||
            loc == Routes.signup ||
            loc == Routes.verifyOtp;
        // Public share routes are accessible without auth
        final isPublic = loc.startsWith('/share/');
        if (isPublic) return null;
        if (!loggedIn && !atAuth) return Routes.login;
        if (loggedIn && atAuth) return Routes.dashboard;
        return null;
      },
      errorBuilder: (ctx, state) => Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No route: ${state.uri}'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => GoRouter.of(ctx).go(Routes.dashboard),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
      routes: [
        // Catch the launch path '/' explicitly so Android intent redirects work.
        GoRoute(
          path: '/',
          redirect: (_, __) =>
              authBloc.state is Authenticated ? Routes.dashboard : Routes.login,
        ),
        GoRoute(path: Routes.login, builder: (_, __) => const LoginPage()),
        GoRoute(path: Routes.signup, builder: (_, __) => const SignupPage()),
        GoRoute(
          path: Routes.verifyOtp,
          builder: (_, state) {
            final email = (state.extra as String?) ?? '';
            return VerifyOtpPage(email: email);
          },
        ),
        ShellRoute(
          builder: (context, state, child) => _RootShell(child: child),
          routes: [
            GoRoute(
                path: Routes.dashboard,
                builder: (_, __) => const DashboardPage()),
            GoRoute(path: Routes.vault, builder: (_, __) => const VaultPage()),
            GoRoute(path: Routes.chat, builder: (_, __) => const ChatPage()),
            GoRoute(path: Routes.badges, builder: (_, __) => const BadgesPage()),
            GoRoute(
                path: Routes.profile, builder: (_, __) => const ProfilePage()),
          ],
        ),
        GoRoute(
          path: Routes.addNote,
          builder: (_, state) {
            // `extra` is set when navigating from the share-intent handler.
            final initialUrl = state.extra as String?;
            return AddNotePage(initialUrl: initialUrl);
          },
        ),
        GoRoute(
          path: Routes.editNote,
          builder: (_, state) {
            final note = state.extra as NoteEntity?;
            if (note == null) {
              return const Scaffold(body: Center(child: Text('Note not found')));
            }
            return AddNotePage(existingNote: note);
          },
        ),
        GoRoute(
          path: Routes.tags,
          builder: (_, __) => const TagsPage(),
        ),
        GoRoute(
          path: Routes.noteDetail,
          builder: (_, state) {
            final note = state.extra as NoteEntity?;
            if (note == null) {
              return const Scaffold(body: Center(child: Text('Note not found')));
            }
            return NoteDetailPage(note: note);
          },
        ),
        GoRoute(
          path: Routes.shared,
          builder: (_, state) {
            final token = state.pathParameters['token'] ?? '';
            return SharedNotePage(token: token);
          },
        ),
      ],
    );
  }
}

/// Bridges a Bloc/Cubit Stream to GoRouter's refreshListenable.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class _RootShell extends StatefulWidget {
  final Widget child;
  const _RootShell({required this.child});

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  static const _tabs = [
    (route: Routes.dashboard, icon: Icons.dashboard_rounded, label: 'Beranda'),
    (route: Routes.vault, icon: Icons.layers_rounded, label: 'Brankas'),
    (route: Routes.chat, icon: Icons.psychology_alt_outlined, label: 'Otak'),
    (route: Routes.badges, icon: Icons.emoji_events_outlined, label: 'Lencana'),
    (route: Routes.profile, icon: Icons.person_outline, label: 'Saya'),
  ];

  int _indexFor(String location) {
    final i = _tabs.indexWhere((t) => location.startsWith(t.route));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final current = _indexFor(location);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgPrimary.withOpacity(0.9),
          border: Border(top: BorderSide(color: AppColors.glassStroke)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final selected = i == current;
                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(t.route),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(t.icon,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                              size: 22),
                          const SizedBox(height: 4),
                          Text(t.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
