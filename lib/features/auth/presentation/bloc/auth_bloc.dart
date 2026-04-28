import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';

// ============ EVENTS ============
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final UserEntity? user;
  const AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  const AuthSignUpRequested(this.email, this.password, this.username);
  @override
  List<Object?> get props => [email, password, username];
}

class AuthSignOutRequested extends AuthEvent {}

class AuthOtpVerificationRequested extends AuthEvent {
  final String email;
  final String token;
  const AuthOtpVerificationRequested({required this.email, required this.token});
  @override
  List<Object?> get props => [email, token];
}

class AuthOtpResendRequested extends AuthEvent {
  final String email;
  const AuthOtpResendRequested(this.email);
  @override
  List<Object?> get props => [email];
}

// ============ STATES ============
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserEntity user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Sign-up succeeded but the user must enter a 6-digit OTP from their email
/// before the session is granted.
class AuthAwaitingOtp extends AuthState {
  final String email;
  const AuthAwaitingOtp(this.email);
  @override
  List<Object?> get props => [email];
}

/// Resend OTP succeeded.
class AuthOtpResent extends AuthState {
  final String email;
  const AuthOtpResent(this.email);
  @override
  List<Object?> get props => [email];
}

// ============ BLOC ============
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final AuthRepository _repo;
  StreamSubscription<UserEntity?>? _sub;

  AuthBloc({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required AuthRepository repo,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut,
        _repo = repo,
        super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthOtpVerificationRequested>(_onVerifyOtp);
    on<AuthOtpResendRequested>(_onResendOtp);
  }

  void _onStarted(AuthStarted e, Emitter<AuthState> emit) {
    final u = _repo.currentUser;
    emit(u != null ? Authenticated(u) : Unauthenticated());
    _sub?.cancel();
    _sub = _repo.authStateChanges().listen((u) => add(AuthUserChanged(u)));
  }

  void _onUserChanged(AuthUserChanged e, Emitter<AuthState> emit) {
    emit(e.user != null ? Authenticated(e.user!) : Unauthenticated());
  }

  Future<void> _onSignIn(AuthSignInRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _signIn(SignInParams(email: e.email, password: e.password));
    res.fold(
      (f) => emit(AuthError(f.message)),
      (u) => emit(Authenticated(u)),
    );
  }

  Future<void> _onSignUp(AuthSignUpRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _signUp(
      SignUpParams(email: e.email, password: e.password, username: e.username),
    );
    res.fold(
      (f) => emit(AuthError(f.message)),
      (outcome) => emit(
        outcome.needsVerification
            ? AuthAwaitingOtp(e.email)
            : Authenticated(outcome.user),
      ),
    );
  }

  Future<void> _onVerifyOtp(
    AuthOtpVerificationRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final res = await _repo.verifyOtp(email: e.email, token: e.token);
    res.fold(
      (f) => emit(AuthError(f.message)),
      (u) => emit(Authenticated(u)),
    );
  }

  Future<void> _onResendOtp(
    AuthOtpResendRequested e,
    Emitter<AuthState> emit,
  ) async {
    final res = await _repo.resendOtp(email: e.email);
    res.fold(
      (f) => emit(AuthError(f.message)),
      (_) => emit(AuthOtpResent(e.email)),
    );
  }

  Future<void> _onSignOut(AuthSignOutRequested e, Emitter<AuthState> emit) async {
    await _signOut(const NoParams());
    emit(Unauthenticated());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
