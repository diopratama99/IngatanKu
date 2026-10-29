import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/error/failures.dart';
import 'package:ingatanku/features/auth/domain/entities/user_entity.dart';
import 'package:ingatanku/features/auth/domain/repositories/auth_repository.dart';
import 'package:ingatanku/features/auth/domain/usecases/sign_in.dart';
import 'package:ingatanku/features/auth/domain/usecases/sign_out.dart';
import 'package:ingatanku/features/auth/domain/usecases/sign_up.dart';
import 'package:ingatanku/features/auth/presentation/bloc/auth_bloc.dart';

/// Google sign-in answers when the test says so.
class _Repo implements AuthRepository {
  final google = Completer<Either<Failure, GoogleSignInOutcome?>>();

  @override
  Future<Either<Failure, GoogleSignInOutcome?>> signInWithGoogle() =>
      google.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _ana = UserEntity(id: 'u1', email: 'ana@gmail.com', hasPassword: false);

void main() {
  late _Repo repo;
  late AuthBloc bloc;
  late List<AuthState> states;

  setUp(() {
    repo = _Repo();
    bloc = AuthBloc(
      signIn: SignIn(repo),
      signUp: SignUp(repo),
      signOut: SignOut(repo),
      repo: repo,
    );
    states = [];
    bloc.stream.listen(states.add);
  });
  tearDown(() => bloc.close());

  test('a new Google account is sent to the welcome story', () async {
    bloc.add(AuthGoogleSignInRequested());
    await pumpEventQueue();
    // Supabase reports the session before we know the account is new:
    // that mustn't count as an ordinary sign-in (Beranda, no story).
    bloc.add(const AuthUserChanged(_ana));
    await pumpEventQueue();
    repo.google
        .complete(const Right(GoogleSignInOutcome(user: _ana, isNew: true)));
    await pumpEventQueue();
    expect(states.map((s) => s.runtimeType),
        [AuthGoogleLoading, AuthNewAccount]);
  });

  test('Supabase reporting the new account again keeps it new', () async {
    bloc.add(AuthGoogleSignInRequested());
    repo.google
        .complete(const Right(GoogleSignInOutcome(user: _ana, isNew: true)));
    await pumpEventQueue();
    // Arrives after: it mustn't turn into an ordinary sign-in on the way
    // to the welcome story.
    bloc.add(const AuthUserChanged(_ana));
    await pumpEventQueue();
    expect(bloc.state, isA<AuthNewAccount>());
    // Someone else is someone else.
    bloc.add(const AuthUserChanged(UserEntity(id: 'u2', email: 'b@x.id')));
    await pumpEventQueue();
    expect(bloc.state, isNot(isA<AuthNewAccount>()));
  });

  test('a returning Google account is just signed in', () async {
    bloc.add(AuthGoogleSignInRequested());
    repo.google
        .complete(const Right(GoogleSignInOutcome(user: _ana, isNew: false)));
    await pumpEventQueue();
    expect(states.last, const Authenticated(_ana));
    expect(states.last, isNot(isA<AuthNewAccount>()));
  });

  test('closing the account picker goes back, with no error', () async {
    bloc.add(AuthGoogleSignInRequested());
    repo.google.complete(const Right(null));
    await pumpEventQueue();
    expect(states.map((s) => s.runtimeType),
        [AuthGoogleLoading, Unauthenticated]);
  });

  test('a failed Google sign-in says so in the app language', () async {
    bloc.add(AuthGoogleSignInRequested());
    repo.google.complete(const Left(AuthFailure(kGoogleSignInFailed)));
    await pumpEventQueue();
    expect(states.last, const AuthError(kGoogleSignInFailed));
  });
}
