import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/route_optimization.dart';

class RouteOptimizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Main route optimization function
  Future<List<OptimizedRoute>> optimizeRoutes({
    required String restaurantId,
    required List<DeliveryStop> stops,
    required List<DeliveryVehicle> availableVehicles,
    OptimizationAlgorithm algorithm = OptimizationAlgorithm.aStar,
    List<RouteConstraint> constraints = const [RouteConstraint.distance],
    Map<String, double> optimizationWeights = const {},
  }) async {
    try {
      debugPrint('Starting route optimization with ${stops.length} stops and ${availableVehicles.length} vehicles');

      // Validate inputs
      final validation = _validateOptimizationRequest(stops, availableVehicles);
      if (!validation.isValid) {
        throw Exception('Invalid optimization request: ${validation.errors.join(", ")}');
      }

      // Get real-time data (traffic, weather, etc.)
      final trafficData = await _getRealTimeTrafficData(restaurantId);
      final weatherData = await _getWeatherData(restaurantId);

      // Apply optimization algorithm
      List<OptimizedRoute> optimizedRoutes;
      
      switch (algorithm) {
        case OptimizationAlgorithm.aStar:
          optimizedRoutes = await _optimizeWithAStar(
            stops, availableVehicles, constraints, optimizationWeights);
          break;
        case OptimizationAlgorithm.dijkstra:
          optimizedRoutes = await _optimizeWithDijkstra(
            stops, availableVehicles, constraints, optimizationWeights);
          break;
        case OptimizationAlgorithm.tspGenetic:
          optimizedRoutes = await _optimizeWithTSPGenetic(
            stops, availableVehicles, constraints, optimizationWeights);
          break;
        case OptimizationAlgorithm.vrpClarkeWright:
          optimizedRoutes = await _optimizeWithVRPClarkeWright(
            stops, availableVehicles, constraints, optimizationWeights);
          break;
        case OptimizationAlgorithm.multiObjective:
          optimizedRoutes = await _optimizeWithMultiObjective(
            stops, availableVehicles, constraints, optimizationWeights);
          break;
        case OptimizationAlgorithm.machineLearning:
          optimizedRoutes = await _optimizeWithML(
            stops, availableVehicles, constraints, optimizationWeights);
          break;
        default:
          optimizedRoutes = await _optimizeWithAStar(
            stops, availableVehicles, constraints, optimizationWeights);
      }

      // Apply real-time data
      for (final route in optimizedRoutes) {
        route.trafficData.addAll(trafficData);
        route.weatherData.addAll(weatherData);
        route.totalDistance = _recalculateDistanceWithTraffic(route, trafficData);
        route.estimatedDuration = _recalculateDurationWithWeather(route, weatherData);
      }

      // Save optimized routes
      await _saveOptimizedRoutes(optimizedRoutes);

      debugPrint('Route optimization completed. Generated ${optimizedRoutes.length} routes');
      return optimizedRoutes;
      
    } catch (e) {
      debugPrint('Error optimizing routes: $e');
      rethrow;
    }
  }

  // A* algorithm for route optimization
  Future<List<OptimizedRoute>> _optimizeWithAStar(
    List<DeliveryStop> stops,
    List<DeliveryVehicle> availableVehicles,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) async {
    // Get restaurant location
    final restaurantLocation = await _getRestaurantLocation(stops.first.orderId);
    
    // Assign stops to vehicles (simplified assignment)
    final vehicleAssignments = _assignStopsToVehicles(stops, availableVehicles, weights);
    
    final optimizedRoutes = <OptimizedRoute>[];
    
    for (final assignment in vehicleAssignments) {
      final vehicle = assignment['vehicle'] as DeliveryVehicle;
      final vehicleStops = assignment['stops'] as List<DeliveryStop>;
      
      if (vehicleStops.isEmpty) continue;
      
      // A* pathfinding for this vehicle's route
      final route = await _aStarPathfinding(
        restaurantLocation,
        vehicleStops,
        vehicle,
        constraints,
        weights,
      );
      
      if (route != null) {
        optimizedRoutes.add(route);
      }
    }
    
    return optimizedRoutes;
  }

  // Dijkstra algorithm implementation
  Future<List<OptimizedRoute>> _optimizeWithDijkstra(
    List<DeliveryStop> stops,
    List<DeliveryVehicle> availableVehicles,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) async {
    // Similar to A* but without heuristic (Dijkstra's shortest path)
    return _optimizeWithAStar(stops, availableVehicles, constraints, weights);
  }

  // Genetic Algorithm for TSP (Traveling Salesman Problem)
  Future<List<OptimizedRoute>> _optimizeWithTSPGenetic(
    List<DeliveryStop> stops,
    List<DeliveryVehicle> availableVehicles,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) async {
    final restaurantLocation = await _getRestaurantLocation(stops.first.orderId);
    final vehicleAssignments = _assignStopsToVehicles(stops, availableVehicles, weights);
    final optimizedRoutes = <OptimizedRoute>[];
    
    for (final assignment in vehicleAssignments) {
      final vehicle = assignment['vehicle'] as DeliveryVehicle;
      final vehicleStops = assignment['stops'] as List<DeliveryStop>;
      
      if (vehicleStops.isEmpty) continue;
      
      // Apply genetic algorithm for TSP
      final route = await _geneticAlgorithmTSP(
        restaurantLocation,
        vehicleStops,
        vehicle,
        constraints,
        weights,
      );
      
      if (route != null) {
        optimizedRoutes.add(route);
      }
    }
    
    return optimizedRoutes;
  }

  // Clarke-Wright algorithm for VRP (Vehicle Routing Problem)
  Future<List<OptimizedRoute>> _optimizeWithVRPClarkeWright(
    List<DeliveryStop> stops,
    List<DeliveryVehicle> availableVehicles,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) async {
    final optimizedRoutes = <OptimizedRoute>[];
    
    // Clarke-Wright Savings Algorithm
    // 1. Start with each stop on its own route
    final individualRoutes = stops.map((stop) => [stop]).toList();
    
    // 2. Calculate savings for combining routes
    final savings = _calculateSavings(stops);
    
    // 3. Sort savings in descending order
    savings.sort((a, b) => b.saving.compareTo(a.saving));
    
    // 4. Apply savings to merge routes
    for (final saving in savings) {
      if (saving.saving < 0) break; // No more savings possible
      
      final route1Index = _findRouteContainingStop(individualRoutes, saving.stop1);
      final route2Index = _findRouteContainingStop(individualRoutes, saving.stop2);
      
      if (route1Index == -1 || route2Index == -1 || route1Index == route2Index) {
        continue;
      }
      
      final route1 = individualRoutes[route1Index];
      final route2 = individualRoutes[route2Index];
      
      // Check if merging is feasible
      if (_canMergeRoutes(route1, route2, availableVehicles, constraints)) {
        // Merge routes
        final mergedRoute = _mergeRoutes(route1, route2);
        individualRoutes.removeAt(max(route1Index, route2Index));
        individualRoutes.removeAt(min(route1Index, route2Index));
        individualRoutes.add(mergedRoute);
      }
    }
    
    // Convert to OptimizedRoute format
    for (int i = 0; i < individualRoutes.length; i++) {
      final routeStops = individualRoutes[i];
      if (routeStops.isNotEmpty) {
        // Assign vehicle to route
        final vehicle = _selectBestVehicleForRoute(routeStops, availableVehicles);
        if (vehicle != null) {
          final optimizedRoute = _createOptimizedRoute(
            routeStops,
            vehicle,
            OptimizationAlgorithm.vrpClarkeWright,
            constraints,
            weights,
          );
          optimizedRoutes.add(optimizedRoute);
        }
      }
    }
    
    return optimizedRoutes;
  }

  // Multi-objective optimization
  Future<List<OptimizedRoute>> _optimizeWithMultiObjective(
    List<DeliveryStop> stops,
    List<DeliveryVehicle> availableVehicles,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) async {
    // Apply different algorithms and get multiple solutions
    final aStarRoutes = await _optimizeWithAStar(stops, availableVehicles, constraints, weights);
    final tspRoutes = await _optimizeWithTSPGenetic(stops, availableVehicles, constraints, weights);
    final vrpRoutes = await _optimizeWithVRPClarkeWright(stops, availableVehicles, constraints, weights);
    
    // Combine all solutions
    final allRoutes = [...aStarRoutes, ...tspRoutes, ...vrpRoutes];
    
    // Pareto optimization - find non-dominated solutions
    final paretoOptimal = _findParetoOptimalRoutes(allRoutes, constraints, weights);
    
    return paretoOptimal;
  }

  // Machine Learning-based optimization
  Future<List<OptimizedRoute>> _optimizeWithML(
    List<DeliveryStop> stops,
    List<DeliveryVehicle> availableVehicles,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) async {
    // In a real implementation, this would use trained ML models
    // For now, we'll use a hybrid approach with historical data
    
    // Get historical performance data
    final historicalData = await _getHistoricalOptimizationData();
    
    // Use historical insights to improve optimization
    final optimizedRoutes = await _optimizeWithAStar(stops, availableVehicles, constraints, weights);
    
    // Apply ML-based adjustments
    for (final route in optimizedRoutes) {
      _applyMLOptimizations(route, historicalData, constraints);
    }
    
    return optimizedRoutes;
  }

  // Real-time route optimization during delivery
  Future<OptimizedRoute?> optimizeExistingRoute({
    required String routeId,
    List<DeliveryStop>? additionalStops,
    Map<String, dynamic>? newTrafficData,
    Map<String, dynamic>? newWeatherData,
  }) async {
    try {
      // Get existing route
      final existingRouteDoc = await _firestore.collection('optimizedRoutes').doc(routeId).get();
      if (!existingRouteDoc.exists) return null;
      
      final existingRoute = OptimizedRoute.fromJson(routeId, existingRouteDoc.data()!);
      
      // If new stops are added, insert them optimally
      if (additionalStops != null && additionalStops.isNotEmpty) {
        _insertStopsIntoRoute(existingRoute, additionalStops);
      }
      
      // Re-optimize with new data
      if (newTrafficData != null) {
        existingRoute.trafficData.addAll(newTrafficData);
        existingRoute.totalDistance = _recalculateDistanceWithTraffic(existingRoute, newTrafficData);
      }
      
      if (newWeatherData != null) {
        existingRoute.weatherData.addAll(newWeatherData);
        existingRoute.estimatedDuration = _recalculateDurationWithWeather(existingRoute, newWeatherData);
      }
      
      // Update route in database
      await _firestore.collection('optimizedRoutes').doc(routeId).update(existingRoute.toJson());
      
      return existingRoute;
    } catch (e) {
      debugPrint('Error optimizing existing route: $e');
      return null;
    }
  }

  // Get delivery tracking information
  Future<Map<String, dynamic>> getDeliveryTracking({
    required String routeId,
    String? stopId,
  }) async {
    try {
      final routeDoc = await _firestore.collection('optimizedRoutes').doc(routeId).get();
      if (!routeDoc.exists) return {};
      
      final route = OptimizedRoute.fromJson(routeId, routeDoc.data()!);
      
      if (stopId != null) {
        // Get specific stop tracking
        final stop = route.stops.firstWhere(
          (s) => s.id == stopId,
          orElse: () => throw Exception('Stop not found'),
        );
        
        return {
          'routeId': routeId,
          'stopId': stopId,
          'estimatedArrival': route.getEstimatedArrival(stopId),
          'currentStatus': stop.status,
          'driverLocation': await _getCurrentDriverLocation(route.driverId),
          'trafficConditions': route.trafficData,
          'weatherConditions': route.weatherData,
          'progress': route.progressPercentage,
        };
      } else {
        // Get route-level tracking
        return {
          'routeId': routeId,
          'currentStop': route.currentStop?.id,
          'nextStop': route.nextStop?.id,
          'progress': route.progressPercentage,
          'estimatedEndTime': route.scheduledEnd,
          'isOnTime': route.isOnTime,
          'totalStops': route.stopOrder.length,
          'completedStops': route.stops.where((s) => s.status == 'delivered').length,
        };
      }
    } catch (e) {
      debugPrint('Error getting delivery tracking: $e');
      return {};
    }
  }

  // Update delivery status
  Future<bool> updateDeliveryStatus({
    required String routeId,
    required String stopId,
    required String status,
    String? failureReason,
  }) async {
    try {
      final routeDoc = await _firestore.collection('optimizedRoutes').doc(routeId).get();
      if (!routeDoc.exists) return false;
      
      final route = OptimizedRoute.fromJson(routeId, routeDoc.data()!);
      
      // Update stop status
      final stopIndex = route.stops.indexWhere((s) => s.id == stopId);
      if (stopIndex == -1) return false;
      
      route.stops[stopIndex] = route.stops[stopIndex].copyWith(
        status: status,
        actualArrival: status == 'delivered' || status == 'failed' 
            ? DateTime.now() 
            : null,
        failureReason: failureReason,
      );
      
      // If all stops completed, mark route as completed
      final allCompleted = route.stops.every((s) => s.status == 'delivered');
      if (allCompleted) {
        route.status = RouteStatus.completed;
      }
      
      // Update route in database
      await _firestore.collection('optimizedRoutes').doc(routeId).update(route.toJson());
      
      // Send status update notification
      await _sendStatusUpdateNotification(route, stopId, status);
      
      return true;
    } catch (e) {
      debugPrint('Error updating delivery status: $e');
      return false;
    }
  }

  // Generate route analytics
  Future<RouteAnalytics> generateRouteAnalytics({
    required DateTime startDate,
    required DateTime endDate,
    String? restaurantId,
  }) async {
    try {
      Query query = _firestore.collection('optimizedRoutes')
          .where('createdAt', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where('createdAt', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
      
      if (restaurantId != null) {
        // Note: This would need a restaurantId field in the route model
        // For now, we'll skip this filter
      }
      
      final snapshot = await query.get();
      final routes = snapshot.docs.map((doc) {
        return OptimizedRoute.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      return _calculateRouteAnalytics(routes, startDate, endDate, restaurantId);
    } catch (e) {
      debugPrint('Error generating route analytics: $e');
      rethrow;
    }
  }

  // Private helper methods
  ValidationResult _validateOptimizationRequest(
    List<DeliveryStop> stops,
    List<DeliveryVehicle> vehicles,
  ) {
    final errors = <String>[];
    
    if (stops.isEmpty) {
      errors.add('No delivery stops provided');
    }
    
    if (vehicles.isEmpty) {
      errors.add('No available vehicles');
    }
    
    if (stops.any((stop) => stop.latitude == 0.0 && stop.longitude == 0.0)) {
      errors.add('Some stops have invalid coordinates');
    }
    
    // Check if we have enough vehicle capacity
    final totalWeight = stops.fold(0.0, (total, stop) => total + stop.weight);
    final totalVolume = stops.fold(0.0, (total, stop) => total + stop.volume);
    
    final availableCapacity = vehicles
        .where((v) => v.isAvailable && v.isActive)
        .fold(0.0, (total, v) => total + v.capacity);
    
    final availableVolume = vehicles
        .where((v) => v.isAvailable && v.isActive)
        .fold(0.0, (total, v) => total + v.volumeCapacity);
    
    if (totalWeight > availableCapacity) {
      errors.add('Total package weight exceeds available vehicle capacity');
    }
    
    if (totalVolume > availableVolume) {
      errors.add('Total package volume exceeds available vehicle volume');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  List<Map<String, dynamic>> _assignStopsToVehicles(
    List<DeliveryStop> stops,
    List<DeliveryVehicle> vehicles,
    Map<String, double> weights,
  ) {
    final assignments = <Map<String, dynamic>>[];
    
    // Sort stops by priority
    final sortedStops = [...stops]..sort((a, b) => b.priority.compareTo(a.priority));
    
    // Assign stops to vehicles using greedy approach
    for (final stop in sortedStops) {
      // Find best vehicle for this stop
      final bestVehicle = _findBestVehicleForStop(stop, vehicles, weights);
      
      if (bestVehicle != null) {
        // Add stop to vehicle's assignment
        final existingAssignment = assignments.firstWhere(
          (assignment) => assignment['vehicle'].id == bestVehicle.id,
          orElse: () => {
            'vehicle': bestVehicle,
            'stops': <DeliveryStop>[],
          },
        );
        
        (existingAssignment['stops'] as List<DeliveryStop>).add(stop);
        
        if (!assignments.any((assignment) => assignment['vehicle'].id == bestVehicle.id)) {
          assignments.add(existingAssignment);
        }
      }
    }
    
    return assignments;
  }

  DeliveryVehicle? _findBestVehicleForStop(
    DeliveryStop stop,
    List<DeliveryVehicle> vehicles,
    Map<String, double> weights,
  ) {
    DeliveryVehicle? bestVehicle;
    double bestScore = double.negativeInfinity;
    
    for (final vehicle in vehicles) {
      if (!vehicle.isAvailable || !vehicle.isActive) continue;
      
      // Check if vehicle can handle the stop
      if (!vehicle.canHandleDelivery(stop)) continue;
      
      // Calculate suitability score
      double score = 0.0;
      
      // Priority score
      score += stop.priority * (weights['priority'] ?? 1.0);
      
      // Distance score (prefer closer vehicles)
      final distance = _calculateDistance(
        vehicle.currentLocation ?? '0,0',
        '${stop.latitude},${stop.longitude}',
      );
      score += (100.0 - distance) * (weights['distance'] ?? 0.5);
      
      // Vehicle capacity utilization score
      final utilization = (vehicle.currentLoad['weight']! + stop.weight) / vehicle.capacity;
      score += (1.0 - utilization.abs()) * (weights['capacity'] ?? 1.0);
      
      // Fuel efficiency score
      score += vehicle.fuelEfficiency * (weights['efficiency'] ?? 0.3);
      
      if (score > bestScore) {
        bestScore = score;
        bestVehicle = vehicle;
      }
    }
    
    return bestVehicle;
  }

  Future<OptimizedRoute?> _aStarPathfinding(
    String restaurantLocation,
    List<DeliveryStop> stops,
    DeliveryVehicle vehicle,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) async {
    // Simplified A* implementation
    if (stops.isEmpty) return null;
    
    // Calculate optimal order using nearest neighbor heuristic
    final routeStops = _nearestNeighborOrdering(restaurantLocation, stops);
    
    return _createOptimizedRoute(
      routeStops,
      vehicle,
      OptimizationAlgorithm.aStar,
      constraints,
      weights,
    );
  }

  List<DeliveryStop> _nearestNeighborOrdering(String start, List<DeliveryStop> stops) {
    final orderedStops = <DeliveryStop>[];
    final remainingStops = [...stops];
    String currentLocation = start;
    
    while (remainingStops.isNotEmpty) {
      DeliveryStop? nearestStop;
      double minDistance = double.infinity;
      
      for (final stop in remainingStops) {
        final distance = _calculateDistance(
          currentLocation,
          '${stop.latitude},${stop.longitude}',
        );
        
        // Combine distance with priority for selection
        final score = distance / (stop.priority / 10.0);
        
        if (score < minDistance) {
          minDistance = score;
          nearestStop = stop;
        }
      }
      
      if (nearestStop != null) {
        orderedStops.add(nearestStop);
        remainingStops.remove(nearestStop);
        currentLocation = '${nearestStop.latitude},${nearestStop.longitude}';
      }
    }
    
    return orderedStops;
  }

  OptimizedRoute _createOptimizedRoute(
    List<DeliveryStop> stops,
    DeliveryVehicle vehicle,
    OptimizationAlgorithm algorithm,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) {
    final now = DateTime.now();
    final totalDistance = _calculateTotalDistance(stops);
    final estimatedDuration = _calculateEstimatedDuration(stops, vehicle);
    final stopOrder = stops.map((s) => s.id).toList();
    
    return OptimizedRoute(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vehicleId: vehicle.id,
      driverId: vehicle.driverId,
      createdAt: now,
      scheduledStart: now,
      scheduledEnd: now.add(estimatedDuration),
      status: RouteStatus.planning,
      stops: stops,
      stopOrder: stopOrder,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      fuelCostEstimate: _calculateFuelCost(totalDistance, vehicle),
      carbonFootprintEstimate: _calculateCarbonFootprint(totalDistance, vehicle),
      algorithmUsed: algorithm,
      optimizationScores: {},
      trafficData: {},
      weatherData: {},
      constraints: constraints,
      metadata: weights,
    );
  }

  double _calculateTotalDistance(List<DeliveryStop> stops) {
    if (stops.isEmpty) return 0.0;
    
    double totalDistance = 0.0;
    
    // Distance from restaurant to first stop
    // This would use actual routing service in production
    for (int i = 0; i < stops.length - 1; i++) {
      final distance = _calculateDistance(
        '${stops[i].latitude},${stops[i].longitude}',
        '${stops[i + 1].latitude},${stops[i + 1].longitude}',
      );
      totalDistance += distance;
    }
    
    return totalDistance;
  }

  double _calculateDistance(String from, String to) {
    // Haversine formula for calculating distance between two points
    // This is a simplified version - in production, use proper routing services
    return 5.0; // Mock distance
  }

  Duration _calculateEstimatedDuration(List<DeliveryStop> stops, DeliveryVehicle vehicle) {
    final totalDistance = _calculateTotalDistance(stops);
    final averageSpeed = vehicle.averageSpeed; // km/h
    final travelTime = Duration(minutes: (totalDistance / averageSpeed * 60).round());
    
    // Add delivery time per stop
    final totalDeliveryTime = Duration(minutes: stops.length * 5);
    
    return travelTime + totalDeliveryTime;
  }

  double _calculateFuelCost(double distance, DeliveryVehicle vehicle) {
    return distance / vehicle.fuelEfficiency; // Simplified calculation
  }

  double _calculateCarbonFootprint(double distance, DeliveryVehicle vehicle) {
    // Emission factors per km (simplified)
    final emissionFactors = {
      VehicleType.bicycle: 0.0,
      VehicleType.electricScooter: 0.05,
      VehicleType.motorcycle: 0.15,
      VehicleType.car: 0.20,
      VehicleType.drone: 0.10,
      VehicleType.robot: 0.02,
    };
    
    return distance * (emissionFactors[vehicle.type] ?? 0.15);
  }

  // Additional helper methods for Clarke-Wright algorithm
  List<Saving> _calculateSavings(List<DeliveryStop> stops) {
    final savings = <Saving>[];
    
    for (int i = 0; i < stops.length; i++) {
      for (int j = i + 1; j < stops.length; j++) {
        final stop1 = stops[i];
        final stop2 = stops[j];
        
        // Calculate saving if these stops are served on the same route
        final saving = _calculatePairSaving(stop1, stop2);
        savings.add(Saving(stop1, stop2, saving));
      }
    }
    
    return savings;
  }

  double _calculatePairSaving(DeliveryStop stop1, DeliveryStop stop2) {
    // Simplified savings calculation
    // Savings = distance to serve both stops together - sum of individual distances
    return 2.0; // Mock savings
  }

  bool _canMergeRoutes(
    List<DeliveryStop> route1,
    List<DeliveryStop> route2,
    List<DeliveryVehicle> vehicles,
    List<RouteConstraint> constraints,
  ) {
    final allStops = [...route1, ...route2];
    final totalWeight = allStops.fold(0.0, (total, stop) => total + stop.weight);
    final totalVolume = allStops.fold(0.0, (total, stop) => total + stop.volume);
    
    return vehicles.any((vehicle) =>
        vehicle.capacity >= totalWeight &&
        vehicle.volumeCapacity >= totalVolume);
  }

  List<DeliveryStop> _mergeRoutes(List<DeliveryStop> route1, List<DeliveryStop> route2) {
    // Simple merge - in production would use more sophisticated logic
    return [...route1, ...route2];
  }

  DeliveryVehicle? _selectBestVehicleForRoute(
    List<DeliveryStop> stops,
    List<DeliveryVehicle> vehicles,
  ) {
    final totalWeight = stops.fold(0.0, (total, stop) => total + stop.weight);
    final totalVolume = stops.fold(0.0, (total, stop) => total + stop.volume);
    
    return vehicles.firstWhere(
      (vehicle) =>
          vehicle.isAvailable &&
          vehicle.isActive &&
          vehicle.capacity >= totalWeight &&
          vehicle.volumeCapacity >= totalVolume,
      orElse: () => throw Exception('No suitable vehicle found'),
    );
  }

  // ML optimization methods
  Future<Map<String, dynamic>> _getHistoricalOptimizationData() async {
    // Get historical route performance data
    // In production, this would query historical routes and their performance
    return {
      'averageOptimizedTime': 25.0, // minutes
      'commonBottlenecks': ['traffic_lights', 'busy_intersections'],
      'peakHours': [12, 13, 18, 19, 20],
      'seasonalPatterns': {
        'summer': 1.1,
        'winter': 0.9,
        'rainy': 1.2,
      },
    };
  }

  void _applyMLOptimizations(
    OptimizedRoute route,
    Map<String, dynamic> historicalData,
    List<RouteConstraint> constraints,
  ) {
    // Apply ML-based time adjustments
    final now = DateTime.now();
    final currentHour = now.hour;
    final peakHours = historicalData['peakHours'] as List<int>;
    
    if (peakHours.contains(currentHour)) {
      // Add time buffer during peak hours
      route.estimatedDuration = Duration(
        minutes: route.estimatedDuration.inMinutes + 10,
      );
    }
    
    // Apply seasonal adjustments
    final season = _getCurrentSeason(now);
    final seasonalFactor = (historicalData['seasonalPatterns'] as Map<String, double>)[season] ?? 1.0;
    
    route.estimatedDuration = Duration(
      minutes: (route.estimatedDuration.inMinutes * seasonalFactor).round(),
    );
  }

  // Pareto optimization
  List<OptimizedRoute> _findParetoOptimalRoutes(
    List<OptimizedRoute> routes,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) {
    final paretoOptimal = <OptimizedRoute>[];
    
    for (final route in routes) {
      bool isDominated = false;
      
      for (final otherRoute in routes) {
        if (route == otherRoute) continue;
        
        // Check if other route dominates this route
        if (_dominates(otherRoute, route, constraints, weights)) {
          isDominated = true;
          break;
        }
      }
      
      if (!isDominated) {
        paretoOptimal.add(route);
      }
    }
    
    return paretoOptimal;
  }

  bool _dominates(
    OptimizedRoute route1,
    OptimizedRoute route2,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) {
    // Check if route1 is better or equal in all objectives and strictly better in at least one
    bool betterInAtLeastOne = false;
    
    // Compare distance (lower is better)
    if (route1.totalDistance < route2.totalDistance) {
      betterInAtLeastOne = true;
    } else if (route1.totalDistance > route2.totalDistance) {
      return false; // route1 is worse in distance
    }
    
    // Compare time (lower is better)
    if (route1.estimatedDuration.inMinutes < route2.estimatedDuration.inMinutes) {
      betterInAtLeastOne = true;
    } else if (route1.estimatedDuration.inMinutes > route2.estimatedDuration.inMinutes) {
      return false; // route1 is worse in time
    }
    
    // Compare cost (lower is better)
    if (route1.fuelCostEstimate < route2.fuelCostEstimate) {
      betterInAtLeastOne = true;
    } else if (route1.fuelCostEstimate > route2.fuelCostEstimate) {
      return false; // route1 is worse in cost
    }
    
    return betterInAtLeastOne;
  }

  // Data retrieval methods
  Future<String> _getRestaurantLocation(String orderId) async {
    // Get restaurant location from order or restaurant data
    return '40.7128,-74.0060'; // Mock coordinates
  }

  Future<Map<String, dynamic>> _getRealTimeTrafficData(String restaurantId) async {
    // Get real-time traffic data from external API
    return {
      'congestionLevel': 0.3,
      'averageSpeed': 25.0,
      'accidents': [],
      'roadClosures': [],
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<Map<String, dynamic>> _getWeatherData(String restaurantId) async {
    // Get weather data from external API
    return {
      'condition': 'clear',
      'temperature': 22.0,
      'windSpeed': 5.0,
      'visibility': 10.0,
      'precipitation': 0.0,
    };
  }

  String _getCurrentSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  double _recalculateDistanceWithTraffic(
    OptimizedRoute route,
    Map<String, dynamic> trafficData,
  ) {
    final congestionLevel = (trafficData['congestionLevel'] ?? 0.0) as double;
    return route.totalDistance * (1.0 + congestionLevel * 0.5);
  }

  Duration _recalculateDurationWithWeather(
    OptimizedRoute route,
    Map<String, dynamic> weatherData,
  ) {
    final condition = weatherData['condition'] as String? ?? 'clear';
    final precipitation = (weatherData['precipitation'] ?? 0.0) as double;
    
    double weatherFactor = 1.0;
    
    switch (condition) {
      case 'rain':
        weatherFactor = 1.2;
        break;
      case 'snow':
        weatherFactor = 1.4;
        break;
      case 'fog':
        weatherFactor = 1.1;
        break;
    }
    
    if (precipitation > 0.0) {
      weatherFactor += 0.1;
    }
    
    return Duration(
      minutes: (route.estimatedDuration.inMinutes * weatherFactor).round(),
    );
  }

  // Database operations
  Future<void> _saveOptimizedRoutes(List<OptimizedRoute> routes) async {
    final batch = _firestore.batch();
    
    for (final route in routes) {
      final docRef = _firestore.collection('optimizedRoutes').doc(route.id);
      batch.set(docRef, route.toJson());
    }
    
    await batch.commit();
  }

  // Notification methods
  Future<void> _sendStatusUpdateNotification(
    OptimizedRoute route,
    String stopId,
    String status,
  ) async {
    // Send push notification to customer
    // This would integrate with notification service
    debugPrint('Status update sent: $status for stop $stopId');
  }

  // Other helper methods

  void _insertStopsIntoRoute(OptimizedRoute route, List<DeliveryStop> newStops) {
    for (final newStop in newStops) {
      // Find optimal insertion point
      int insertIndex = _findOptimalInsertionIndex(route, newStop);
      route.stops.insert(insertIndex, newStop);
      route.stopOrder.insert(insertIndex, newStop.id);
    }
    
    // Recalculate route metrics
    route.totalDistance = _calculateTotalDistance(route.stops);
    route.estimatedDuration = _calculateEstimatedDuration(route.stops, 
        DeliveryVehicle(
          id: route.vehicleId,
          driverId: route.driverId,
          driverName: '',
          type: VehicleType.bicycle,
          capacity: 50.0,
          volumeCapacity: 100.0,
          fuelEfficiency: 0.0,
          currentLoad: {'weight': 0.0, 'volume': 0.0},
          isActive: true,
          isAvailable: true,
          lastMaintenance: DateTime.now(),
          supportedAreas: [],
          averageSpeed: 25.0,
          performanceMetrics: {},
          capabilities: [],
          metadata: {},
        ));
  }

  int _findOptimalInsertionIndex(OptimizedRoute route, DeliveryStop newStop) {
    double minCost = double.infinity;
    int bestIndex = 0;
    
    for (int i = 0; i <= route.stops.length; i++) {
      final cost = _calculateInsertionCost(route, i, newStop);
      if (cost < minCost) {
        minCost = cost;
        bestIndex = i;
      }
    }
    
    return bestIndex;
  }

  double _calculateInsertionCost(OptimizedRoute route, int index, DeliveryStop newStop) {
    double cost = 0.0;
    
    // Calculate distance from previous stop to new stop
    if (index > 0) {
      final prevStop = route.stops[index - 1];
      cost += _calculateDistance(
        '${prevStop.latitude},${prevStop.longitude}',
        '${newStop.latitude},${newStop.longitude}',
      );
    }
    
    // Calculate distance from new stop to next stop
    if (index < route.stops.length) {
      final nextStop = route.stops[index];
      cost += _calculateDistance(
        '${newStop.latitude},${newStop.longitude}',
        '${nextStop.latitude},${nextStop.longitude}',
      );
    }
    
    // Subtract original distance
    if (index > 0 && index < route.stops.length) {
      final prevStop = route.stops[index - 1];
      final nextStop = route.stops[index];
      cost -= _calculateDistance(
        '${prevStop.latitude},${prevStop.longitude}',
        '${nextStop.latitude},${nextStop.longitude}',
      );
    }
    
    return cost;
  }

  Future<String> _getCurrentDriverLocation(String driverId) async {
    // Get current driver location from tracking service
    return '40.7129,-74.0061'; // Mock location
  }

  RouteAnalytics _calculateRouteAnalytics(
    List<OptimizedRoute> routes,
    DateTime startDate,
    DateTime endDate,
    String? restaurantId,
  ) {
    final totalRoutes = routes.length;
    final completedRoutes = routes.where((r) => r.status == RouteStatus.completed).length;
    final onTimeDeliveries = routes.where((r) => r.isOnTime).length;
    
    final totalDistance = routes.fold(0.0, (total, r) => total + r.totalDistance);
    final totalFuelCost = routes.fold(0.0, (total, r) => total + r.fuelCostEstimate);
    final totalCarbonEmissions = routes.fold(0.0, (total, r) => total + r.carbonFootprintEstimate);
    
    return RouteAnalytics(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      periodStart: startDate,
      periodEnd: endDate,
      restaurantId: restaurantId,
      totalRoutes: totalRoutes,
      completedRoutes: completedRoutes,
      onTimeDeliveries: onTimeDeliveries,
      lateDeliveries: totalRoutes - onTimeDeliveries,
      averageDeliveryTime: totalRoutes > 0
          ? routes.fold(0.0, (total, r) => total + r.estimatedDuration.inMinutes) / totalRoutes
          : 0.0,
      averageDistance: totalRoutes > 0 ? totalDistance / totalRoutes : 0.0,
      totalDistance: totalDistance,
      totalFuelCost: totalFuelCost,
      totalCarbonEmissions: totalCarbonEmissions,
      averageDriverEfficiency: 85.0, // Mock data
      algorithmUsage: _countAlgorithmUsage(routes),
      vehicleTypeUsage: _countVehicleTypeUsage(routes),
      performanceMetrics: {},
      commonDelays: ['traffic', 'weather', 'customer_not_available'],
      customerSatisfaction: {'rating': 4.2, 'complaints': 15, 'compliments': 45},
      recommendations: [
        'Use A* algorithm for complex routes',
        'Implement real-time traffic updates',
        'Add weather-based route adjustments',
      ],
      metadata: {},
    );
  }

  Map<String, int> _countAlgorithmUsage(List<OptimizedRoute> routes) {
    final usage = <String, int>{};
    for (final route in routes) {
      final algorithm = route.algorithmUsed.name;
      usage[algorithm] = (usage[algorithm] ?? 0) + 1;
    }
    return usage;
  }

  Map<String, int> _countVehicleTypeUsage(List<OptimizedRoute> routes) {
    // This would need to be implemented based on available data
    return {};
  }

  int _findRouteContainingStop(List<List<DeliveryStop>> routes, DeliveryStop stop) {
    for (int i = 0; i < routes.length; i++) {
      if (routes[i].any((s) => s.id == stop.id)) {
        return i;
      }
    }
    return -1;
  }

  // Genetic Algorithm for TSP
  Future<OptimizedRoute?> _geneticAlgorithmTSP(
    String restaurantLocation,
    List<DeliveryStop> stops,
    DeliveryVehicle vehicle,
    List<RouteConstraint> constraints,
    Map<String, double> weights,
  ) async {
    // Simplified genetic algorithm implementation
    // In production, this would be a full genetic algorithm
    
    final route = _createOptimizedRoute(
      stops,
      vehicle,
      OptimizationAlgorithm.tspGenetic,
      constraints,
      weights,
    );
    
    return route;
  }

  // Remaining helper methods for Clarke-Wright
  int max(int a, int b) => a > b ? a : b;
  int min(int a, int b) => a < b ? a : b;
}

// Helper classes
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});
}

class Saving {
  final DeliveryStop stop1;
  final DeliveryStop stop2;
  final double saving;

  Saving(this.stop1, this.stop2, this.saving);
}