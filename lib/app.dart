import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection_container.dart';
import 'core/network/supabase_client.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/share_intent_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/ai_chat/data/chat_session_store.dart';
import 'features/ai_chat/domain/repositories/chat_repository.dart';
import 'features/ai_chat/presentation/bloc/chat_bloc.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'features/notes/domain/repositories/personal_note_repository.dart';
import 'features/notes/presentation/bloc/personal_notes_bloc.dart';
import 'features/vault/domain/repositories/vault_repository.dart';
import 'features/vault/domain/usecases/add_note.dart';
import 'features/vault/domain/usecases/delete_note.dart';
import 'features/vault/domain/usecases/get_notes.dart';
import 'features/vault/domain/usecases/update_note.dart';
import 'features/vault/presentation/bloc/vault_bloc.dart';

class IngatanKuApp extends StatefulWidget {
  const IngatanKuApp({super.key});

  @override
  State<IngatanKuApp> createState() => _IngatanKuAppState();
}

class _IngatanKuAppState extends State<IngatanKuApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;
  StreamSubscription<String>? _shareSub;
  StreamSubscription<Uri?>? _widgetTapSub;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(
      signIn: sl<SignIn>(),
      signUp: sl<SignUp>(),
      signOut: sl<SignOut>(),
      repo: sl<AuthRepository>(),
    )..add(AuthStarted());
    _router = AppRouter.build(_authBloc);

    // Cold-start: if a URL was shared while the app wasn't running, hand
    // it to Beranda once the auth state is known.
    final pending = ShareIntentService.instance.consumePending();
    if (pending != null) {
      _waitForAuthThenPush(pending);
    }
    // Warm: every subsequent share while the app is open.
    _shareSub =
        ShareIntentService.instance.sharedUrlStream.listen(_handleSharedUrl);

    // Cold-start: if the user launched the app by tapping the homescreen
    // widget, route to the matching page after auth resolves.
    HomeWidgetService.instance.consumeColdStartUri().then((uri) {
      if (uri != null) _waitForAuthThenHandleWidgetUri(uri);
    });
    // Warm: every subsequent widget tap while the app is open.
    _widgetTapSub = HomeWidgetService.instance.tapStream.listen((uri) {
      if (uri != null) _handleWidgetUri(uri);
    });
  }

  void _handleSharedUrl(String url) {
    debugPrint(
        '[App] _handleSharedUrl: $url (authState=${_authBloc.state.runtimeType})');
    if (_authBloc.state is Authenticated) {
      _sendToHome(url);
    } else {
      _waitForAuthThenPush(url);
    }
  }

  /// Defer navigation until the user signs in (covers cold-start where
  /// AuthBloc hasn't resolved a session yet).
  void _waitForAuthThenPush(String url) {
    debugPrint('[App] waiting for auth before pushing $url');
    late final StreamSubscription sub;
    sub = _authBloc.stream.listen((s) {
      debugPrint('[App] auth state changed: ${s.runtimeType}');
      if (s is Authenticated) {
        sub.cancel();
        _sendToHome(url);
      }
    });
    // If we're already authenticated by the time this runs, fire immediately.
    if (_authBloc.state is Authenticated) {
      sub.cancel();
      _sendToHome(url);
    }
  }

  /// Shared links go into Beranda's "paste a link" bar, where the pet
  /// writes the note up once you tap the check. Deferred to the next frame
  /// so the router is fully attached (otherwise navigating during the
  /// first build can no-op).
  void _sendToHome(String url) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[App] handing $url to Beranda');
      ShareIntentService.instance.forHome.value = url;
      _router.go(Routes.dashboard);
    });
  }

  // ──────────────────────────────────────────────────────────────
  //  Homescreen widget deep-link handling
  // ──────────────────────────────────────────────────────────────

  /// Decodes a widget URI and pushes the matching route. The URI scheme is
  /// `ingatanku://` and the host distinguishes the kind of intent:
  ///   * `ingatanku://note?id=<noteId>`  → open the note detail page
  ///   * `ingatanku://capture`           → open the add-note page
  void _handleWidgetUri(Uri uri) {
    debugPrint('[App] _handleWidgetUri: $uri');
    if (uri.scheme != 'ingatanku') return;
    switch (uri.host) {
      // The widget's "Feed it": today's quiz.
      case 'quiz':
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _router.go(Routes.dashboard);
          _router.push(Routes.dailyQuiz);
        });
      // The pet itself, or "Save a link": Beranda, with its link bar.
      case 'home':
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _router.go(Routes.dashboard);
        });
    }
  }

  /// Same as [_handleWidgetUri] but waits for the user to be authenticated
  /// first — used on cold-start where the app might not have resolved the
  /// session yet.
  void _waitForAuthThenHandleWidgetUri(Uri uri) {
    if (_authBloc.state is Authenticated) {
      _handleWidgetUri(uri);
      return;
    }
    late final StreamSubscription sub;
    sub = _authBloc.stream.listen((s) {
      if (s is Authenticated) {
        sub.cancel();
        _handleWidgetUri(uri);
      }
    });
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    _widgetTapSub?.cancel();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider(
          create: (_) => VaultBloc(
            repo: sl<VaultRepository>(),
            getNotes: sl<GetNotes>(),
            addNote: sl<AddNote>(),
            deleteNote: sl<DeleteNote>(),
            updateNote: sl<UpdateNote>(),
          )..add(const VaultLoadRequested()),
        ),
        BlocProvider(
          create: (_) => ChatBloc(
            repo: sl<ChatRepository>(),
            store: sl<ChatSessionStore>(),
            user: sl<SupabaseService>().currentUserId,
            users: sl<SupabaseService>()
                .auth
                .onAuthStateChange
                .map((e) => e.session?.user.id),
          ),
        ),
        BlocProvider(
          create: (_) => DashboardCubit(
            sl<DashboardRepository>(),
            sl<NotificationService>(),
            changes: sl<VaultRepository>().changes,
          ),
        ),
        BlocProvider(
          create: (_) => PersonalNotesBloc(repo: sl<PersonalNoteRepository>())
            ..add(const PersonalNotesLoadRequested()),
        ),
      ],
      child: AnimatedBuilder(
        // AppSettingsService is a ChangeNotifier; rebuild MaterialApp
        // whenever the user flips locale or theme so the change
        // takes effect without an app restart.
        animation: AppSettingsService.instance,
        builder: (_, __) {
          final settings = AppSettingsService.instance;
          return MaterialApp.router(
            title: 'IngatanKu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: settings.storedLocale,
            supportedLocales: AppSettingsService.supportedLocales,
            // Required by Flutter when supportedLocales is set —
            // provides translated strings for built-in widgets
            // (Cancel/OK in dialogs, datepicker labels, etc).
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Dark status-bar icons on the light pages by default;
            // a page that needs otherwise sets its own
            // `AnnotatedRegion<SystemUiOverlayStyle>`.
            builder: (ctx, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.dark,
              child: child ?? const SizedBox.shrink(),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
