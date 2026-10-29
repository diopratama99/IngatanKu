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

/// "Continue with Google": signs in, or makes the account the first time.
class AuthGoogleSignInRequested extends AuthEvent {}

class AuthOtpVerificationRequested extends AuthEvent {
  final String email;
  final String token;
  const AuthOtpVerificationRequested(
      {required this.email, required this.token});
  @override
  List<Object?> get props => [email, token];
}

class AuthOtpResendRequested extends AuthEvent {
  final String email;
  const AuthOtpResendRequested(this.email);
  @override
  List<Object?> get props => [email];
}

/// Request a password reset — sends a 6-digit recovery OTP to [email].
class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}

/// Verify the password-reset OTP. On success the bloc enters
/// [AuthPasswordResetVerified] and waits for [AuthPasswordUpdateRequested].
class AuthPasswordResetVerifyRequested extends AuthEvent {
  final String email;
  final String token;
  const AuthPasswordResetVerifyRequested({
    required this.email,
    required this.token,
  });
  @override
  List<Object?> get props => [email, token];
}

/// Submit the new password during the password-reset flow.
class AuthPasswordUpdateRequested extends AuthEvent {
  final String newPassword;
  const AuthPasswordUpdateRequested(this.newPassword);
  @override
  List<Object?> get props => [newPassword];
}

/// Update the user's display name (`user_metadata.name`).
class AuthDisplayNameUpdateRequested extends AuthEvent {
  final String name;
  const AuthDisplayNameUpdateRequested(this.name);
  @override
  List<Object?> get props => [name];
}

/// Verify [currentPassword] then rotate to [newPassword]. Used from
/// the Settings page (different flow from the unauthenticated reset).
class AuthChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  const AuthChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });
  @override
  List<Object?> get props => [currentPassword, newPassword];
}

/// Upload a new avatar. Caller already cropped the image.
/// The user picked another avatar (a `UserAvatar` id).
class AuthAvatarUpdateRequested extends AuthEvent {
  final String avatarId;
  const AuthAvatarUpdateRequested(this.avatarId);
  @override
  List<Object?> get props => [avatarId];
}

// ============ STATES ============
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

/// Signing in with Google (its button spins, not the email one).
class AuthGoogleLoading extends AuthLoading {}

class Authenticated extends AuthState {
  final UserEntity user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

/// Signed in with an account made just now (by Google): the welcome
/// story comes first.
class AuthNewAccount extends Authenticated {
  const AuthNewAccount(super.user);
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

/// Password-reset code dispatched — the UI should advance to the OTP step.
class AuthPasswordResetCodeSent extends AuthState {
  final String email;
  const AuthPasswordResetCodeSent(this.email);
  @override
  List<Object?> get props => [email];
}

/// Recovery OTP verified — the auth client now holds a recovery session.
/// The UI should advance to the new-password step. The bloc *suppresses* the
/// auto-emitted [Authenticated] from the auth-state stream while in this
/// state so the user is forced through password update first.
class AuthPasswordResetVerified extends AuthState {
  final String email;
  const AuthPasswordResetVerified(this.email);
  @override
  List<Object?> get props => [email];
}

/// Profile update succeeded (display name, avatar, or password
/// changed). Carries the latest user so the page can refresh
/// without waiting for the auth-state stream tick.
class AuthProfileUpdateSuccess extends AuthState {
  final UserEntity user;
  final String message;
  const AuthProfileUpdateSuccess({
    required this.user,
    required this.message,
  });
  @override
  List<Object?> get props => [user, message];
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
    on<AuthGoogleSignInRequested>(_onGoogle);
    on<AuthOtpVerificationRequested>(_onVerifyOtp);
    on<AuthOtpResendRequested>(_onResendOtp);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthPasswordResetVerifyRequested>(_onPasswordResetVerify);
    on<AuthPasswordUpdateRequested>(_onPasswordUpdate);
    on<AuthDisplayNameUpdateRequested>(_onDisplayNameUpdate);
    on<AuthChangePasswordRequested>(_onChangePassword);
    on<AuthAvatarUpdateRequested>(_onAvatarUpdate);
  }

  void _onStarted(AuthStarted e, Emitter<AuthState> emit) {
    final u = _repo.currentUser;
    emit(u != null ? Authenticated(u) : Unauthenticated());
    _sub?.cancel();
    _sub = _repo.authStateChanges().listen((u) => add(AuthUserChanged(u)));
  }

  void _onUserChanged(AuthUserChanged e, Emitter<AuthState> emit) {
    // While the recovery flow is in progress (between OTP verify and password
    // update) Supabase has already issued a session, which would normally
    // cause this listener to flip the state to [Authenticated]. We suppress
    // that so the UI stays on the new-password step until the user submits.
    if (state is AuthPasswordResetVerified) return;
    // Mid-Google sign-in the session lands before we know if the account
    // is new; [_onGoogle] says which once it does.
    if (state is AuthGoogleLoading && e.user != null) return;
    // The same new account, refreshed: still new (it's on its way to the
    // welcome story).
    final s = state;
    if (s is AuthNewAccount && e.user?.id == s.user.id) {
      emit(AuthNewAccount(e.user!));
      return;
    }
    emit(e.user != null ? Authenticated(e.user!) : Unauthenticated());
  }

  Future<void> _onGoogle(
    AuthGoogleSignInRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthGoogleLoading());
    final res = await _repo.signInWithGoogle();
    res.fold(
      (f) => emit(AuthError(f.message)),
      (out) => emit(out == null
          // Picker dismissed: back where we were.
          ? Unauthenticated()
          : out.isNew
              ? AuthNewAccount(out.user)
              : Authenticated(out.user)),
    );
  }

  Future<void> _onSignIn(AuthSignInRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res =
        await _signIn(SignInParams(email: e.email, password: e.password));
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

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final res = await _repo.sendPasswordResetOtp(email: e.email);
    res.fold(
      (f) => emit(AuthError(f.message)),
      (_) => emit(AuthPasswordResetCodeSent(e.email)),
    );
  }

  Future<void> _onPasswordResetVerify(
    AuthPasswordResetVerifyRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final res = await _repo.verifyPasswordResetOtp(
      email: e.email,
      token: e.token,
    );
    res.fold(
      (f) => emit(AuthError(f.message)),
      (_) => emit(AuthPasswordResetVerified(e.email)),
    );
  }

  Future<void> _onPasswordUpdate(
    AuthPasswordUpdateRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final res = await _repo.updatePassword(newPassword: e.newPassword);
    res.fold(
      (f) => emit(AuthError(f.message)),
      (_) {
        final u = _repo.currentUser;
        emit(u != null ? Authenticated(u) : Unauthenticated());
      },
    );
  }

  Future<void> _onDisplayNameUpdate(
    AuthDisplayNameUpdateRequested e,
    Emitter<AuthState> emit,
  ) async {
    final previous = state;
    emit(AuthLoading());
    final res = await _repo.updateDisplayName(name: e.name);
    res.fold(
      (f) {
        // Restore the previous Authenticated state so the page doesn't
        // bounce back to a logged-out look on transient errors.
        emit(AuthError(f.message));
        if (previous is Authenticated) emit(previous);
      },
      (user) {
        emit(AuthProfileUpdateSuccess(
          user: user,
          message: 'Nama berhasil diperbarui',
        ));
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _onChangePassword(
    AuthChangePasswordRequested e,
    Emitter<AuthState> emit,
  ) async {
    final previous = state;
    emit(AuthLoading());
    final res = await _repo.changePassword(
      currentPassword: e.currentPassword,
      newPassword: e.newPassword,
    );
    res.fold(
      (f) {
        emit(AuthError(f.message));
        if (previous is Authenticated) emit(previous);
      },
      (_) {
        final u = _repo.currentUser;
        if (u != null) {
          emit(AuthProfileUpdateSuccess(
            user: u,
            message: 'Kata sandi berhasil diperbarui',
          ));
          emit(Authenticated(u));
        } else {
          emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> _onAvatarUpdate(
    AuthAvatarUpdateRequested e,
    Emitter<AuthState> emit,
  ) async {
    final previous = state;
    emit(AuthLoading());
    final res = await _repo.updateAvatar(avatarId: e.avatarId);
    res.fold(
      (f) {
        emit(AuthError(f.message));
        if (previous is Authenticated) emit(previous);
      },
      (user) {
        emit(AuthProfileUpdateSuccess(
          user: user,
          message: 'Avatar berhasil diganti',
        ));
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _onSignOut(
      AuthSignOutRequested e, Emitter<AuthState> emit) async {
    await _signOut(const NoParams());
    emit(Unauthenticated());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
