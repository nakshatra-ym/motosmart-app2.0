import 'customer.dart';

/// The outcome of converting a lead: the customer row, plus whether they
/// actually got a login.
///
/// The two can disagree. Conversion never fails because Cognito did — the
/// customer is still created — so [invited] being false with an [inviteError]
/// means the dealer has a customer who cannot sign in yet. That has to be
/// visible, because the symptom otherwise appears days later as "I never got
/// the code".
class LeadConversion {
  const LeadConversion({
    required this.customer,
    required this.invited,
    this.inviteError,
  });

  final Customer customer;
  final bool invited;
  final String? inviteError;

  factory LeadConversion.fromJson(Map<String, dynamic> json, Customer customer) =>
      LeadConversion(
        customer: customer,
        invited: json['invited'] as bool? ?? false,
        inviteError: json['invite_error'] as String?,
      );
}
