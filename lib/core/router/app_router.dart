import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/ai_chat/presentation/pages/chat_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/knowledge_map_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/gamification/presentation/pages/badges_page.dart';
import '../../features/gamification/presentation/pages/badges_stats_page.dart';
import '../../features/profile/presentation/pages/about_page.dart';
import '../../features/profile/presentation/pages/privacy_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/quiz/presentation/pages/weekly_quiz_page.dart';
import '../../features/vault/domain/entities/note_entity.dart';
import '../../features/vault/presentation/bloc/vault_bloc.dart';
import '../../features/vault/presentation/pages/add_note_page.dart';
import '../../features/vault/presentation/pages/note_detail_page.dart';
import '../../features/vault/presentation/pages/notes_stats_page.dart';
import '../../features/vault/presentation/pages/shared_note_page.dart';
import '../../features/vault/presentation/pages/tag_detail_page.dart';
import '../../features/vault/presentation/pages/tags_page.dart';
import '../../features/vault/presentation/pages/vault_page.dart';
import '../theme/app_colors.dart';
import 'route_names.dart';

/// Height the floating editorial nav bar reserves at the bottom of the
/// screen (dock + minimum safe-area handling, ~78px worst case + breathing).
///
/// Pages with bottom-anchored *interactive* UI (chat composer, FAB, action
/// sheet, etc.) should add this as a vertical inset so they don't render
/// behind the dock. Plain scrollable content does not need to use this —
/// it's allowed (and visually nicer) to flow behind the glass dock.
const double kEditorialNavBarOverlay = 80;

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
            loc == Routes.verifyOtp ||
            loc == Routes.forgotPassword;
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
        GoRoute(
          path: Routes.forgotPassword,
          builder: (_, __) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: Routes.onboarding,
          builder: (_, __) => const OnboardingPage(),
        ),
        GoRoute(
          path: Routes.privacy,
          builder: (_, __) => const PrivacyPage(),
        ),
        GoRoute(
          path: Routes.about,
          builder: (_, __) => const AboutPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => _RootShell(child: child),
          routes: [
            GoRoute(
                path: Routes.dashboard,
                builder: (_, __) => const DashboardPage()),
            GoRoute(path: Routes.vault, builder: (_, __) => const VaultPage()),
            GoRoute(path: Routes.chat, builder: (_, __) => const ChatPage()),
            GoRoute(
                path: Routes.badges, builder: (_, __) => const BadgesPage()),
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
              return const Scaffold(
                  body: Center(child: Text('Note not found')));
            }
            return AddNotePage(existingNote: note);
          },
        ),
        GoRoute(
          path: Routes.tags,
          builder: (_, __) => const TagsPage(),
        ),
        GoRoute(
          path: Routes.tagDetail,
          builder: (_, state) {
            final tag = state.extra as String? ?? '';
            return TagDetailPage(tag: tag);
          },
        ),
        GoRoute(
          path: Routes.knowledgeMap,
          builder: (_, __) => const KnowledgeMapPage(),
        ),
        GoRoute(
          path: Routes.notesStats,
          builder: (_, __) => const NotesStatsPage(),
        ),
        GoRoute(
          path: Routes.badgesStats,
          builder: (_, __) => const BadgesStatsPage(),
        ),
        GoRoute(
          path: Routes.weeklyQuiz,
          builder: (_, __) => const WeeklyQuizPage(),
        ),
        GoRoute(
          path: Routes.noteDetail,
          builder: (_, state) {
            // Two entry paths land here:
            //  1. In-app navigation — the caller passes the full NoteEntity
            //     as `extra` (instant render, no bloc lookup needed).
            //  2. External deep-link (homescreen widget tap, share sheet,
            //     etc.) — only the path id is available, so we look the
            //     entity up in VaultBloc state and wait for it to load.
            final note = state.extra as NoteEntity?;
            if (note != null) return NoteDetailPage(note: note);
            final id = state.pathParameters['id'] ?? '';
            return _NoteDetailByIdLoader(id: id);
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

/// Resolves a note by id from [VaultBloc] state and renders [NoteDetailPage]
/// once it's available. Used when the user opens a note via deep-link
/// (e.g. homescreen widget tap) where only the id is known.
class _NoteDetailByIdLoader extends StatelessWidget {
  final String id;
  const _NoteDetailByIdLoader({required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VaultBloc, VaultState>(
      builder: (ctx, state) {
        if (state is VaultLoaded) {
          NoteEntity? match;
          for (final n in state.notes) {
            if (n.id == id) {
              match = n;
              break;
            }
          }
          if (match != null) return NoteDetailPage(note: match);
          return const _NoteMissingScaffold(
              message: 'Catatan tidak ditemukan.');
        }
        if (state is VaultError) {
          return _NoteMissingScaffold(message: state.message);
        }
        // VaultInitial / VaultLoading — spinner while the vault loads.
        return const Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}

class _NoteMissingScaffold extends StatelessWidget {
  final String message;
  const _NoteMissingScaffold({required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
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
  static const _tabs = <_TabSpec>[
    _TabSpec(
      route: Routes.dashboard,
      label: 'Beranda',
      iconActive: Icons.home_rounded,
      iconInactive: Icons.home_outlined,
    ),
    _TabSpec(
      route: Routes.vault,
      label: 'Brankas',
      iconActive: Icons.description_rounded,
      iconInactive: Icons.description_outlined,
    ),
    _TabSpec(
      route: Routes.chat,
      label: 'Asisten',
      iconActive: Icons.chat_bubble_rounded,
      iconInactive: Icons.chat_bubble_outline_rounded,
    ),
    _TabSpec(
      route: Routes.badges,
      label: 'Lencana',
      iconActive: Icons.workspace_premium_rounded,
      iconInactive: Icons.workspace_premium_outlined,
    ),
    _TabSpec(
      route: Routes.profile,
      label: 'Saya',
      iconActive: Icons.person_rounded,
      iconInactive: Icons.person_outline_rounded,
    ),
  ];

  int _indexFor(String location) {
    final i = _tabs.indexWhere((t) => location.startsWith(t.route));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final current = _indexFor(location);
    // Navbar is rendered as a Stack overlay (not in `bottomNavigationBar`)
    // so the body fills the full screen and page content extends behind
    // the floating dock — keeping the area around the pill transparent.
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Align(
                  alignment: Alignment.center,
                  heightFactor: 1,
                  child: _EditorialNavBar(
                    tabs: _tabs,
                    currentIndex: current,
                    onSelect: (i) => context.go(_tabs[i].route),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spec for a single tab in [_EditorialNavBar].
class _TabSpec {
  final String route;
  final String label;
  final IconData iconActive;
  final IconData iconInactive;
  const _TabSpec({
    required this.route,
    required this.label,
    required this.iconActive,
    required this.iconInactive,
  });
}

/// Compact icon-only dock that hugs its content (centered, not full-width).
/// The active tab fills with a solid indigo pill; inactive tabs are icon-only
/// on a transparent slot. Selection transitions are a soft fade + scale on
/// the icon and a color cross-fade on the pill.
class _EditorialNavBar extends StatelessWidget {
  final List<_TabSpec> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _EditorialNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 26.0;
    // Outer shadow lives outside the clip so blur can render edge-to-edge
    // inside the rounded shape without the shadow getting cropped.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              // Semi-transparent slate tint + subtle gradient gives the
              // surface a vibrancy-style depth (lighter top, darker bottom)
              // similar to Apple's frosted glass.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bgSecondary.withValues(alpha: 0.55),
                  AppColors.bgSecondary.withValues(alpha: 0.40),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(tabs.length, (i) {
                return _NavItem(
                  tab: tabs[i],
                  selected: i == currentIndex,
                  onTap: () => onSelect(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabSpec tab;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: 52,
      height: 48,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: Colors.white.withValues(alpha: 0.10),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Tooltip(
            message: tab.label,
            child: Semantics(
              label: tab.label,
              selected: selected,
              button: true,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Icon(
                    selected ? tab.iconActive : tab.iconInactive,
                    key: ValueKey('${tab.route}-$selected'),
                    size: 22,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
