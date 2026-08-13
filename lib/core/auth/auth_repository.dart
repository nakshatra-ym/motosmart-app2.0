import 'session.dart';

/// Wraps Cognito OTP sign-in (see PLAN_frontend.md's Auth flow). Screens and
/// the router only ever depend on this interface — never on Amplify or dio
/// directly — so swapping [MockAuthRepository] for a real
/// `amplify_flutter`-backed implementation later is a one-line provider
/// change.
abstract class AuthRepository {
  /// Kicks off Cognito's USER_AUTH passwordless flow: sends an OTP to the
  /// given email/phone. Throws [ApiException] if the identifier isn't a
  /// provisioned dealer-staff account (accounts are admin-provisioned).
  Future<void> requestOtp(String identifier);

  /// Confirms the OTP challenge and returns the resulting [Session].
  Future<Session> confirmOtp({required String identifier, required String otp});

  Future<void> signOut();
}
