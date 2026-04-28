import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/user_model.dart';

/// Result of a sign-up attempt.
/// - [needsVerification] = true means an email OTP was sent and the user must
///   call [AuthRemoteDataSource.verifyOtp] before they're authenticated.
class SignUpResult {
  final UserModel user;
  final bool needsVerification;
  const SignUpResult({required this.user, required this.needsVerification});
}

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String username,
  });

  /// Verify the 6-digit signup OTP sent to [email].
  Future<UserModel> verifyOtp({required String email, required String token});

  /// Re-send the signup OTP code.
  Future<void> resendOtp({required String email});

  Future<void> signOut();
  UserModel? currentUser();
  Stream<UserModel?> authStateChanges();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseService _service;
  AuthRemoteDataSourceImpl(this._service);

  GoTrueClient get _auth => _service.auth;

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final res = await _auth.signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) throw AuthException('Sign-in failed');
      return UserModel.fromSupabase(user);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final res = await _auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      final user = res.user;
      if (user == null) throw AuthException('Pendaftaran gagal');
      // session == null  → email confirmation required, OTP was sent.
      // session != null  → confirmations off in Supabase, user is fully signed in.
      return SignUpResult(
        user: UserModel.fromSupabase(user),
        needsVerification: res.session == null,
      );
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      final res = await _auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      final user = res.user;
      if (user == null) throw AuthException('Kode verifikasi tidak valid');
      return UserModel.fromSupabase(user);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> resendOtp({required String email}) async {
    try {
      await _auth.resend(email: email, type: OtpType.signup);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  UserModel? currentUser() {
    final u = _auth.currentUser;
    return u == null ? null : UserModel.fromSupabase(u);
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth.onAuthStateChange.map((event) {
      final u = event.session?.user;
      return u == null ? null : UserModel.fromSupabase(u);
    });
  }
}
