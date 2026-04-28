import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/services/notification_service.dart';
import 'core/services/share_intent_service.dart';
import 'core/theme/app_theme.dart';
import 'features/ai_chat/domain/repositories/chat_repository.dart';
import 'features/ai_chat/presentation/bloc/chat_bloc.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'features/gamification/domain/repositories/badge_repository.dart';
import 'features/gamification/presentation/bloc/badges_cubit.dart';
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

    // Cold-start: if a URL was shared while the app wasn't running,
    // navigate to the add-note page once the auth state is known.
    final pending = ShareIntentService.instance.consumePending();
    if (pending != null) {
      _waitForAuthThenPush(pending);
    }
    // Warm: every subsequent share while the app is open.
    _shareSub = ShareIntentService.instance.sharedUrlStream.listen(_handleSharedUrl);
  }

  void _handleSharedUrl(String url) {
    debugPrint('[App] _handleSharedUrl: $url (authState=${_authBloc.state.runtimeType})');
    if (_authBloc.state is Authenticated) {
      _pushAddNote(url);
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
        _pushAddNote(url);
      }
    });
    // If we're already authenticated by the time this runs, fire immediately.
    if (_authBloc.state is Authenticated) {
      sub.cancel();
      _pushAddNote(url);
    }
  }

  /// Defer to the next frame so the Navigator is fully attached (otherwise
  /// pushes during first build can no-op).
  void _pushAddNote(String url) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[App] pushing /vault/new with url=$url');
      _router.push(Routes.addNote, extra: url);
    });
  }

  @override
  void dispose() {
    _shareSub?.cancel();
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
            getNotes: sl<GetNotes>(),
            addNote: sl<AddNote>(),
            deleteNote: sl<DeleteNote>(),
            updateNote: sl<UpdateNote>(),
          ),
        ),
        BlocProvider(
          create: (_) => ChatBloc(
            repo: sl<ChatRepository>(),
            sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
          ),
        ),
        BlocProvider(
          create: (_) =>
              DashboardCubit(sl<DashboardRepository>(), sl<NotificationService>()),
        ),
        BlocProvider(create: (_) => BadgesCubit(sl<BadgeRepository>())),
      ],
      child: MaterialApp.router(
        title: 'IngatanKu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }
}
