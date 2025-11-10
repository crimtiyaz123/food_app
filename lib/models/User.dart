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

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
    );
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

  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    return AddressInfo(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
    );
  }
}

// ===================== ROLE ENUM =====================
enum Role {
  superAdmin,
  stockUser,
  adminStock,
  deliveryBoy,
  adminDelivery,
  customer,
}

// ===================== USER ENTITY =====================
class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String password; // Note: In production, hash passwords
  final PersonalInfo personalInfo;
  final AddressInfo? addressInfo;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.password,
    required this.personalInfo,
    this.addressInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'password': password,
      'personalInfo': personalInfo.toJson(),
      if (addressInfo != null) 'addressInfo': addressInfo!.toJson(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json, [String? documentId]) {
    final id = documentId ?? json['id'] ?? '';
    return User(
      id: id,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      personalInfo: PersonalInfo.fromJson(json['personalInfo'] ?? {}),
      addressInfo: json['addressInfo'] != null ? AddressInfo.fromJson(json['addressInfo']) : null,
    );
  }
}

// ===================== ORG ENTITY =====================
class Org {
  final String id;
  final String name;
  final String type; // e.g., 'Restaurant', 'Delivery', 'Stock'

  Org({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  factory Org.fromJson(Map<String, dynamic> json) {
    return Org(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}

// ===================== ORGUSER ENTITY =====================
class OrgUser {
  final String userId;
  final String orgId;
  final Role role;

  OrgUser({
    required this.userId,
    required this.orgId,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'orgId': orgId,
      'role': role.name, // Store as string
    };
  }

  factory OrgUser.fromJson(Map<String, dynamic> json) {
    return OrgUser(
      userId: json['userId'],
      orgId: json['orgId'],
      role: Role.values.firstWhere((e) => e.name == json['role']),
    );
  }
}
