import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/iot_device.dart';
import '../utils/logger.dart';

class IoTService {
  static final IoTService _instance = IoTService._internal();
  factory IoTService() => _instance;
  IoTService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MqttServerClient? _mqttClient;
  final StreamController<IoTDevice> _deviceUpdatesController = StreamController<IoTDevice>.broadcast();
  final StreamController<IoTAlert> _alertsController = StreamController<IoTAlert>.broadcast();

  Stream<IoTDevice> get deviceUpdates => _deviceUpdatesController.stream;
  Stream<IoTAlert> get alerts => _alertsController.stream;

  // MQTT Configuration
  static const String mqttServer = 'your-mqtt-server.com';
  static const int mqttPort = 1883;
  static const String mqttClientId = 'food_app_iot_client';

  Future<void> initialize() async {
    await _initializeMQTT();
    await _initializeBluetooth();
    _startDeviceMonitoring();
  }

  Future<void> _initializeMQTT() async {
    _mqttClient = MqttServerClient(mqttServer, mqttClientId);
    _mqttClient!.port = mqttPort;
    _mqttClient!.keepAlivePeriod = 20;

    try {
      await _mqttClient!.connect();
    } catch (e) {
      AppLogger.error('MQTT Connection failed', e);
    }
  }

  Future<void> _initializeBluetooth() async {
    // Initialize Bluetooth for local IoT device discovery
    try {
      if (await FlutterBluePlus.isSupported == false) {
        AppLogger.info('Bluetooth not supported on this device');
        return;
      }

      FlutterBluePlus.setLogLevel(LogLevel.info, color: true);
    } catch (e) {
      AppLogger.error('Bluetooth initialization failed', e);
    }
  }

  void _startDeviceMonitoring() {
    // Monitor device status and readings
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkDeviceStatuses();
    });
  }

  Future<void> _checkDeviceStatuses() async {
    try {
      final devices = await getDevices();
      for (final device in devices) {
        if (device.status == IoTDeviceStatus.online) {
          await _updateDeviceReadings(device);
        }
      }
    } catch (e) {
      AppLogger.error('Device status check failed', e);
    }
  }

  Future<List<IoTDevice>> getDevices({String? restaurantId}) async {
    try {
      final query = _firestore.collection('iot_devices');
      var filteredQuery = query.where('isActive', isEqualTo: true);

      if (restaurantId != null) {
        filteredQuery = filteredQuery.where('restaurantId', isEqualTo: restaurantId);
      }

      final snapshot = await filteredQuery.get();
      return snapshot.docs.map((doc) => IoTDevice.fromJson(doc.data())).toList();
    } catch (e) {
      AppLogger.error('Failed to get IoT devices', e);
      return [];
    }
  }

  Future<void> registerDevice(IoTDevice device) async {
    try {
      await _firestore
          .collection('iot_devices')
          .doc(device.id)
          .set(device.toJson());

      // Subscribe to device MQTT topics
      if (_mqttClient?.connectionStatus?.state == MqttConnectionState.connected) {
        _mqttClient!.subscribe('iot/devices/${device.id}/status', MqttQos.atLeastOnce);
        _mqttClient!.subscribe('iot/devices/${device.id}/readings', MqttQos.atLeastOnce);
        _mqttClient!.subscribe('iot/devices/${device.id}/alerts', MqttQos.atLeastOnce);
      }

      AppLogger.info('IoT device registered: ${device.name}');
    } catch (e) {
      AppLogger.error('Failed to register IoT device', e);
      rethrow;
    }
  }

  Future<void> updateDevice(IoTDevice device) async {
    try {
      await _firestore
          .collection('iot_devices')
          .doc(device.id)
          .update(device.toJson());

      _deviceUpdatesController.add(device);
      AppLogger.info('IoT device updated: ${device.name}');
    } catch (e) {
      AppLogger.error('Failed to update IoT device', e);
      rethrow;
    }
  }

  Future<void> sendCommand(IoTCommand command) async {
    try {
      // Send command via MQTT
      if (_mqttClient?.connectionStatus?.state == MqttConnectionState.connected) {
        final builder = MqttClientPayloadBuilder();
        builder.addString(jsonEncode(command.toJson()));
        _mqttClient!.publishMessage(
          'iot/devices/${command.deviceId}/commands',
          MqttQos.atLeastOnce,
          builder.payload!,
        );
      }

      // Store command in Firestore
      await _firestore
          .collection('iot_commands')
          .doc(command.id)
          .set(command.toJson());

      AppLogger.info('IoT command sent: ${command.command} to device ${command.deviceId}');
    } catch (e) {
      AppLogger.error('Failed to send IoT command', e);
      rethrow;
    }
  }

  Future<void> _updateDeviceReadings(IoTDevice device) async {
    try {
      // Simulate reading updates from MQTT or Bluetooth
      // In real implementation, this would come from device sensors
      final updatedReadings = await _fetchDeviceReadings(device);

      if (updatedReadings != null) {
        final updatedDevice = device.copyWith(
          currentReadings: updatedReadings,
          lastSeen: DateTime.now(),
        );

        await updateDevice(updatedDevice);

        // Check for alerts based on readings
        await _checkForAlerts(updatedDevice);
      }
    } catch (e) {
      AppLogger.error('Failed to update device readings', e);
    }
  }

  Future<Map<String, dynamic>?> _fetchDeviceReadings(IoTDevice device) async {
    // In real implementation, this would fetch from MQTT or Bluetooth
    // For now, return simulated data
    switch (device.type) {
      case IoTDeviceType.smartOven:
        return {
          'temperature': 180 + (DateTime.now().second % 20),
          'timer': 25,
          'status': 'heating',
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      case IoTDeviceType.smartFridge:
        return {
          'temperature': 4 + (DateTime.now().second % 3),
          'humidity': 45 + (DateTime.now().second % 10),
          'doorOpen': false,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      case IoTDeviceType.deliveryDrone:
        return {
          'batteryLevel': 85 - (DateTime.now().second % 20),
          'altitude': 50,
          'speed': 25,
          'location': {'lat': 37.7749, 'lng': -122.4194},
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      default:
        return null;
    }
  }

  Future<void> _checkForAlerts(IoTDevice device) async {
    final readings = device.currentReadings;

    switch (device.type) {
      case IoTDeviceType.smartOven:
        final temp = readings['temperature'] as num?;
        if (temp != null && temp > 220) {
          final alert = IoTAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            deviceId: device.id,
            alertType: 'temperature_high',
            message: 'Oven temperature too high: $temp°C',
            data: readings,
            timestamp: DateTime.now(),
            severity: 'high',
          );
          _alertsController.add(alert);
        }
        break;
      case IoTDeviceType.smartFridge:
        final temp = readings['temperature'] as num?;
        if (temp != null && temp > 8) {
          final alert = IoTAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            deviceId: device.id,
            alertType: 'temperature_high',
            message: 'Fridge temperature too high: $temp°C',
            data: readings,
            timestamp: DateTime.now(),
            severity: 'critical',
          );
          _alertsController.add(alert);
        }
        break;
      case IoTDeviceType.deliveryDrone:
        final battery = readings['batteryLevel'] as num?;
        if (battery != null && battery < 20) {
          final alert = IoTAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            deviceId: device.id,
            alertType: 'battery_low',
            message: 'Drone battery low: $battery%',
            data: readings,
            timestamp: DateTime.now(),
            severity: 'high',
          );
          _alertsController.add(alert);
        }
        break;
      default:
        break;
    }
  }

  Future<List<IoTAlert>> getAlerts({String? deviceId, bool onlyUnacknowledged = true}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('iot_alerts');

      if (deviceId != null) {
        query = query.where('deviceId', isEqualTo: deviceId);
      }

      if (onlyUnacknowledged) {
        query = query.where('acknowledged', isEqualTo: false);
      }

      final snapshot = await query.orderBy('timestamp', descending: true).get();
      return snapshot.docs.map((doc) => IoTAlert.fromJson(doc.data())).toList();
    } catch (e) {
      AppLogger.error('Failed to get IoT alerts', e);
      return [];
    }
  }

  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await _firestore
          .collection('iot_alerts')
          .doc(alertId)
          .update({'acknowledged': true});
    } catch (e) {
      AppLogger.error('Failed to acknowledge alert', e);
      rethrow;
    }
  }



  Future<void> dispose() async {
    _mqttClient?.disconnect();
    _deviceUpdatesController.close();
    _alertsController.close();
  }
}
