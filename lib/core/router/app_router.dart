import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_chat/presentation/pages/chat_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/notes/domain/entities/personal_note.dart';
import '../../features/notes/presentation/pages/personal_note_editor_page.dart';
import '../../features/notes/presentation/pages/personal_notes_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/about_page.dart';
import '../../features/profile/presentation/pages/account_settings_page.dart';
import '../../features/profile/presentation/pages/privacy_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/reindex_page.dart';
import '../../features/profile/presentation/pages/storage_page.dart';
import '../../features/quiz/domain/entities/weekly_quiz.dart';
import '../../features/quiz/presentation/pages/quiz_page.dart';
import '../../features/vault/domain/entities/note_entity.dart';
import '../../features/vault/presentation/bloc/vault_bloc.dart';
import '../../features/vault/presentation/pages/add_note_page.dart';
import '../../features/vault/presentation/pages/note_detail_page.dart';
import '../../features/vault/presentation/pages/tag_detail_page.dart';
import '../../features/vault/presentation/pages/tags_page.dart';
import '../../features/vault/presentation/pages/vault_page.dart';
import '../../features/companion/presentation/pages/pet_shop_page.dart';
import '../../l10n/generated/app_localizations.dart';
import '../services/sound_service.dart';
import '../theme/app_palette.dart';
import 'route_names.dart';

import '../theme/app_fonts.dart';

/// Height the floating pill nav bar reserves at the bottom of the
/// screen (bar + margins, excluding the device's safe-area inset).
///
/// Pages with bottom-anchored *interactive* UI (chat composer, FAB, action
/// sheet, etc.) should add this as a vertical inset so they don't render
/// behind the bar. Plain scrollable content may flow behind it.
const double kEditorialNavBarOverlay = 84;

class AppRouter {
  static GoRouter build(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: Routes.dashboard,
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        // We only react to two terminal auth states. Transient ones
        // (`AuthLoading`, `AuthProfileUpdateSuccess`, OTP states, …)
        // must NOT cause a redirect — otherwise updating the password
        // or display name from /profile/account briefly flips the user
        // through /login and lands them on /dashboard instead of
        // staying put.
        final authState = authBloc.state;
        final loggedIn = authState is Authenticated;
        final loggedOut = authState is Unauthenticated;
        final loc = state.uri.path;
        // Root → punt to dashboard; the rest of the redirect logic kicks in next pass.
        if (loc == '/' || loc.isEmpty) {
          return loggedIn ? Routes.dashboard : Routes.login;
        }
        final atAuth = loc == Routes.login ||
            loc == Routes.signup ||
            loc == Routes.verifyOtp ||
            loc == Routes.forgotPassword;
        if (loggedOut && !atAuth) return Routes.login;
        // A new account (from Google) hears the welcome story first.
        if (loggedIn && atAuth) {
          return authState is AuthNewAccount
              ? Routes.onboarding
              : Routes.dashboard;
        }
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
          path: Routes.accountSettings,
          builder: (_, __) => const AccountSettingsPage(),
        ),
        GoRoute(
          path: Routes.about,
          builder: (_, __) => const AboutPage(),
        ),
        GoRoute(
          path: Routes.storage,
          builder: (_, __) => const StoragePage(),
        ),
        GoRoute(
          path: Routes.reindex,
          builder: (_, __) => const ReindexPage(),
        ),
        // The five tabs keep their pages once visited (each room, its pet,
        // the TV, scroll positions…) instead of building them again on
        // every switch; a tab out of sight is paused (TickerMode), so its
        // animations, TV and room sound stop until it's back.
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _RootShell(child: shell),
          // Each room has its own music and background sound.
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.dashboard,
                  builder: (_, __) => const SceneSound(
                      scene: SoundScene.home, child: DashboardPage())),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.vault,
                  builder: (_, __) => const SceneSound(
                      scene: SoundScene.library, child: VaultPage())),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.notes,
                  builder: (_, __) => const SceneSound(
                      scene: SoundScene.notes, child: PersonalNotesPage())),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.chat,
                  builder: (_, __) => const SceneSound(
                      scene: SoundScene.assistant, child: ChatPage())),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.profile,
                  builder: (_, __) => const ProfilePage()),
            ]),
          ],
        ),
        GoRoute(
          path: Routes.notesNew,
          builder: (_, __) => const PersonalNoteEditorPage(),
        ),
        GoRoute(
          path: Routes.notesEdit,
          builder: (_, state) {
            final note = state.extra as PersonalNote?;
            if (note == null) {
              return const Scaffold(
                body: Center(child: Text('Catatan tidak ditemukan')),
              );
            }
            return PersonalNoteEditorPage(existing: note);
          },
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
          path: Routes.weeklyQuiz,
          builder: (_, __) => const QuizPage(kind: QuizKind.weekly),
        ),
        GoRoute(
          path: Routes.dailyQuiz,
          builder: (_, __) => const QuizPage(kind: QuizKind.daily),
        ),
        GoRoute(
          path: Routes.shop,
          builder: (_, __) => const PetShopPage(),
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
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.palette.primary,
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
      appBar: AppBar(
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.body(
              fontSize: 14,
              color: context.palette.textSecondary,
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
  /// Tabs are built lazily in [build] so each label can be looked up
  /// from [AppLocalizations] for the current locale.
  static const _tabRoutes = <_TabIcon>[
    _TabIcon(
      route: Routes.dashboard,
      iconActive: Icons.home_rounded,
      iconInactive: Icons.home_outlined,
    ),
    _TabIcon(
      route: Routes.vault,
      iconActive: Icons.bookmark_rounded,
      iconInactive: Icons.bookmark_border_rounded,
    ),
    _TabIcon(
      route: Routes.notes,
      iconActive: Icons.sticky_note_2_rounded,
      iconInactive: Icons.sticky_note_2_outlined,
    ),
    _TabIcon(
      route: Routes.chat,
      iconActive: Icons.chat_bubble_rounded,
      iconInactive: Icons.chat_bubble_outline_rounded,
    ),
    _TabIcon(
      route: Routes.profile,
      iconActive: Icons.person_rounded,
      iconInactive: Icons.person_outline_rounded,
    ),
  ];

  int _indexFor(String location) {
    final i = _tabRoutes.indexWhere((t) => location.startsWith(t.route));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabLabels = [
      l10n.navHome,
      l10n.navLibrary,
      l10n.navNotes,
      l10n.navAssistant,
      l10n.navProfile,
    ];
    final tabs = [
      for (var i = 0; i < _tabRoutes.length; i++)
        _TabSpec(
          route: _tabRoutes[i].route,
          label: tabLabels[i],
          iconActive: _tabRoutes[i].iconActive,
          iconInactive: _tabRoutes[i].iconInactive,
        ),
    ];
    final location = GoRouterState.of(context).uri.toString();
    final current = _indexFor(location);
    // While typing the bar steps aside so the keyboard has the room.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    // Navbar is rendered as a Stack overlay (not in `bottomNavigationBar`)
    // so the body fills the full screen and page content extends behind
    // the floating bar. The shell doesn't resize for the keyboard — each
    // tab's own Scaffold does, and needs to see the inset to do so.
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),
          if (!keyboard)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Align(
                    heightFactor: 1,
                    child: _PillNavBar(
                      tabs: tabs,
                      currentIndex: current,
                      onSelect: (i) {
                        if (i != current) {
                          HapticFeedback.selectionClick();
                          SoundService.instance.play(Sfx.tabTick);
                        }
                        context.go(tabs[i].route);
                      },
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

/// Static metadata for a tab — locale-independent so it can stay
/// `const`. The display label is appended in [_RootShellState.build].
class _TabIcon {
  final String route;
  final IconData iconActive;
  final IconData iconInactive;
  const _TabIcon({
    required this.route,
    required this.iconActive,
    required this.iconInactive,
  });
}

/// Spec for a single tab in [_PillNavBar].
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

/// Floating white pill. Inactive tabs are quiet icon circles; the
/// active one opens into a capsule with a tinted icon and its label.
class _PillNavBar extends StatelessWidget {
  final List<_TabSpec> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _PillNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: palette.surfaceStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // Scale down on very narrow phones / long translations rather
      // than overflow.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _NavItem(
                tab: tabs[i],
                selected: i == currentIndex,
                onTap: () => onSelect(i),
              ),
            ],
          ],
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
    final palette = context.palette;
    // The active tab in warm cream and brown, like the furniture on
    // Beranda.
    const capsule = Color(0xFFF1E8D8);
    const disc = Color(0xFFDCC7A4);
    const accentFg = Color(0xFF5B4630);
    return Semantics(
      label: tab.label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 52,
          padding: EdgeInsets.fromLTRB(4, 4, selected ? 18 : 4, 4),
          decoration: BoxDecoration(
            color: selected ? capsule : palette.bgPrimary,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? disc : Colors.transparent,
                ),
                child: Icon(
                  selected ? tab.iconActive : tab.iconInactive,
                  size: 22,
                  color: selected ? accentFg : palette.textSecondary,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          style: AppFonts.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
