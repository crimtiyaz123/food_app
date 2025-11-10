import 'package:json_annotation/json_annotation.dart';

part 'iot_device.g.dart';

enum IoTDeviceType {
  smartOven,
  smartFridge,
  smartLocker,
  deliveryDrone,
  smartScale,
  temperatureSensor,
  humiditySensor,
}

enum IoTDeviceStatus {
  online,
  offline,
  maintenance,
  error,
}

enum IoTDeviceCategory {
  kitchen,
  delivery,
  storage,
  monitoring,
}

@JsonSerializable()
class IoTDevice {
  final String id;
  final String name;
  final IoTDeviceType type;
  final IoTDeviceCategory category;
  final String restaurantId;
  final String? locationId; // For delivery devices
  final IoTDeviceStatus status;
  final Map<String, dynamic> capabilities;
  final Map<String, dynamic> currentReadings;
  final DateTime lastSeen;
  final DateTime installedAt;
  final String firmwareVersion;
  final bool isActive;
  final Map<String, dynamic>? settings;

  IoTDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.restaurantId,
    this.locationId,
    required this.status,
    required this.capabilities,
    required this.currentReadings,
    required this.lastSeen,
    required this.installedAt,
    required this.firmwareVersion,
    this.isActive = true,
    this.settings,
  });

  factory IoTDevice.fromJson(Map<String, dynamic> json) =>
      _$IoTDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$IoTDeviceToJson(this);

  IoTDevice copyWith({
    String? id,
    String? name,
    IoTDeviceType? type,
    IoTDeviceCategory? category,
    String? restaurantId,
    String? locationId,
    IoTDeviceStatus? status,
    Map<String, dynamic>? capabilities,
    Map<String, dynamic>? currentReadings,
    DateTime? lastSeen,
    DateTime? installedAt,
    String? firmwareVersion,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return IoTDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      restaurantId: restaurantId ?? this.restaurantId,
      locationId: locationId ?? this.locationId,
      status: status ?? this.status,
      capabilities: capabilities ?? this.capabilities,
      currentReadings: currentReadings ?? this.currentReadings,
      lastSeen: lastSeen ?? this.lastSeen,
      installedAt: installedAt ?? this.installedAt,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }
}

@JsonSerializable()
class IoTCommand {
  final String id;
  final String deviceId;
  final String command;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final bool executed;
  final String? result;
  final String? error;

  IoTCommand({
    required this.id,
    required this.deviceId,
    required this.command,
    required this.parameters,
    required this.timestamp,
    this.executed = false,
    this.result,
    this.error,
  });

  factory IoTCommand.fromJson(Map<String, dynamic> json) =>
      _$IoTCommandFromJson(json);

  Map<String, dynamic> toJson() => _$IoTCommandToJson(this);
}

@JsonSerializable()
class IoTAlert {
  final String id;
  final String deviceId;
  final String alertType;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool acknowledged;
  final String severity; // 'low', 'medium', 'high', 'critical'

  IoTAlert({
    required this.id,
    required this.deviceId,
    required this.alertType,
    required this.message,
    required this.data,
    required this.timestamp,
    this.acknowledged = false,
    required this.severity,
  });

  factory IoTAlert.fromJson(Map<String, dynamic> json) =>
      _$IoTAlertFromJson(json);

  Map<String, dynamic> toJson() => _$IoTAlertToJson(this);
}
