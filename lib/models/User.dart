// ===================== LOGIN USER =====================
class LoginUser {
  final String email;
  final String password;

  LoginUser({
    required this.email,
    required this.password,
  });

  // ✅ Convert to JSON (useful for APIs or Firestore)
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

// ===================== REGISTRATION USER =====================
class RegistrationUser {
  final PersonalInfo personalInfo;
  final AddressInfo? addressInfo;

  RegistrationUser({
    required this.personalInfo,
    this.addressInfo,
  });

  // ✅ Convert registration data to JSON
  Map<String, dynamic> toJson() {
    return {
      'personalInfo': personalInfo.toJson(),
      if (addressInfo != null) 'addressInfo': addressInfo!.toJson(),
    };
  }
}

// ===================== PERSONAL INFO =====================
class PersonalInfo {
  final String name;
  final String email;
  final String phone;
  final String password;

  PersonalInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };
  }
}

// ===================== ADDRESS INFO =====================
class AddressInfo {
  final String street;
  final String city;
  final String state;
  final String zip;

  AddressInfo({
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
  });

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zip': zip,
    };
  }
}
