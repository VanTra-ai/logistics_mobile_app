import '../../auth/models/user_model.dart';

/// Model cho Đơn hàng đính kèm hoặc khả dụng trong kho
class OrderModel {
  final String id;
  final String trackingNumber;
  final String currentStatus;
  final String receiverName;
  final String receiverAddress;
  final double weight;
  final double codAmount;
  final int deliverySequence;
  final double? latitude;
  final double? longitude;

  const OrderModel({
    required this.id,
    required this.trackingNumber,
    required this.currentStatus,
    required this.receiverName,
    required this.receiverAddress,
    required this.weight,
    required this.codAmount,
    this.deliverySequence = 0,
    this.latitude,
    this.longitude,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      trackingNumber: json['tracking_number'] as String,
      currentStatus: json['current_status'] as String,
      receiverName: json['receiver_name'] as String? ?? 'Khách nhận',
      receiverAddress: json['receiver_address'] as String? ?? '',
      weight: double.tryParse(json['weight']?.toString() ?? '0') ?? 0.0,
      codAmount: double.tryParse(json['cod_amount']?.toString() ?? '0') ?? 0.0,
      deliverySequence: json['delivery_sequence'] as int? ?? 0,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_number': trackingNumber,
      'current_status': currentStatus,
      'receiver_name': receiverName,
      'receiver_address': receiverAddress,
      'weight': weight,
      'cod_amount': codAmount,
      'delivery_sequence': deliverySequence,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Model cho Chuyến xe vận chuyển
class ShipmentModel {
  final String id;
  final String? shipmentCode;
  final String vehicleNumber;
  final double capacityWeight;
  final String status;
  final DateTime createdAt;
  final UserModel? shipper;
  final HubModel? originHub;
  final HubModel? destinationHub;
  final List<OrderModel>? orders;

  const ShipmentModel({
    required this.id,
    this.shipmentCode,
    required this.vehicleNumber,
    required this.capacityWeight,
    required this.status,
    required this.createdAt,
    this.shipper,
    this.originHub,
    this.destinationHub,
    this.orders,
  });

  /// Tính tổng khối lượng các đơn hàng đang nằm trên xe
  double get currentWeight {
    if (orders == null || orders!.isEmpty) return 0.0;
    return orders!.fold(0.0, (sum, o) => sum + o.weight);
  }

  /// Tính tỷ lệ lấp đầy tải trọng của xe (giới hạn từ 0.0 đến 1.0)
  double get fillRate {
    if (capacityWeight <= 0) return 0.0;
    final rate = currentWeight / capacityWeight;
    return rate.isNaN || rate.isInfinite ? 0.0 : (rate > 1.0 ? 1.0 : rate);
  }

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: json['id'] as String,
      shipmentCode: json['shipment_code'] as String?,
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      capacityWeight: double.tryParse(json['capacity_weight']?.toString() ?? '1000') ?? 1000.0,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      shipper: json['shipper'] != null ? UserModel.fromJson(json['shipper'] as Map<String, dynamic>) : null,
      originHub: json['origin_hub'] != null ? HubModel.fromJson(json['origin_hub'] as Map<String, dynamic>) : null,
      destinationHub: json['destination_hub'] != null ? HubModel.fromJson(json['destination_hub'] as Map<String, dynamic>) : null,
      orders: json['orders'] != null
          ? (json['orders'] as List).map((o) => OrderModel.fromJson(o as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_code': shipmentCode,
      'vehicle_number': vehicleNumber,
      'capacity_weight': capacityWeight,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'shipper': shipper?.toJson(),
      'origin_hub': originHub?.toJson(),
      'destination_hub': destinationHub?.toJson(),
      'orders': orders?.map((o) => o.toJson()).toList(),
    };
  }
}
