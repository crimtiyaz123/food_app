import 'package:cloud_firestore/cloud_firestore.dart';

// QR Code Types
enum QRCodeType {
  orderDelivery,
  pickupVerification,
  feedback,
  contactTracing,
  safetyCheck
}

// QR Code Status
enum QRCodeStatus {
  generated,
  active,
  used,
  expired,
  cancelled
}

// Delivery Contact Info
class DeliveryContactInfo {
  final String customerName;
  final String customerPhone;
  final String deliveryInstructions;
  final String dropOffLocation;
  final bool leaveAtDoor;
  final String? specialNotes;
  final List<String> safetyRequirements;

  DeliveryContactInfo({
    required this.customerName,
    required this.customerPhone,
    required this.deliveryInstructions,
    required this.dropOffLocation,
    required this.leaveAtDoor,
    this.specialNotes,
    required this.safetyRequirements,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryInstructions': deliveryInstructions,
      'dropOffLocation': dropOffLocation,
      'leaveAtDoor': leaveAtDoor,
      'specialNotes': specialNotes,
      'safetyRequirements': safetyRequirements,
    };
  }

  factory DeliveryContactInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryContactInfo(
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      deliveryInstructions: json['deliveryInstructions'] ?? '',
      dropOffLocation: json['dropOffLocation'] ?? '',
      leaveAtDoor: json['leaveAtDoor'] ?? false,
      specialNotes: json['specialNotes'],
      safetyRequirements: List<String>.from(json['safetyRequirements'] ?? []),
    );
  }
}

// QR Code Delivery Model
class QRCodeDelivery {
  final String id;
  final String orderId;
  final String deliveryPersonId;
  final String customerId;
  final QRCodeType codeType;
  final String qrCodeData;
  final QRCodeStatus status;
  final DeliveryContactInfo contactInfo;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? usedBy;
  final Map<String, dynamic> deliveryMetadata;
  final List<QRCodeScanEvent> scanHistory;
  final bool isContactless;
  final String? verificationToken;
  final int scanCount;
  final int maxScanCount;

  QRCodeDelivery({
    required this.id,
    required this.orderId,
    required this.deliveryPersonId,
    required this.customerId,
    required this.codeType,
    required this.qrCodeData,
    required this.status,
    required this.contactInfo,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.usedBy,
    required this.deliveryMetadata,
    required this.scanHistory,
    required this.isContactless,
    this.verificationToken,
    required this.scanCount,
    required this.maxScanCount,
  });

  factory QRCodeDelivery.fromJson(String id, Map<String, dynamic> json) {
    return QRCodeDelivery(
      id: id,
      orderId: json['orderId'] ?? '',
      deliveryPersonId: json['deliveryPersonId'] ?? '',
      customerId: json['customerId'] ?? '',
      codeType: QRCodeType.values.firstWhere(
        (e) => e.toString().split('.').last == json['codeType'],
        orElse: () => QRCodeType.orderDelivery,
      ),
      qrCodeData: json['qrCodeData'] ?? '',
      status: QRCodeStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => QRCodeStatus.generated,
      ),
      contactInfo: DeliveryContactInfo.fromJson(json['contactInfo'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt']),
      usedAt: json['usedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['usedAt']) : null,
      usedBy: json['usedBy'],
      deliveryMetadata: Map<String, dynamic>.from(json['deliveryMetadata'] ?? {}),
      scanHistory: (json['scanHistory'] as List<dynamic>?)
          ?.map((e) => QRCodeScanEvent.fromJson(e))
          .toList() ?? [],
      isContactless: json['isContactless'] ?? true,
      verificationToken: json['verificationToken'],
      scanCount: json['scanCount'] ?? 0,
      maxScanCount: json['maxScanCount'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'deliveryPersonId': deliveryPersonId,
      'customerId': customerId,
      'codeType': codeType.toString().split('.').last,
      'qrCodeData': qrCodeData,
      'status': status.toString().split('.').last,
      'contactInfo': contactInfo.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'usedAt': usedAt?.millisecondsSinceEpoch,
      'usedBy': usedBy,
      'deliveryMetadata': deliveryMetadata,
      'scanHistory': scanHistory.map((e) => e.toJson()).toList(),
      'isContactless': isContactless,
      'verificationToken': verificationToken,
      'scanCount': scanCount,
      'maxScanCount': maxScanCount,
    };
  }

  // Check if QR code is still valid
  bool isValid() {
    final now = DateTime.now();
    return status == QRCodeStatus.active && 
           now.isBefore(expiresAt) && 
           scanCount < maxScanCount;
  }

  // Check if QR code has expired
  bool isExpired() {
    return DateTime.now().isAfter(expiresAt);
  }

  // Check if QR code can be used
  bool canBeUsed() {
    return isValid() && status == QRCodeStatus.active;
  }

  // Mark as used
  QRCodeDelivery markAsUsed(String userId) {
    return copyWith(
      status: QRCodeStatus.used,
      usedAt: DateTime.now(),
      usedBy: userId,
      scanCount: scanCount + 1,
    );
  }

  // Add scan event
  QRCodeDelivery addScanEvent(QRCodeScanEvent event) {
    final updatedHistory = List<QRCodeScanEvent>.from(scanHistory)..add(event);
    return copyWith(
      scanHistory: updatedHistory,
      scanCount: scanCount + 1,
    );
  }

  // Generate delivery completion data
  Map<String, dynamic> getDeliveryCompletionData() {
    return {
      'orderId': orderId,
      'deliveryPersonId': deliveryPersonId,
      'customerId': customerId,
      'deliveredAt': DateTime.now().toIso8601String(),
      'contactless': isContactless,
      'verificationToken': verificationToken,
      'deliveryMetadata': deliveryMetadata,
      'finalLocation': contactInfo.dropOffLocation,
      'customerSatisfaction': null, // To be filled later
    };
  }

  QRCodeDelivery copyWith({
    String? id,
    String? orderId,
    String? deliveryPersonId,
    String? customerId,
    QRCodeType? codeType,
    String? qrCodeData,
    QRCodeStatus? status,
    DeliveryContactInfo? contactInfo,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? usedBy,
    Map<String, dynamic>? deliveryMetadata,
    List<QRCodeScanEvent>? scanHistory,
    bool? isContactless,
    String? verificationToken,
    int? scanCount,
    int? maxScanCount,
  }) {
    return QRCodeDelivery(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      customerId: customerId ?? this.customerId,
      codeType: codeType ?? this.codeType,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      status: status ?? this.status,
      contactInfo: contactInfo ?? this.contactInfo,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedBy: usedBy ?? this.usedBy,
      deliveryMetadata: deliveryMetadata ?? this.deliveryMetadata,
      scanHistory: scanHistory ?? this.scanHistory,
      isContactless: isContactless ?? this.isContactless,
      verificationToken: verificationToken ?? this.verificationToken,
      scanCount: scanCount ?? this.scanCount,
      maxScanCount: maxScanCount ?? this.maxScanCount,
    );
  }
}

// QR Code Scan Event
class QRCodeScanEvent {
  final String id;
  final String scannedBy;
  final String scannedByRole; // 'customer', 'delivery_person', 'restaurant'
  final DateTime scannedAt;
  final String? location;
  final String? deviceInfo;
  final Map<String, dynamic>? additionalData;
  final double? accuracy;
  final bool isSuccessful;

  QRCodeScanEvent({
    required this.id,
    required this.scannedBy,
    required this.scannedByRole,
    required this.scannedAt,
    this.location,
    this.deviceInfo,
    this.additionalData,
    this.accuracy,
    required this.isSuccessful,
  });

  factory QRCodeScanEvent.fromJson(Map<String, dynamic> json) {
    return QRCodeScanEvent(
      id: json['id'] ?? '',
      scannedBy: json['scannedBy'] ?? '',
      scannedByRole: json['scannedByRole'] ?? '',
      scannedAt: DateTime.fromMillisecondsSinceEpoch(json['scannedAt']),
      location: json['location'],
      deviceInfo: json['deviceInfo'],
      additionalData: json['additionalData'],
      accuracy: json['accuracy']?.toDouble(),
      isSuccessful: json['isSuccessful'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scannedBy': scannedBy,
      'scannedByRole': scannedByRole,
      'scannedAt': scannedAt.millisecondsSinceEpoch,
      'location': location,
      'deviceInfo': deviceInfo,
      'additionalData': additionalData,
      'accuracy': accuracy,
      'isSuccessful': isSuccessful,
    };
  }
}

// Contactless Delivery Request
class ContactlessDeliveryRequest {
  final String orderId;
  final String customerId;
  final bool contactlessDelivery;
  final String dropOffInstructions;
  final String dropOffLocation;
  final bool leaveAtDoor;
  final String? specialNotes;
  final List<String> safetyMeasures;
  final String verificationMethod;
  final DateTime requestedAt;

  ContactlessDeliveryRequest({
    required this.orderId,
    required this.customerId,
    required this.contactlessDelivery,
    required this.dropOffInstructions,
    required this.dropOffLocation,
    required this.leaveAtDoor,
    this.specialNotes,
    required this.safetyMeasures,
    required this.verificationMethod,
    required this.requestedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'contactlessDelivery': contactlessDelivery,
      'dropOffInstructions': dropOffInstructions,
      'dropOffLocation': dropOffLocation,
      'leaveAtDoor': leaveAtDoor,
      'specialNotes': specialNotes,
      'safetyMeasures': safetyMeasures,
      'verificationMethod': verificationMethod,
      'requestedAt': requestedAt.millisecondsSinceEpoch,
    };
  }

  factory ContactlessDeliveryRequest.fromJson(Map<String, dynamic> json) {
    return ContactlessDeliveryRequest(
      orderId: json['orderId'] ?? '',
      customerId: json['customerId'] ?? '',
      contactlessDelivery: json['contactlessDelivery'] ?? true,
      dropOffInstructions: json['dropOffInstructions'] ?? '',
      dropOffLocation: json['dropOffLocation'] ?? '',
      leaveAtDoor: json['leaveAtDoor'] ?? false,
      specialNotes: json['specialNotes'],
      safetyMeasures: List<String>.from(json['safetyMeasures'] ?? []),
      verificationMethod: json['verificationMethod'] ?? 'qr_code',
      requestedAt: DateTime.fromMillisecondsSinceEpoch(json['requestedAt']),
    );
  }
}

// Delivery Safety Protocol
class DeliverySafetyProtocol {
  final String id;
  final String name;
  final String description;
  final List<String> requirements;
  final bool isActive;
  final DateTime createdAt;
  final String? iconUrl;
  final int orderPriority;

  DeliverySafetyProtocol({
    required this.id,
    required this.name,
    required this.description,
    required this.requirements,
    required this.isActive,
    required this.createdAt,
    this.iconUrl,
    required this.orderPriority,
  });

  factory DeliverySafetyProtocol.fromJson(Map<String, dynamic> json) {
    return DeliverySafetyProtocol(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      requirements: List<String>.from(json['requirements'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      iconUrl: json['iconUrl'],
      orderPriority: json['orderPriority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'requirements': requirements,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'iconUrl': iconUrl,
      'orderPriority': orderPriority,
    };
  }
}