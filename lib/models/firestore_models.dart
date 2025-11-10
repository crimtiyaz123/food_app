import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String docId) {
    return UserModel(
      id: docId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
    };
  }
}

class Organization {
  final String id;
  final String name;
  final String type; // e.g., 'Restaurant', 'Stock', 'Delivery'

  Organization({
    required this.id,
    required this.name,
    required this.type,
  });

  factory Organization.fromMap(Map<String, dynamic> data, String docId) {
    return Organization(
      id: docId,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
    };
  }
}

class Role {
  final String id;
  final String name;

  Role({required this.id, required this.name});

  factory Role.fromMap(Map<String, dynamic> data, String docId) {
    return Role(
      id: docId,
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name};
  }
}

class OrgUser {
  final String id;
  final String orgId;
  final String userId;
  final String roleId;
  final bool isActive;
  final DateTime joinedAt;

  OrgUser({
    required this.id,
    required this.orgId,
    required this.userId,
    required this.roleId,
    this.isActive = true,
    required this.joinedAt,
  });

  factory OrgUser.fromMap(Map<String, dynamic> data, String docId) {
    return OrgUser(
      id: docId,
      orgId: data['orgId'] ?? '',
      userId: data['userId'] ?? '',
      roleId: data['roleId'] ?? '',
      isActive: data['isActive'] ?? true,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orgId': orgId,
      'userId': userId,
      'roleId': roleId,
      'isActive': isActive,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

class InitialSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> roles = [
    'SuperAdmin',
    'Stock User',
    'Admin (Stock Admin)',
    'Delivery Boy',
    'Admin (Delivery Admin)',
    'Customer',
  ];

  final List<Map<String, String>> orgs = [
    {'name': 'Restaurant Org', 'type': 'Restaurant'},
    {'name': 'Stock Org', 'type': 'Stock'},
    {'name': 'Delivery Org', 'type': 'Delivery'},
  ];

  Future<void> seedRoles() async {
    final collection = _db.collection('roles');
    for (var role in roles) {
      final exists = await collection.where('name', isEqualTo: role).get();
      if (exists.docs.isEmpty) {
        await collection.add({'name': role});
        print('Added Role: $role');
      }
    }
  }

  Future<void> seedOrgs() async {
    final collection = _db.collection('orgs');
    for (var org in orgs) {
      final exists = await collection.where('name', isEqualTo: org['name']).get();
      if (exists.docs.isEmpty) {
        await collection.add(org);
        print('Added Org: ${org['name']}');
      }
    }
  }

  Future<void> seedFoodCategories() async {
    final collection = _db.collection('foodCategories');
    final String jsonString = await rootBundle.loadString('lib/Seed/food_categories.json');
    final List<dynamic> categoriesData = json.decode(jsonString);

    for (var categoryData in categoriesData) {
      final categoryName = categoryData['name'];
      final exists = await collection.where('name', isEqualTo: categoryName).get();
      if (exists.docs.isEmpty) {
        await collection.add(categoryData);
        print('Added Food Category: $categoryName');
      }
    }
  }

  Future<void> seedAll() async {
    await seedRoles();
    await seedOrgs();
    await seedFoodCategories();
  }
}