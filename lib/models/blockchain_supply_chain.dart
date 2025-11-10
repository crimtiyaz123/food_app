import 'package:json_annotation/json_annotation.dart';

part 'blockchain_supply_chain.g.dart';

enum SupplyChainStage {
  farming,
  processing,
  packaging,
  transportation,
  storage,
  distribution,
  delivery,
}

enum SupplyChainStatus {
  pending,
  inProgress,
  completed,
  verified,
  rejected,
}

@JsonSerializable()
class SupplyChainRecord {
  final String id;
  final String productId;
  final String batchId;
  final SupplyChainStage stage;
  final SupplyChainStatus status;
  final String participantId; // Farmer, processor, transporter, etc.
  final String participantName;
  final String location;
  final Map<String, dynamic> data; // Temperature, quality metrics, etc.
  final DateTime timestamp;
  final String transactionHash;
  final String previousTransactionHash;
  final bool verified;
  final Map<String, dynamic>? certificates;
  final Map<String, dynamic>? qualityMetrics;

  SupplyChainRecord({
    required this.id,
    required this.productId,
    required this.batchId,
    required this.stage,
    required this.status,
    required this.participantId,
    required this.participantName,
    required this.location,
    required this.data,
    required this.timestamp,
    required this.transactionHash,
    required this.previousTransactionHash,
    this.verified = false,
    this.certificates,
    this.qualityMetrics,
  });

  factory SupplyChainRecord.fromJson(Map<String, dynamic> json) =>
      _$SupplyChainRecordFromJson(json);

  Map<String, dynamic> toJson() => _$SupplyChainRecordToJson(this);
}

@JsonSerializable()
class SupplyChainBatch {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final String unit; // kg, liters, pieces, etc.
  final DateTime harvestDate;
  final String originFarm;
  final String originLocation;
  final List<SupplyChainRecord> records;
  final bool isComplete;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? finalQualityReport;

  SupplyChainBatch({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.harvestDate,
    required this.originFarm,
    required this.originLocation,
    required this.records,
    this.isComplete = false,
    required this.createdAt,
    this.completedAt,
    this.finalQualityReport,
  });

  factory SupplyChainBatch.fromJson(Map<String, dynamic> json) =>
      _$SupplyChainBatchFromJson(json);

  Map<String, dynamic> toJson() => _$SupplyChainBatchToJson(this);

  double get progressPercentage {
    if (records.isEmpty) return 0.0;
    final completedStages = records.where((r) => r.status == SupplyChainStatus.completed).length;
    return (completedStages / SupplyChainStage.values.length) * 100;
  }

  SupplyChainRecord? getCurrentRecord() {
    return records.where((r) => r.status == SupplyChainStatus.inProgress).firstOrNull;
  }

  SupplyChainRecord? getLastRecord() {
    if (records.isEmpty) return null;
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records.first;
  }
}

@JsonSerializable()
class SupplyChainVerification {
  final String id;
  final String batchId;
  final String verifierId;
  final String verifierName;
  final DateTime verificationDate;
  final bool isAuthentic;
  final Map<String, dynamic> verificationData;
  final String notes;
  final String transactionHash;

  SupplyChainVerification({
    required this.id,
    required this.batchId,
    required this.verifierId,
    required this.verifierName,
    required this.verificationDate,
    required this.isAuthentic,
    required this.verificationData,
    required this.notes,
    required this.transactionHash,
  });

  factory SupplyChainVerification.fromJson(Map<String, dynamic> json) =>
      _$SupplyChainVerificationFromJson(json);

  Map<String, dynamic> toJson() => _$SupplyChainVerificationToJson(this);
}

@JsonSerializable()
class SupplyChainAlert {
  final String id;
  final String batchId;
  final String alertType;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool resolved;
  final String severity;

  SupplyChainAlert({
    required this.id,
    required this.batchId,
    required this.alertType,
    required this.message,
    required this.data,
    required this.timestamp,
    this.resolved = false,
    required this.severity,
  });

  factory SupplyChainAlert.fromJson(Map<String, dynamic> json) =>
      _$SupplyChainAlertFromJson(json);

  Map<String, dynamic> toJson() => _$SupplyChainAlertToJson(this);
}

extension SupplyChainStageExtension on SupplyChainStage {
  String get displayName {
    switch (this) {
      case SupplyChainStage.farming:
        return 'Farming';
      case SupplyChainStage.processing:
        return 'Processing';
      case SupplyChainStage.packaging:
        return 'Packaging';
      case SupplyChainStage.transportation:
        return 'Transportation';
      case SupplyChainStage.storage:
        return 'Storage';
      case SupplyChainStage.distribution:
        return 'Distribution';
      case SupplyChainStage.delivery:
        return 'Delivery';
    }
  }

  int get order {
    return SupplyChainStage.values.indexOf(this);
  }
}
