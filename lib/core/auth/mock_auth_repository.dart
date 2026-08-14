import '../../data/mock/mock_data_store.dart';
import '../../models/dealer.dart';
import '../../models/enums.dart';
import '../network/api_exception.dart';
import 'auth_repository.dart';
import 'session.dart';
import 'token_storage.dart';

/// Simulates Cognito's passwordless OTP flow against seeded dealer-staff
/// and customer accounts. The OTP is fixed at [demoOtp] and shown on the
/// OTP screen — this is a hackathon demo standing in for real SMS/email
/// delivery, not a security boundary.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._store, this._tokenStorage);

  static const demoOtp = '123456';

  final MockDataStore _store;
  final TokenStorage _tokenStorage;

  static const _notFoundMessage = 'No account found for that email.';

  @override
  Future<void> requestOtp(String identifier) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final employee = _store.findEmployeeByIdentifier(identifier);
    if (employee != null) {
      if (!employee.isActive) {
        throw const ApiException('This account has been deactivated.', statusCode: 403);
      }
      return;
    }
    final customer = _store.findCustomerByIdentifier(identifier);
    if (customer == null) {
      throw const ApiException(_notFoundMessage, statusCode: 404);
    }
  }

  @override
  Future<Session> confirmOtp({required String identifier, required String otp}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (otp.trim() != demoOtp) {
      throw const ApiException('Incorrect OTP. Please try again.', statusCode: 401);
    }

    final employee = _store.findEmployeeByIdentifier(identifier);
    if (employee != null) {
      final token = 'mock-jwt.${employee.id}.${DateTime.now().millisecondsSinceEpoch}';
      await _tokenStorage.saveToken(token);
      return Session(
        token: token,
        role: UserRole.dealerStaff,
        employee: employee,
        dealer: _dealerFor(employee.dealerId),
      );
    }

    final customer = _store.findCustomerByIdentifier(identifier);
    if (customer != null) {
      final token = 'mock-jwt.${customer.id}.${DateTime.now().millisecondsSinceEpoch}';
      await _tokenStorage.saveToken(token);
      return Session(
        token: token,
        role: UserRole.customer,
        customer: customer,
        dealer: _dealerFor(customer.onboardingDealerId),
      );
    }

    throw const ApiException(_notFoundMessage, statusCode: 404);
  }

  @override
  Future<void> signOut() async {
    await _tokenStorage.clearToken();
  }

  /// The branch a mock identity belongs to, so offline mode carries the same
  /// dealer the API returns with `GET /me`.
  Dealer? _dealerFor(String? dealerId) {
    if (dealerId == null) return null;
    for (final d in _store.dealers) {
      if (d.id == dealerId) return d;
    }
    return null;
  }
}
