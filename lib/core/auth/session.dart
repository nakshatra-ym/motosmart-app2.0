import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../models/enums.dart';

/// The authenticated identity for the app's lifetime — what would normally
/// be decoded from the Cognito JWT (`cognito:groups` -> [role]) plus the
/// `GET /me` profile lookup, collapsed into one object for the mock layer.
class Session {
  const Session({
    required this.token,
    required this.role,
    this.employee,
    this.customer,
  });

  final String token;
  final UserRole role;

  /// Populated for [UserRole.dealerStaff].
  final Employee? employee;

  /// Populated for [UserRole.customer].
  final Customer? customer;
}
