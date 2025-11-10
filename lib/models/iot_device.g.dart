// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iot_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IoTDevice _$IoTDeviceFromJson(Map<String, dynamic> json) => IoTDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$IoTDeviceTypeEnumMap, json['type']),
      category: $enumDecode(_$IoTDeviceCategoryEnumMap, json['category']),
      restaurantId: json['restaurantId'] as String,
      locationId: json['locationId'] as String?,
      status: $enumDecode(_$IoTDeviceStatusEnumMap, json['status']),
      capabilities: json['capabilities'] as Map<String, dynamic>,
      currentReadings: json['currentReadings'] as Map<String, dynamic>,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      installedAt: DateTime.parse(json['installedAt'] as String),
      firmwareVersion: json['firmwareVersion'] as String,
      isActive: json['isActive'] as bool? ?? true,
      settings: json['settings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$IoTDeviceToJson(IoTDevice instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$IoTDeviceTypeEnumMap[instance.type]!,
      'category': _$IoTDeviceCategoryEnumMap[instance.category]!,
      'restaurantId': instance.restaurantId,
      'locationId': instance.locationId,
      'status': _$IoTDeviceStatusEnumMap[instance.status]!,
      'capabilities': instance.capabilities,
      'currentReadings': instance.currentReadings,
      'lastSeen': instance.lastSeen.toIso8601String(),
      'installedAt': instance.installedAt.toIso8601String(),
      'firmwareVersion': instance.firmwareVersion,
      'isActive': instance.isActive,
      'settings': instance.settings,
    };

const _$IoTDeviceTypeEnumMap = {
  IoTDeviceType.smartOven: 'smartOven',
  IoTDeviceType.smartFridge: 'smartFridge',
  IoTDeviceType.smartLocker: 'smartLocker',
  IoTDeviceType.deliveryDrone: 'deliveryDrone',
  IoTDeviceType.smartScale: 'smartScale',
  IoTDeviceType.temperatureSensor: 'temperatureSensor',
  IoTDeviceType.humiditySensor: 'humiditySensor',
};

const _$IoTDeviceCategoryEnumMap = {
  IoTDeviceCategory.kitchen: 'kitchen',
  IoTDeviceCategory.delivery: 'delivery',
  IoTDeviceCategory.storage: 'storage',
  IoTDeviceCategory.monitoring: 'monitoring',
};

const _$IoTDeviceStatusEnumMap = {
  IoTDeviceStatus.online: 'online',
  IoTDeviceStatus.offline: 'offline',
  IoTDeviceStatus.maintenance: 'maintenance',
  IoTDeviceStatus.error: 'error',
};

IoTCommand _$IoTCommandFromJson(Map<String, dynamic> json) => IoTCommand(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      command: json['command'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      executed: json['executed'] as bool? ?? false,
      result: json['result'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$IoTCommandToJson(IoTCommand instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'command': instance.command,
      'parameters': instance.parameters,
      'timestamp': instance.timestamp.toIso8601String(),
      'executed': instance.executed,
      'result': instance.result,
      'error': instance.error,
    };

IoTAlert _$IoTAlertFromJson(Map<String, dynamic> json) => IoTAlert(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      alertType: json['alertType'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      acknowledged: json['acknowledged'] as bool? ?? false,
      severity: json['severity'] as String,
    );

Map<String, dynamic> _$IoTAlertToJson(IoTAlert instance) => <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'alertType': instance.alertType,
      'message': instance.message,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
      'acknowledged': instance.acknowledged,
      'severity': instance.severity,
    };
