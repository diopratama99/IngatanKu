import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../../../core/config/env.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/repositories/auth_repository.dart';
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

  /// Send a 6-digit OTP for password reset.
  Future<void> sendPasswordResetOtp({required String email});

  /// Verify the password-reset OTP. On success the auth client holds a
  /// (recovery) session and [updatePassword] becomes callable.
  Future<UserModel> verifyPasswordResetOtp({
    required String email,
    required String token,
  });

  /// Update the password for the currently-authenticated user. Used after a
  /// recovery OTP has been verified.
  Future<void> updatePassword({required String newPassword});

  /// Verify [currentPassword] against the user's email then update to
  /// [newPassword]. Throws [AuthException] if the current password is
  /// wrong.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Update the `name` field in `user_metadata`. Returns the refreshed
  /// [UserModel] reflecting the new value.
  Future<UserModel> updateDisplayName({required String name});

  /// Stores the picked avatar ([avatarId]) in `user_metadata.avatar_id`
  /// (and drops the old uploaded photo's `avatar_url`).
  Future<UserModel> updateAvatar({required String avatarId});

  /// Signs in with the Google account picked on the phone. Null when the
  /// picker was dismissed; [isNew] when the account was made just now.
  Future<({UserModel user, bool isNew})?> signInWithGoogle();

  Future<void> signOut();
  UserModel? currentUser();
  Stream<UserModel?> authStateChanges();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseService _service;
  AuthRemoteDataSourceImpl(this._service);

  GoTrueClient get _auth => _service.auth;

  @override
  Future<UserModel> signIn(
      {required String email, required String password}) async {
    try {
      final res =
          await _auth.signInWithPassword(email: email, password: password);
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
  Future<void> sendPasswordResetOtp({required String email}) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    try {
      final res = await _auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      final user = res.user;
      if (user == null) throw AuthException('Kode reset tidak valid');
      return UserModel.fromSupabase(user);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _auth.currentUser?.email;
    if (email == null) {
      throw AuthException('Belum login');
    }
    // Supabase doesn't expose a native "verify password" call, so we
    // re-issue signInWithPassword as a verification step. On success
    // it just refreshes the existing session — no harm done.
    try {
      await _auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } on AuthApiException catch (e) {
      // Most common failure: invalid_grant / "Invalid login credentials".
      // Translate to something the user can act on.
      if (e.message.toLowerCase().contains('invalid')) {
        throw AuthException('Kata sandi saat ini salah');
      }
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }

    // Verified — now actually rotate the password.
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> updateDisplayName({required String name}) async {
    try {
      final res = await _auth.updateUser(
        UserAttributes(data: {'name': name}),
      );
      final u = res.user;
      if (u == null) throw AuthException('Gagal memperbarui nama');
      return UserModel.fromSupabase(u);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> updateAvatar({required String avatarId}) async {
    try {
      final res = await _auth.updateUser(
        UserAttributes(data: {'avatar_id': avatarId, 'avatar_url': null}),
      );
      final u = res.user;
      if (u == null) throw AuthException('Gagal memperbarui avatar');
      return UserModel.fromSupabase(u);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// `GoogleSignIn.initialize` may only run once per app run.
  static Future<void>? _googleReady;

  Future<void> _google() => _googleReady ??= GoogleSignIn.instance
      .initialize(serverClientId: Env.googleWebClientId);

  @override
  Future<({UserModel user, bool isNew})?> signInWithGoogle() async {
    final GoogleSignInAccount account;
    try {
      await _google();
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      debugPrint('[Auth] Google sign-in: ${e.code} ${e.description}');
      throw AuthException(kGoogleSignInFailed);
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw AuthException(kGoogleSignInFailed);
    try {
      final res = await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      final user = res.user;
      if (user == null) throw AuthException(kGoogleSignInFailed);
      // New on this sign-in: made within the last few minutes.
      final made = DateTime.tryParse(user.createdAt);
      final isNew = made != null &&
          DateTime.now().difference(made) < const Duration(minutes: 5);
      return (user: UserModel.fromSupabase(user), isNew: isNew);
    } on AuthApiException catch (e) {
      debugPrint('[Auth] Supabase Google sign-in: ${e.message}');
      throw AuthException(kGoogleSignInFailed);
    }
  }

  @override
  Future<void> signOut() async {
    // Forget the Google account too, so the next sign-in asks which one.
    if (_auth.currentUser?.appMetadata['provider'] == 'google' ||
        _googleReady != null) {
      try {
        await _google();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Signing out of the app mustn't wait on Google.
      }
    }
    await _auth.signOut();
  }

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
