enum OrderStatus {
  pending('Pending'),
  accepted('Accepted'),
  preparing('Preparing'),
  ready('Ready for Pickup'),
  pickedUp('Picked Up'),
  outForDelivery('Out for Delivery'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.displayName);
  final String displayName;

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderStatusTracker {
  final String orderId;
  final List<OrderStatusUpdate> updates;

  OrderStatusTracker({
    required this.orderId,
    required this.updates,
  });

  OrderStatus get currentStatus {
    return updates.isNotEmpty ? updates.last.status : OrderStatus.pending;
  }

  void addUpdate(OrderStatus status, {String? note}) {
    updates.add(OrderStatusUpdate(
      status: status,
      timestamp: DateTime.now(),
      note: note,
    ));
  }
}

class OrderStatusUpdate {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;

  OrderStatusUpdate({
    required this.status,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory OrderStatusUpdate.fromJson(Map<String, dynamic> json) {
    return OrderStatusUpdate(
      status: OrderStatus.fromString(json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'],
    );
  }
}