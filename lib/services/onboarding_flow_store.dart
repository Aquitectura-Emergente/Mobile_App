import 'package:shared_preferences/shared_preferences.dart';

enum ClientType { company, individual }

class PersonalDetailsDraft {
  const PersonalDetailsDraft({
    required this.clientType,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    this.documentId,
    this.companyName,
    this.industry,
    this.contactName,
  });

  final ClientType clientType;
  final String displayName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String country;
  final String? documentId;
  final String? companyName;
  final String? industry;
  final String? contactName;

  /// Backend clientType value ('company' | 'individual').
  String get clientTypeValue =>
      clientType == ClientType.company ? 'company' : 'individual';

  String get clientTypeLabel =>
      clientType == ClientType.company ? 'Company' : 'Individual';
}

class OnboardingFlowStore {
  static const _accountCreatedKey = 'emsafe_account_created';

  static PersonalDetailsDraft? personalDetailsDraft;

  static Future<bool> hasCreatedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_accountCreatedKey) ?? false;
  }

  static Future<void> markAccountCreated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_accountCreatedKey, true);
  }
}
