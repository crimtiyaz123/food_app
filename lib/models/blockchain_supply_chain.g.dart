// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blockchain_supply_chain.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupplyChainRecord _$SupplyChainRecordFromJson(Map<String, dynamic> json) =>
    SupplyChainRecord(
      id: json['id'] as String,
      productId: json['productId'] as String,
      batchId: json['batchId'] as String,
      stage: $enumDecode(_$SupplyChainStageEnumMap, json['stage']),
      status: $enumDecode(_$SupplyChainStatusEnumMap, json['status']),
      participantId: json['participantId'] as String,
      participantName: json['participantName'] as String,
      location: json['location'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      transactionHash: json['transactionHash'] as String,
      previousTransactionHash: json['previousTransactionHash'] as String,
      verified: json['verified'] as bool? ?? false,
      certificates: json['certificates'] as Map<String, dynamic>?,
      qualityMetrics: json['qualityMetrics'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SupplyChainRecordToJson(SupplyChainRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'batchId': instance.batchId,
      'stage': _$SupplyChainStageEnumMap[instance.stage]!,
      'status': _$SupplyChainStatusEnumMap[instance.status]!,
      'participantId': instance.participantId,
      'participantName': instance.participantName,
      'location': instance.location,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
      'transactionHash': instance.transactionHash,
      'previousTransactionHash': instance.previousTransactionHash,
      'verified': instance.verified,
      'certificates': instance.certificates,
      'qualityMetrics': instance.qualityMetrics,
    };

const _$SupplyChainStageEnumMap = {
  SupplyChainStage.farming: 'farming',
  SupplyChainStage.processing: 'processing',
  SupplyChainStage.packaging: 'packaging',
  SupplyChainStage.transportation: 'transportation',
  SupplyChainStage.storage: 'storage',
  SupplyChainStage.distribution: 'distribution',
  SupplyChainStage.delivery: 'delivery',
};

const _$SupplyChainStatusEnumMap = {
  SupplyChainStatus.pending: 'pending',
  SupplyChainStatus.inProgress: 'inProgress',
  SupplyChainStatus.completed: 'completed',
  SupplyChainStatus.verified: 'verified',
  SupplyChainStatus.rejected: 'rejected',
};

SupplyChainBatch _$SupplyChainBatchFromJson(Map<String, dynamic> json) =>
    SupplyChainBatch(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unit: json['unit'] as String,
      harvestDate: DateTime.parse(json['harvestDate'] as String),
      originFarm: json['originFarm'] as String,
      originLocation: json['originLocation'] as String,
      records: (json['records'] as List<dynamic>)
          .map((e) => SupplyChainRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      isComplete: json['isComplete'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      finalQualityReport: json['finalQualityReport'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SupplyChainBatchToJson(SupplyChainBatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'harvestDate': instance.harvestDate.toIso8601String(),
      'originFarm': instance.originFarm,
      'originLocation': instance.originLocation,
      'records': instance.records,
      'isComplete': instance.isComplete,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'finalQualityReport': instance.finalQualityReport,
    };

SupplyChainVerification _$SupplyChainVerificationFromJson(
        Map<String, dynamic> json) =>
    SupplyChainVerification(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      verifierId: json['verifierId'] as String,
      verifierName: json['verifierName'] as String,
      verificationDate: DateTime.parse(json['verificationDate'] as String),
      isAuthentic: json['isAuthentic'] as bool,
      verificationData: json['verificationData'] as Map<String, dynamic>,
      notes: json['notes'] as String,
      transactionHash: json['transactionHash'] as String,
    );

Map<String, dynamic> _$SupplyChainVerificationToJson(
        SupplyChainVerification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batchId': instance.batchId,
      'verifierId': instance.verifierId,
      'verifierName': instance.verifierName,
      'verificationDate': instance.verificationDate.toIso8601String(),
      'isAuthentic': instance.isAuthentic,
      'verificationData': instance.verificationData,
      'notes': instance.notes,
      'transactionHash': instance.transactionHash,
    };

SupplyChainAlert _$SupplyChainAlertFromJson(Map<String, dynamic> json) =>
    SupplyChainAlert(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      alertType: json['alertType'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      resolved: json['resolved'] as bool? ?? false,
      severity: json['severity'] as String,
    );

Map<String, dynamic> _$SupplyChainAlertToJson(SupplyChainAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batchId': instance.batchId,
      'alertType': instance.alertType,
      'message': instance.message,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
      'resolved': instance.resolved,
      'severity': instance.severity,
    };
