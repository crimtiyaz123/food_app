import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/delivery_tracking_service.dart';
import '../services/route_optimization_service.dart';
import '../models/delivery_tracking.dart';
import '../models/route_optimization.dart';
import '../widgets/enhanced_ui_components.dart';

class RealTimeOrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final bool showFullScreen;

  const RealTimeOrderTrackingScreen({
    super.key,
    required this.orderId,
    this.showFullScreen = true,
  });

  @override
  State<RealTimeOrderTrackingScreen> createState() => _RealTimeOrderTrackingScreenState();
}

class _RealTimeOrderTrackingScreenState extends State<RealTimeOrderTrackingScreen>
    with TickerProviderStateMixin {
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();
  final RouteOptimizationService _optimizationService = RouteOptimizationService();
  
  late AnimationController _statusController;
  late AnimationController _pulseController;
  late Animation<double> _statusAnimation;
  late Animation<double> _pulseAnimation;
  
  Stream<DeliveryTracking>? _trackingStream;
  DeliveryTracking? _currentTracking;
  
  // Map and location
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  LatLng? _restaurantLocation;
  LatLng? _deliveryLocation;
  
  // Timer for auto-refresh
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  
  // Analytics
  Map<String, dynamic>? _trackingAnalytics;
  
  // Mock data for demo
  final bool _isMockMode = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTracking();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _statusController.dispose();
    _pulseController.dispose();
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _statusAnimation = CurvedAnimation(
      parent: _statusController,
      curve: Curves.elasticOut,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    
    _pulseController.repeat(reverse: true);
  }

  void _initializeTracking() {
    if (_isMockMode) {
      _initializeMockData();
    } else {
      _trackingStream = _trackingService.getOrderTracking(widget.orderId);
      _trackingStream!.listen((tracking) {
        setState(() {
          _currentTracking = tracking;
        });
        _updateMapMarkers(tracking);
        _loadTrackingAnalytics();
      });
    }
  }

  void _initializeMockData() {
    // Mock data for demonstration
    _currentLocation = const LatLng(40.7128, -74.0060);
    _restaurantLocation = const LatLng(40.7580, -73.9855);
    _deliveryLocation = const LatLng(40.7505, -73.9934);
    
    _currentTracking = DeliveryTracking(
      orderId: widget.orderId,
      deliveryPartnerId: 'partner_001',
      customerId: 'customer_001',
      currentLocation: LocationData(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        address: 'Delivering to your location',
        placeName: 'Current Location',
        timestamp: DateTime.now(),
      ),
      restaurantLocation: LocationData(
        latitude: _restaurantLocation!.latitude,
        longitude: _restaurantLocation!.longitude,
        address: '123 Restaurant St, New York',
        placeName: 'Restaurant',
        timestamp: DateTime.now(),
      ),
      deliveryAddress: LocationData(
        latitude: _deliveryLocation!.latitude,
        longitude: _deliveryLocation!.longitude,
        address: '456 Customer Ave, New York',
        placeName: 'Your Location',
        timestamp: DateTime.now(),
      ),
      orderStatus: OrderStatus.outForDelivery,
      lastUpdated: DateTime.now(),
      estimatedArrival: '8 min',
      trackingHistory: [
        TrackingUpdate(
          status: 'confirmed',
          description: 'Order confirmed by restaurant',
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
          location: LocationData(
            latitude: _restaurantLocation!.latitude,
            longitude: _restaurantLocation!.longitude,
            address: '123 Restaurant St',
            placeName: 'Restaurant',
          ),
          updatedBy: 'system',
        ),
        TrackingUpdate(
          status: 'preparing',
          description: 'Restaurant is preparing your food',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
          location: LocationData(
            latitude: _restaurantLocation!.latitude,
            longitude: _restaurantLocation!.longitude,
            address: '123 Restaurant St',
            placeName: 'Restaurant',
          ),
          updatedBy: 'restaurant',
        ),
        TrackingUpdate(
          status: 'ready',
          description: 'Food is ready for pickup',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          location: LocationData(
            latitude: _restaurantLocation!.latitude,
            longitude: _restaurantLocation!.longitude,
            address: '123 Restaurant St',
            placeName: 'Restaurant',
          ),
          updatedBy: 'restaurant',
        ),
        TrackingUpdate(
          status: 'pickedup',
          description: 'Order picked up by delivery partner',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          location: LocationData(
            latitude: _restaurantLocation!.latitude,
            longitude: _restaurantLocation!.longitude,
            address: '123 Restaurant St',
            placeName: 'Restaurant',
          ),
          updatedBy: 'delivery_partner',
        ),
        TrackingUpdate(
          status: 'outfordelivery',
          description: 'Out for delivery',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          location: LocationData(
            latitude: _currentLocation!.latitude,
            longitude: _currentLocation!.longitude,
            address: 'En route to destination',
            placeName: 'In Transit',
          ),
          updatedBy: 'delivery_partner',
        ),
      ],
      deliveryPartnerName: 'John Smith',
      deliveryPartnerPhone: '+1 (555) 123-4567',
      vehicleInfo: 'Honda Civic - Blue',
      distanceRemaining: 2.5,
      deliveryTimeSeconds: 480, // 8 minutes
    );
    
    _updateMapMarkers(_currentTracking!);
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isRefreshing) {
        _refreshLocation();
      }
    });
  }

  void _refreshLocation() async {
    if (_isMockMode) {
      // Simulate movement towards destination
      final current = _currentLocation!;
      final target = _deliveryLocation!;
      
      final newLat = current.latitude + (target.latitude - current.latitude) * 0.1;
      final newLng = current.longitude + (target.longitude - current.longitude) * 0.1;
      
      setState(() {
        _currentLocation = LatLng(newLat, newLng);
        _isRefreshing = false;
      });
      
      _updateMapMarkers(_currentTracking!);
    } else {
      setState(() => _isRefreshing = true);
      // Real location update would happen here
      setState(() => _isRefreshing = false);
    }
  }

  void _updateMapMarkers(DeliveryTracking tracking) {
    setState(() {
      _markers.clear();
      _polylines.clear();
      
      // Restaurant marker
      _markers.add(Marker(
        markerId: const MarkerId('restaurant'),
        position: LatLng(
          tracking.restaurantLocation.latitude,
          tracking.restaurantLocation.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Restaurant',
          snippet: tracking.restaurantLocation.address ?? '',
        ),
      ));
      
      // Customer destination marker
      _markers.add(Marker(
        markerId: const MarkerId('customer'),
        position: LatLng(
          tracking.deliveryAddress.latitude,
          tracking.deliveryAddress.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: tracking.deliveryAddress.address ?? '',
        ),
      ));
      
      // Current delivery location marker
      if (_currentLocation != null) {
        _markers.add(Marker(
          markerId: const MarkerId('delivery'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Delivery Partner',
            snippet: '${tracking.deliveryPartnerName} - ${tracking.vehicleInfo}',
          ),
        ));
      }
      
      // Draw route line
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(tracking.restaurantLocation.latitude, tracking.restaurantLocation.longitude),
          if (_currentLocation != null) _currentLocation!,
          LatLng(tracking.deliveryAddress.latitude, tracking.deliveryAddress.longitude),
        ],
        color: Colors.orange,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ));
    });
  }

  Future<void> _loadTrackingAnalytics() async {
    if (widget.orderId.isNotEmpty) {
      try {
        final analytics = await _trackingService.getOrderAnalytics(widget.orderId);
        setState(() {
          _trackingAnalytics = analytics;
        });
      } catch (e) {
        debugPrint('Error loading analytics: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTracking == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTrackingOverview(),
              if (widget.showFullScreen) _buildInteractiveMap(),
              _buildStatusTimeline(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Tracking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Order #${widget.orderId}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_isRefreshing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingOverview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _statusAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _statusAnimation.value,
                child: Icon(
                  _getStatusIcon(_currentTracking!.orderStatus),
                  size: 48,
                  color: _getStatusColor(_currentTracking!.orderStatus),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            _currentTracking!.orderStatus.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentTracking!.orderStatus.description,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.access_time,
                label: 'ETA',
                value: _currentTracking!.estimatedArrival,
                color: Colors.orange,
              ),
              _buildInfoItem(
                icon: Icons.location_on,
                label: 'Distance',
                value: '${_currentTracking!.distanceRemaining.toStringAsFixed(1)} km',
                color: Colors.blue,
              ),
              _buildInfoItem(
                icon: Icons.delivery_dining,
                label: 'Driver',
                value: _currentTracking!.deliveryPartnerName.split(' ')[0],
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInteractiveMap() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            _updateMapBounds();
          },
          initialCameraPosition: CameraPosition(
            target: _currentLocation ?? const LatLng(40.7128, -74.0060),
            zoom: 13,
          ),
          markers: _markers,
          polylines: _polylines,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }

  void _updateMapBounds() {
    if (_mapController == null || _markers.isEmpty) return;

    final latLngs = _markers.map((marker) => marker.position).toList();
    final bounds = LatLngBounds(
      southwest: LatLng(
        latLngs.map((latLng) => latLng.latitude).reduce(math.min),
        latLngs.map((latLng) => latLng.longitude).reduce(math.min),
      ),
      northeast: LatLng(
        latLngs.map((latLng) => latLng.latitude).reduce(math.max),
        latLngs.map((latLng) => latLng.longitude).reduce(math.max),
      ),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  Widget _buildStatusTimeline() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Timeline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentTracking!.trackingHistory.length,
              itemBuilder: (context, index) {
                final update = _currentTracking!.trackingHistory[index];
                final isLast = index == _currentTracking!.trackingHistory.length - 1;
                
                return Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _isUpdateCompleted(update.status) ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey[600],
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              update.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(update.timestamp),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            if (update.location?.address != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                update.location!.address!,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _callDriver,
              icon: const Icon(Icons.call),
              label: const Text('Call Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _contactSupport,
              icon: const Icon(Icons.chat),
              label: const Text('Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callDriver() {
    // In a real app, this would initiate a call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling driver...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _contactSupport() {
    // Navigate to support chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening support chat...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.play_circle;
      case OrderStatus.pickedUp:
        return Icons.delivery_dining;
      case OrderStatus.outForDelivery:
        return Icons.directions_bike;
      case OrderStatus.arriving:
        return Icons.location_on;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.grey;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.yellow;
      case OrderStatus.pickedUp:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.blue;
      case OrderStatus.arriving:
        return Colors.red;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  bool _isUpdateCompleted(String status) {
    final currentStatus = _currentTracking!.orderStatus.toString();
    return _getStatusOrder(status) <= _getStatusOrder(currentStatus);
  }

  int _getStatusOrder(String status) {
    final order = [
      'pending',
      'confirmed',
      'preparing',
      'ready',
      'pickedup',
      'outfordelivery',
      'arriving',
      'delivered',
      'cancelled',
    ];
    final index = order.indexOf(status);
    return index == -1 ? 0 : index;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}