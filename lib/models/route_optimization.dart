// Route Optimization Models for Efficient Delivery Management

import 'package:cloud_firestore/cloud_firestore.dart';

// Delivery Vehicle Types
enum VehicleType {
  bicycle,    // Fast, eco-friendly, low-cost
  motorcycle, // Fast, medium-cost
  car,        // Medium speed, weather-proof, high-capacity
  electricScooter, // Eco-friendly, fast, low-cost
  drone,      // Very fast, limited by weather and regulations
  robot,      // Autonomous delivery, future technology
}

// Optimization Algorithm Types
enum OptimizationAlgorithm {
  dijkstra,           // Shortest path
  aStar,             // Heuristic shortest path
  tspGenetic,        // Traveling Salesman Problem with Genetic Algorithm
  tspAntColony,      // Traveling Salesman Problem with Ant Colony
  vrpClarkeWright,   // Vehicle Routing Problem with Clarke-Wright
  vrpGenetic,        // Vehicle Routing Problem with Genetic Algorithm
  multiObjective,    // Multi-objective optimization
  machineLearning,   // ML-based route optimization
}

// Route Optimization Constraints
enum RouteConstraint {
  timeWindow,        // Time windows for deliveries
  capacity,          // Vehicle capacity constraints
  distance,          // Maximum distance limits
  traffic,           // Traffic condition considerations
  weather,           // Weather impact on routes
  regulations,       // Legal and regulatory constraints
  fuel,              // Fuel efficiency optimization
  cost,              // Cost minimization
  carbon,            // Carbon footprint reduction
  priority,          // Priority deliveries
}

// Route Status
enum RouteStatus {
  planning,          // Route being planned
  active,            // Route is active
  inProgress,        // Route is being executed
  completed,         // Route completed
  paused,            // Route paused
  cancelled,         // Route cancelled
  optimizationPending, // Route needs optimization
}

// Delivery Stop
class DeliveryStop {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String address;
  final double latitude;
  final double longitude;
  final String instructions;
  final DateTime requestedDeliveryTime;
  final DateTime? preferredTimeWindowStart;
  final DateTime? preferredTimeWindowEnd;
  final double weight; // Package weight
  final double volume; // Package volume
  final int priority; // 1-10, 10 = highest priority
  final bool isFragile;
  final bool requiresSignature;
  final List<String> specialInstructions;
  final Map<String, dynamic> metadata;
  final DateTime? estimatedArrival;
  final DateTime? actualArrival;
  String? status; // 'pending', 'in_transit', 'delivered', 'failed'
  final String? failureReason;

  DeliveryStop({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.instructions,
    required this.requestedDeliveryTime,
    this.preferredTimeWindowStart,
    this.preferredTimeWindowEnd,
    required this.weight,
    required this.volume,
    required this.priority,
    required this.isFragile,
    required this.requiresSignature,
    required this.specialInstructions,
    required this.metadata,
    this.estimatedArrival,
    this.actualArrival,
    this.status,
    this.failureReason,
  });

  factory DeliveryStop.fromJson(String id, Map<String, dynamic> json) {
    return DeliveryStop(
      id: id,
      orderId: json['orderId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      instructions: json['instructions'] ?? '',
      requestedDeliveryTime: DateTime.fromMillisecondsSinceEpoch(
          json['requestedDeliveryTime'] ?? 0),
      preferredTimeWindowStart: json['preferredTimeWindowStart'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['preferredTimeWindowStart'])
          : null,
      preferredTimeWindowEnd: json['preferredTimeWindowEnd'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['preferredTimeWindowEnd'])
          : null,
      weight: (json['weight'] ?? 0.0).toDouble(),
      volume: (json['volume'] ?? 0.0).toDouble(),
      priority: json['priority'] ?? 5,
      isFragile: json['isFragile'] ?? false,
      requiresSignature: json['requiresSignature'] ?? false,
      specialInstructions: List<String>.from(json['specialInstructions'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['estimatedArrival'])
          : null,
      actualArrival: json['actualArrival'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['actualArrival'])
          : null,
      status: json['status'],
      failureReason: json['failureReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'instructions': instructions,
      'requestedDeliveryTime': requestedDeliveryTime.millisecondsSinceEpoch,
      'preferredTimeWindowStart': preferredTimeWindowStart?.millisecondsSinceEpoch,
      'preferredTimeWindowEnd': preferredTimeWindowEnd?.millisecondsSinceEpoch,
      'weight': weight,
      'volume': volume,
      'priority': priority,
      'isFragile': isFragile,
      'requiresSignature': requiresSignature,
      'specialInstructions': specialInstructions,
      'metadata': metadata,
      'estimatedArrival': estimatedArrival?.millisecondsSinceEpoch,
      'actualArrival': actualArrival?.millisecondsSinceEpoch,
      'status': status,
      'failureReason': failureReason,
    };
  }

  // Check if delivery is on time
  bool get isOnTime => actualArrival == null || actualArrival!.isBefore(requestedDeliveryTime);
  
  // Check if delivery is late
  bool get isLate => actualArrival != null && actualArrival!.isAfter(requestedDeliveryTime);
  
  // Check if delivery is in time window
  bool get isInTimeWindow {
    final now = DateTime.now();
    if (preferredTimeWindowStart != null && now.isBefore(preferredTimeWindowStart!)) {
      return false;
    }
    if (preferredTimeWindowEnd != null && now.isAfter(preferredTimeWindowEnd!)) {
      return false;
    }
    return true;
  }

  // Create a copy of this DeliveryStop with optionally updated fields
  DeliveryStop copyWith({
    String? id,
    String? orderId,
    String? customerId,
    String? customerName,
    String? address,
    double? latitude,
    double? longitude,
    String? instructions,
    DateTime? requestedDeliveryTime,
    DateTime? preferredTimeWindowStart,
    DateTime? preferredTimeWindowEnd,
    double? weight,
    double? volume,
    int? priority,
    bool? isFragile,
    bool? requiresSignature,
    List<String>? specialInstructions,
    Map<String, dynamic>? metadata,
    DateTime? estimatedArrival,
    DateTime? actualArrival,
    String? status,
    String? failureReason,
  }) {
    return DeliveryStop(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      instructions: instructions ?? this.instructions,
      requestedDeliveryTime: requestedDeliveryTime ?? this.requestedDeliveryTime,
      preferredTimeWindowStart: preferredTimeWindowStart ?? this.preferredTimeWindowStart,
      preferredTimeWindowEnd: preferredTimeWindowEnd ?? this.preferredTimeWindowEnd,
      weight: weight ?? this.weight,
      volume: volume ?? this.volume,
      priority: priority ?? this.priority,
      isFragile: isFragile ?? this.isFragile,
      requiresSignature: requiresSignature ?? this.requiresSignature,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      metadata: metadata ?? this.metadata,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      actualArrival: actualArrival ?? this.actualArrival,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}

// Delivery Vehicle
class DeliveryVehicle {
  final String id;
  final String driverId;
  final String driverName;
  final VehicleType type;
  final double capacity; // Maximum load capacity
  final double volumeCapacity; // Volume capacity
  final double fuelEfficiency; // KM per liter or battery percentage
  final Map<String, double> currentLoad; // Current weight and volume
  final String? currentLocation; // Current GPS location
  final double? currentFuel; // Current fuel/battery level
  final bool isActive;
  final bool isAvailable;
  final DateTime lastMaintenance;
  final List<String> supportedAreas; // Geographic areas
  final double averageSpeed; // Average speed in different conditions
  final Map<String, dynamic> performanceMetrics;
  final List<String> capabilities; // Special capabilities
  final Map<String, dynamic> metadata;

  DeliveryVehicle({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.type,
    required this.capacity,
    required this.volumeCapacity,
    required this.fuelEfficiency,
    required this.currentLoad,
    this.currentLocation,
    this.currentFuel,
    required this.isActive,
    required this.isAvailable,
    required this.lastMaintenance,
    required this.supportedAreas,
    required this.averageSpeed,
    required this.performanceMetrics,
    required this.capabilities,
    required this.metadata,
  });

  factory DeliveryVehicle.fromJson(String id, Map<String, dynamic> json) {
    return DeliveryVehicle(
      id: id,
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      type: VehicleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VehicleType.bicycle,
      ),
      capacity: (json['capacity'] ?? 0.0).toDouble(),
      volumeCapacity: (json['volumeCapacity'] ?? 0.0).toDouble(),
      fuelEfficiency: (json['fuelEfficiency'] ?? 0.0).toDouble(),
      currentLoad: Map<String, double>.from({
        'weight': (json['currentLoad']?['weight'] ?? 0.0).toDouble(),
        'volume': (json['currentLoad']?['volume'] ?? 0.0).toDouble(),
      }),
      currentLocation: json['currentLocation'],
      currentFuel: json['currentFuel']?.toDouble(),
      isActive: json['isActive'] ?? true,
      isAvailable: json['isAvailable'] ?? true,
      lastMaintenance: DateTime.fromMillisecondsSinceEpoch(
          json['lastMaintenance'] ?? 0),
      supportedAreas: List<String>.from(json['supportedAreas'] ?? []),
      averageSpeed: (json['averageSpeed'] ?? 0.0).toDouble(),
      performanceMetrics: Map<String, dynamic>.from(json['performanceMetrics'] ?? {}),
      capabilities: List<String>.from(json['capabilities'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'type': type.name,
      'capacity': capacity,
      'volumeCapacity': volumeCapacity,
      'fuelEfficiency': fuelEfficiency,
      'currentLoad': currentLoad,
      'currentLocation': currentLocation,
      'currentFuel': currentFuel,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'lastMaintenance': lastMaintenance.millisecondsSinceEpoch,
      'supportedAreas': supportedAreas,
      'averageSpeed': averageSpeed,
      'performanceMetrics': performanceMetrics,
      'capabilities': capabilities,
      'metadata': metadata,
    };
  }

  // Check if vehicle can handle a delivery
  bool canHandleDelivery(DeliveryStop stop) {
    if (!isAvailable || !isActive) return false;
    
    final totalWeight = currentLoad['weight']! + stop.weight;
    final totalVolume = currentLoad['volume']! + stop.volume;
    
    return totalWeight <= capacity && totalVolume <= volumeCapacity;
  }
  
  // Check if vehicle supports the area
  bool supportsArea(double latitude, double longitude) {
    // Simple distance check (in real app, would use geographic areas)
    if (supportedAreas.isEmpty) return true;
    
    // This is a simplified check - in reality, would check against defined service areas
    return true;
  }
  
  // Calculate estimated delivery time for a stop
  Duration estimateDeliveryTime(DeliveryStop stop, Map<String, dynamic> trafficData) {
    // Simplified estimation based on distance and speed
    final distance = _calculateDistance(
      currentLocation ?? '0,0',
      '${stop.latitude},${stop.longitude}',
    );
    
    final baseSpeed = averageSpeed;
    final trafficFactor = _getTrafficFactor(trafficData);
    final speed = baseSpeed / trafficFactor;
    
    final timeInHours = distance / speed;
    return Duration(minutes: (timeInHours * 60).round());
  }
  
  double _calculateDistance(String from, String to) {
    // Simplified distance calculation
    return 5.0; // Mock distance in km
  }
  
  double _getTrafficFactor(Map<String, dynamic> trafficData) {
    // Simplified traffic factor
    return trafficData['density']?.toDouble() ?? 1.0;
  }
}

// Optimized Route
class OptimizedRoute {
  final String id;
  final String vehicleId;
  final String driverId;
  final DateTime createdAt;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  RouteStatus status;
  final List<DeliveryStop> stops;
  final List<String> stopOrder; // Order of delivery stops
  double totalDistance; // Total distance in km
  Duration estimatedDuration; // Estimated completion time
  final double fuelCostEstimate; // Estimated fuel cost
  final double carbonFootprintEstimate; // Carbon emissions estimate
  final OptimizationAlgorithm algorithmUsed;
  final Map<String, double> optimizationScores; // Optimization metrics
  final Map<String, dynamic> trafficData; // Traffic information
  final Map<String, dynamic> weatherData; // Weather information
  final List<RouteConstraint> constraints; // Constraints considered
  final Map<String, dynamic> metadata;

  OptimizedRoute({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.createdAt,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    required this.stops,
    required this.stopOrder,
    required this.totalDistance,
    required this.estimatedDuration,
    required this.fuelCostEstimate,
    required this.carbonFootprintEstimate,
    required this.algorithmUsed,
    required this.optimizationScores,
    required this.trafficData,
    required this.weatherData,
    required this.constraints,
    required this.metadata,
  });

  factory OptimizedRoute.fromJson(String id, Map<String, dynamic> json) {
    return OptimizedRoute(
      id: id,
      vehicleId: json['vehicleId'] ?? '',
      driverId: json['driverId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          json['createdAt'] ?? 0),
      scheduledStart: DateTime.fromMillisecondsSinceEpoch(
          json['scheduledStart'] ?? 0),
      scheduledEnd: DateTime.fromMillisecondsSinceEpoch(
          json['scheduledEnd'] ?? 0),
      status: RouteStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RouteStatus.planning,
      ),
      stops: (json['stops'] as List<dynamic>?)
          ?.map((e) => DeliveryStop.fromJson(e['id'] ?? '', e))
          .toList() ?? [],
      stopOrder: List<String>.from(json['stopOrder'] ?? []),
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      estimatedDuration: Duration(minutes: json['estimatedDuration'] ?? 0),
      fuelCostEstimate: (json['fuelCostEstimate'] ?? 0.0).toDouble(),
      carbonFootprintEstimate: (json['carbonFootprintEstimate'] ?? 0.0).toDouble(),
      algorithmUsed: OptimizationAlgorithm.values.firstWhere(
        (e) => e.name == json['algorithmUsed'],
        orElse: () => OptimizationAlgorithm.aStar,
      ),
      optimizationScores: Map<String, double>.from(json['optimizationScores'] ?? {}),
      trafficData: Map<String, dynamic>.from(json['trafficData'] ?? {}),
      weatherData: Map<String, dynamic>.from(json['weatherData'] ?? {}),
      constraints: (json['constraints'] as List<dynamic>?)
          ?.map((e) => RouteConstraint.values.firstWhere(
            (c) => c.name == e,
            orElse: () => RouteConstraint.distance,
          ))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'driverId': driverId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'scheduledStart': scheduledStart.millisecondsSinceEpoch,
      'scheduledEnd': scheduledEnd.millisecondsSinceEpoch,
      'status': status.name,
      'stops': stops.map((e) => e.toJson()).toList(),
      'stopOrder': stopOrder,
      'totalDistance': totalDistance,
      'estimatedDuration': estimatedDuration.inMinutes,
      'fuelCostEstimate': fuelCostEstimate,
      'carbonFootprintEstimate': carbonFootprintEstimate,
      'algorithmUsed': algorithmUsed.name,
      'optimizationScores': optimizationScores,
      'trafficData': trafficData,
      'weatherData': weatherData,
      'constraints': constraints.map((c) => c.name).toList(),
      'metadata': metadata,
    };
  }

  // Get current delivery stop
  DeliveryStop? get currentStop {
    if (stopOrder.isEmpty) return null;
    final currentStopId = stopOrder.first;
    return stops.firstWhere(
      (stop) => stop.id == currentStopId,
      orElse: () => throw Exception('Stop not found'),
    );
  }
  
  // Get next delivery stop
  DeliveryStop? get nextStop {
    if (stopOrder.length < 2) return null;
    final nextStopId = stopOrder[1];
    return stops.firstWhere(
      (stop) => stop.id == nextStopId,
      orElse: () => throw Exception('Stop not found'),
    );
  }
  
  // Calculate progress percentage
  double get progressPercentage {
    if (stopOrder.isEmpty) return 0.0;
    final deliveredStops = stops.where((stop) => stop.status == 'delivered').length;
    return (deliveredStops / stopOrder.length) * 100;
  }
  
  // Check if route is on time
  bool get isOnTime {
    final now = DateTime.now();
    if (status == RouteStatus.completed) {
      return now.isBefore(scheduledEnd) || scheduledEnd == DateTime(0);
    }
    return now.isBefore(scheduledEnd);
  }
  
  // Get estimated arrival for a stop
  DateTime? getEstimatedArrival(String stopId) {
    // Simplified estimation - in real app, would calculate based on route progress
    final stopIndex = stopOrder.indexOf(stopId);
    if (stopIndex == -1) return null;
    
    final avgStopTime = estimatedDuration.inMinutes / stopOrder.length;
    return scheduledStart.add(Duration(minutes: (stopIndex * avgStopTime).round()));
  }
}

// Route Optimization Request
class RouteOptimizationRequest {
  final String id;
  final String restaurantId;
  final List<String> deliveryStopIds;
  final List<DeliveryStop> stops;
  final List<String> availableVehicleIds;
  final List<DeliveryVehicle> vehicles;
  final OptimizationAlgorithm algorithm;
  final List<RouteConstraint> constraints;
  final Map<String, dynamic> optimizationWeights; // Weights for different objectives
  final DateTime requestedAt;
  final DateTime? deadline;
  final String priority; // 'low', 'medium', 'high', 'critical'
  final Map<String, dynamic> metadata;

  RouteOptimizationRequest({
    required this.id,
    required this.restaurantId,
    required this.deliveryStopIds,
    required this.stops,
    required this.availableVehicleIds,
    required this.vehicles,
    required this.algorithm,
    required this.constraints,
    required this.optimizationWeights,
    required this.requestedAt,
    this.deadline,
    required this.priority,
    required this.metadata,
  });

  factory RouteOptimizationRequest.fromJson(String id, Map<String, dynamic> json) {
    return RouteOptimizationRequest(
      id: id,
      restaurantId: json['restaurantId'] ?? '',
      deliveryStopIds: List<String>.from(json['deliveryStopIds'] ?? []),
      stops: (json['stops'] as List<dynamic>?)
          ?.map((e) => DeliveryStop.fromJson(e['id'] ?? '', e))
          .toList() ?? [],
      availableVehicleIds: List<String>.from(json['availableVehicleIds'] ?? []),
      vehicles: (json['vehicles'] as List<dynamic>?)
          ?.map((e) => DeliveryVehicle.fromJson(e['id'] ?? '', e))
          .toList() ?? [],
      algorithm: OptimizationAlgorithm.values.firstWhere(
        (e) => e.name == json['algorithm'],
        orElse: () => OptimizationAlgorithm.aStar,
      ),
      constraints: (json['constraints'] as List<dynamic>?)
          ?.map((e) => RouteConstraint.values.firstWhere(
            (c) => c.name == e,
            orElse: () => RouteConstraint.distance,
          ))
          .toList() ?? [],
      optimizationWeights: Map<String, double>.from(json['optimizationWeights'] ?? {}),
      requestedAt: DateTime.fromMillisecondsSinceEpoch(
          json['requestedAt'] ?? 0),
      deadline: json['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['deadline'])
          : null,
      priority: json['priority'] ?? 'medium',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'deliveryStopIds': deliveryStopIds,
      'stops': stops.map((e) => e.toJson()).toList(),
      'availableVehicleIds': availableVehicleIds,
      'vehicles': vehicles.map((e) => e.toJson()).toList(),
      'algorithm': algorithm.name,
      'constraints': constraints.map((c) => c.name).toList(),
      'optimizationWeights': optimizationWeights,
      'requestedAt': requestedAt.millisecondsSinceEpoch,
      'deadline': deadline?.millisecondsSinceEpoch,
      'priority': priority,
      'metadata': metadata,
    };
  }

  // Check if request is urgent
  bool get isUrgent {
    if (deadline == null) return false;
    final now = DateTime.now();
    final timeUntilDeadline = deadline!.difference(now);
    return timeUntilDeadline.inMinutes < 30; // Urgent if less than 30 minutes
  }
  
  // Check if request is feasible
  bool get isFeasible {
    if (stops.isEmpty || vehicles.isEmpty) return false;
    
    // Check if we have enough vehicles to handle all stops
    final totalWeight = stops.fold(0.0, (sum, stop) => sum + stop.weight);
    final totalVolume = stops.fold(0.0, (sum, stop) => sum + stop.volume);
    
    final availableCapacity = vehicles
        .where((v) => v.isAvailable && v.isActive)
        .fold(0.0, (sum, v) => sum + v.capacity);
    
    final availableVolumeCapacity = vehicles
        .where((v) => v.isAvailable && v.isActive)
        .fold(0.0, (sum, v) => sum + v.volumeCapacity);
    
    return totalWeight <= availableCapacity && totalVolume <= availableVolumeCapacity;
  }
}

// Real-time Traffic Data
class TrafficData {
  final String id;
  final String areaId; // Geographic area
  final double averageSpeed; // Current average speed in km/h
  final double congestionLevel; // 0.0 to 1.0
  final double accidentRisk; // 0.0 to 1.0
  final List<String> roadClosures;
  final List<String> constructionZones;
  final DateTime timestamp;
  final Map<String, dynamic> historicalData; // Historical patterns
  final String source; // Data source (Google, HERE, etc.)

  TrafficData({
    required this.id,
    required this.areaId,
    required this.averageSpeed,
    required this.congestionLevel,
    required this.accidentRisk,
    required this.roadClosures,
    required this.constructionZones,
    required this.timestamp,
    required this.historicalData,
    required this.source,
  });

  factory TrafficData.fromJson(String id, Map<String, dynamic> json) {
    return TrafficData(
      id: id,
      areaId: json['areaId'] ?? '',
      averageSpeed: (json['averageSpeed'] ?? 0.0).toDouble(),
      congestionLevel: (json['congestionLevel'] ?? 0.0).toDouble(),
      accidentRisk: (json['accidentRisk'] ?? 0.0).toDouble(),
      roadClosures: List<String>.from(json['roadClosures'] ?? []),
      constructionZones: List<String>.from(json['constructionZones'] ?? []),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] ?? 0),
      historicalData: Map<String, dynamic>.from(json['historicalData'] ?? {}),
      source: json['source'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'areaId': areaId,
      'averageSpeed': averageSpeed,
      'congestionLevel': congestionLevel,
      'accidentRisk': accidentRisk,
      'roadClosures': roadClosures,
      'constructionZones': constructionZones,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'historicalData': historicalData,
      'source': source,
    };
  }

  // Check if traffic conditions are good
  bool get isGoodTraffic => congestionLevel < 0.3;
  
  // Check if traffic conditions are poor
  bool get isPoorTraffic => congestionLevel > 0.7;
  
  // Get traffic impact factor for route planning
  double get trafficFactor {
    if (congestionLevel < 0.3) return 1.0;
    if (congestionLevel < 0.7) return 1.5;
    return 2.0;
  }
}

// Route Analytics
class RouteAnalytics {
  final String id;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String? restaurantId;
  final int totalRoutes;
  final int completedRoutes;
  final int onTimeDeliveries;
  final int lateDeliveries;
  final double averageDeliveryTime;
  final double averageDistance;
  final double totalDistance;
  final double totalFuelCost;
  final double totalCarbonEmissions;
  final double averageDriverEfficiency;
  final Map<String, int> algorithmUsage;
  final Map<String, int> vehicleTypeUsage;
  final Map<String, double> performanceMetrics;
  final List<String> commonDelays;
  final Map<String, dynamic> customerSatisfaction;
  final List<String> recommendations;
  final Map<String, dynamic> metadata;

  RouteAnalytics({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    this.restaurantId,
    required this.totalRoutes,
    required this.completedRoutes,
    required this.onTimeDeliveries,
    required this.lateDeliveries,
    required this.averageDeliveryTime,
    required this.averageDistance,
    required this.totalDistance,
    required this.totalFuelCost,
    required this.totalCarbonEmissions,
    required this.averageDriverEfficiency,
    required this.algorithmUsage,
    required this.vehicleTypeUsage,
    required this.performanceMetrics,
    required this.commonDelays,
    required this.customerSatisfaction,
    required this.recommendations,
    required this.metadata,
  });

  factory RouteAnalytics.fromJson(String id, Map<String, dynamic> json) {
    return RouteAnalytics(
      id: id,
      periodStart: DateTime.fromMillisecondsSinceEpoch(
          json['periodStart'] ?? 0),
      periodEnd: DateTime.fromMillisecondsSinceEpoch(
          json['periodEnd'] ?? 0),
      restaurantId: json['restaurantId'],
      totalRoutes: json['totalRoutes'] ?? 0,
      completedRoutes: json['completedRoutes'] ?? 0,
      onTimeDeliveries: json['onTimeDeliveries'] ?? 0,
      lateDeliveries: json['lateDeliveries'] ?? 0,
      averageDeliveryTime: (json['averageDeliveryTime'] ?? 0.0).toDouble(),
      averageDistance: (json['averageDistance'] ?? 0.0).toDouble(),
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      totalFuelCost: (json['totalFuelCost'] ?? 0.0).toDouble(),
      totalCarbonEmissions: (json['totalCarbonEmissions'] ?? 0.0).toDouble(),
      averageDriverEfficiency: (json['averageDriverEfficiency'] ?? 0.0).toDouble(),
      algorithmUsage: Map<String, int>.from(json['algorithmUsage'] ?? {}),
      vehicleTypeUsage: Map<String, int>.from(json['vehicleTypeUsage'] ?? {}),
      performanceMetrics: Map<String, double>.from(json['performanceMetrics'] ?? {}),
      commonDelays: List<String>.from(json['commonDelays'] ?? []),
      customerSatisfaction: Map<String, dynamic>.from(json['customerSatisfaction'] ?? {}),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodStart': periodStart.millisecondsSinceEpoch,
      'periodEnd': periodEnd.millisecondsSinceEpoch,
      'restaurantId': restaurantId,
      'totalRoutes': totalRoutes,
      'completedRoutes': completedRoutes,
      'onTimeDeliveries': onTimeDeliveries,
      'lateDeliveries': lateDeliveries,
      'averageDeliveryTime': averageDeliveryTime,
      'averageDistance': averageDistance,
      'totalDistance': totalDistance,
      'totalFuelCost': totalFuelCost,
      'totalCarbonEmissions': totalCarbonEmissions,
      'averageDriverEfficiency': averageDriverEfficiency,
      'algorithmUsage': algorithmUsage,
      'vehicleTypeUsage': vehicleTypeUsage,
      'performanceMetrics': performanceMetrics,
      'commonDelays': commonDelays,
      'customerSatisfaction': customerSatisfaction,
      'recommendations': recommendations,
      'metadata': metadata,
    };
  }

  // Calculate key performance indicators
  double get onTimeDeliveryRate {
    if (totalRoutes == 0) return 0.0;
    return (onTimeDeliveries / totalRoutes) * 100;
  }
  
  double get completionRate {
    if (totalRoutes == 0) return 0.0;
    return (completedRoutes / totalRoutes) * 100;
  }
  
  double get lateDeliveryRate {
    if (totalRoutes == 0) return 0.0;
    return (lateDeliveries / totalRoutes) * 100;
  }
  
  double get fuelEfficiency {
    if (totalDistance == 0) return 0.0;
    return totalDistance / totalFuelCost;
  }
  
  double get carbonEfficiency {
    if (totalDistance == 0) return 0.0;
    return totalDistance / totalCarbonEmissions;
  }
}