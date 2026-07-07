import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/wms_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Putaway — Enums, Models, State, Notifier
// ─────────────────────────────────────────────────────────────────────────────

enum PutawayStep { scanOrder, scanLocation, confirming, done, error }

class PutawayState {
  final PutawayStep step;
  final String? orderId;
  final String? orderTracking;
  final String? locationBarcode;
  final String? message;

  const PutawayState({
    this.step = PutawayStep.scanOrder,
    this.orderId,
    this.orderTracking,
    this.locationBarcode,
    this.message,
  });

  PutawayState copyWith({
    PutawayStep? step,
    String? orderId,
    String? orderTracking,
    String? locationBarcode,
    String? message,
  }) {
    return PutawayState(
      step: step ?? this.step,
      orderId: orderId ?? this.orderId,
      orderTracking: orderTracking ?? this.orderTracking,
      locationBarcode: locationBarcode ?? this.locationBarcode,
      message: message ?? this.message,
    );
  }
}

class PutawayNotifier extends StateNotifier<PutawayState> {
  final WmsRepository _repository;

  PutawayNotifier(this._repository) : super(const PutawayState());

  /// Bước 1: Quét mã đơn hàng → trích orderId và tracking.
  void scanOrder(String barcode) {
    if (state.step != PutawayStep.scanOrder) return;

    state = state.copyWith(
      step: PutawayStep.scanLocation,
      orderId: barcode,
      orderTracking: barcode,
    );
  }

  /// Bước 2: Quét mã vị trí kho.
  void scanLocation(String barcode) {
    if (state.step != PutawayStep.scanLocation) return;

    state = state.copyWith(
      step: PutawayStep.confirming,
      locationBarcode: barcode,
    );
  }

  /// Bước 3: Xác nhận cất hàng — gọi API.
  Future<void> confirm() async {
    if (state.step != PutawayStep.confirming) return;

    try {
      final result = await _repository.putaway(
        state.orderId!,
        state.locationBarcode!,
      );

      state = state.copyWith(
        step: PutawayStep.done,
        message: result['message'] as String? ?? 'Cất hàng thành công!',
      );

      // Tự động reset sau 2 giây
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) reset();
    } on Exception catch (e) {
      state = state.copyWith(
        step: PutawayStep.error,
        message: _parseError(e),
      );
    }
  }

  /// Reset về trạng thái ban đầu.
  void reset() {
    state = const PutawayState();
  }

  String _parseError(Exception e) {
    final str = e.toString();
    if (str.contains('400')) return 'Đơn hàng không hợp lệ hoặc sai trạng thái.';
    if (str.contains('404')) return 'Không tìm thấy đơn hàng.';
    if (str.contains('SocketException')) return 'Mất kết nối mạng.';
    return 'Lỗi không xác định. Thử lại sau.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Packaging — Models, State, Notifier
// ─────────────────────────────────────────────────────────────────────────────

class MaterialItem {
  final String id;
  final String name;
  final double unitPrice;

  const MaterialItem({
    required this.id,
    required this.name,
    required this.unitPrice,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SelectedMaterial {
  final MaterialItem material;
  final int quantity;

  const SelectedMaterial({required this.material, this.quantity = 1});

  SelectedMaterial copyWith({int? quantity}) {
    return SelectedMaterial(
      material: material,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice => material.unitPrice * quantity;
}

class PackagingState {
  final bool isScanning;
  final String? orderId;
  final String? orderTracking;
  final List<MaterialItem> materials;
  final List<SelectedMaterial> selected;
  final bool isSubmitting;
  final String? message;
  final bool hasError;

  const PackagingState({
    this.isScanning = true,
    this.orderId,
    this.orderTracking,
    this.materials = const [],
    this.selected = const [],
    this.isSubmitting = false,
    this.message,
    this.hasError = false,
  });

  double get totalFee =>
      selected.fold(0.0, (sum, item) => sum + item.totalPrice);

  PackagingState copyWith({
    bool? isScanning,
    String? orderId,
    String? orderTracking,
    List<MaterialItem>? materials,
    List<SelectedMaterial>? selected,
    bool? isSubmitting,
    String? message,
    bool? hasError,
  }) {
    return PackagingState(
      isScanning: isScanning ?? this.isScanning,
      orderId: orderId ?? this.orderId,
      orderTracking: orderTracking ?? this.orderTracking,
      materials: materials ?? this.materials,
      selected: selected ?? this.selected,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      message: message ?? this.message,
      hasError: hasError ?? this.hasError,
    );
  }
}

class PackagingNotifier extends StateNotifier<PackagingState> {
  final WmsRepository _repository;

  PackagingNotifier(this._repository) : super(const PackagingState());

  /// Quét mã đơn hàng → chuyển sang phase chọn vật liệu.
  Future<void> scanOrder(String barcode) async {
    state = state.copyWith(
      isScanning: false,
      orderId: barcode,
      orderTracking: barcode,
    );

    // Tải danh sách vật liệu
    try {
      final rawMaterials = await _repository.getMaterials();
      final materials = rawMaterials
          .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(materials: materials);
    } on Exception catch (e) {
      state = state.copyWith(
        message: _parseError(e),
        hasError: true,
      );
    }
  }

  /// Bật/tắt chọn vật liệu.
  void toggleMaterial(MaterialItem material, bool selected) {
    final current = List<SelectedMaterial>.from(state.selected);

    if (selected) {
      // Thêm nếu chưa có
      if (!current.any((s) => s.material.id == material.id)) {
        current.add(SelectedMaterial(material: material));
      }
    } else {
      current.removeWhere((s) => s.material.id == material.id);
    }

    state = state.copyWith(selected: current);
  }

  /// Cập nhật số lượng vật liệu.
  void updateQuantity(String materialId, int quantity) {
    final current = List<SelectedMaterial>.from(state.selected);
    final index = current.indexWhere((s) => s.material.id == materialId);
    if (index >= 0 && quantity > 0) {
      current[index] = current[index].copyWith(quantity: quantity);
      state = state.copyWith(selected: current);
    }
  }

  /// Xác nhận đóng gói — gọi API.
  Future<void> submit() async {
    if (state.isSubmitting || state.orderId == null) return;

    state = state.copyWith(isSubmitting: true);

    try {
      final items = state.selected
          .map((s) => {
                'material_id': s.material.id,
                'quantity': s.quantity,
              })
          .toList();

      final result = await _repository.packageOrder(state.orderId!, items);

      state = state.copyWith(
        isSubmitting: false,
        message: result['message'] as String? ?? 'Đóng gói thành công!',
        hasError: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        message: _parseError(e),
        hasError: true,
      );
    }
  }

  /// Reset để quét đơn mới.
  void reset() {
    state = const PackagingState();
  }

  String _parseError(Exception e) {
    final str = e.toString();
    if (str.contains('400')) return 'Yêu cầu không hợp lệ.';
    if (str.contains('404')) return 'Không tìm thấy đơn hàng.';
    if (str.contains('SocketException')) return 'Mất kết nối mạng.';
    return 'Lỗi không xác định. Thử lại sau.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Audit — Models, State, Notifier
// ─────────────────────────────────────────────────────────────────────────────

enum AuditStep { selectAudit, scanLocation, scanOrders, submitting, results }

class AuditSummary {
  final String id;
  final String name;
  final String status;
  final String? description;

  const AuditSummary({
    required this.id,
    required this.name,
    required this.status,
    this.description,
  });

  factory AuditSummary.fromJson(Map<String, dynamic> json) {
    return AuditSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

class AuditResult {
  final int matched;
  final int missing;
  final int wrong;
  final List<Map<String, dynamic>> details;

  const AuditResult({
    required this.matched,
    required this.missing,
    required this.wrong,
    this.details = const [],
  });

  factory AuditResult.fromJson(Map<String, dynamic> json) {
    return AuditResult(
      matched: json['matched'] as int? ?? 0,
      missing: json['missing'] as int? ?? 0,
      wrong: json['wrong'] as int? ?? 0,
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

class AuditState {
  final AuditStep step;
  final List<AuditSummary> audits;
  final String? selectedAuditId;
  final String? locationBarcode;
  final List<String> scannedTrackings;
  final AuditResult? result;
  final String? message;
  final bool hasError;

  const AuditState({
    this.step = AuditStep.selectAudit,
    this.audits = const [],
    this.selectedAuditId,
    this.locationBarcode,
    this.scannedTrackings = const [],
    this.result,
    this.message,
    this.hasError = false,
  });

  AuditState copyWith({
    AuditStep? step,
    List<AuditSummary>? audits,
    String? selectedAuditId,
    String? locationBarcode,
    List<String>? scannedTrackings,
    AuditResult? result,
    String? message,
    bool? hasError,
  }) {
    return AuditState(
      step: step ?? this.step,
      audits: audits ?? this.audits,
      selectedAuditId: selectedAuditId ?? this.selectedAuditId,
      locationBarcode: locationBarcode ?? this.locationBarcode,
      scannedTrackings: scannedTrackings ?? this.scannedTrackings,
      result: result ?? this.result,
      message: message ?? this.message,
      hasError: hasError ?? this.hasError,
    );
  }
}

class AuditNotifier extends StateNotifier<AuditState> {
  final WmsRepository _repository;

  AuditNotifier(this._repository) : super(const AuditState());

  /// Tải danh sách phiên kiểm kê IN_PROGRESS.
  Future<void> loadAudits() async {
    try {
      final rawAudits = await _repository.getAudits(status: 'IN_PROGRESS');
      final audits = rawAudits
          .map((e) => AuditSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(audits: audits);
    } on Exception catch (e) {
      state = state.copyWith(
        message: _parseError(e),
        hasError: true,
      );
    }
  }

  /// Chọn phiên kiểm kê → chuyển sang quét vị trí.
  void selectAudit(String auditId) {
    state = state.copyWith(
      step: AuditStep.scanLocation,
      selectedAuditId: auditId,
    );
  }

  /// Quét mã vị trí → chuyển sang quét đơn hàng.
  void scanLocation(String barcode) {
    if (state.step != AuditStep.scanLocation) return;

    state = state.copyWith(
      step: AuditStep.scanOrders,
      locationBarcode: barcode,
    );
  }

  /// Quét mã đơn hàng (chế độ liên tục).
  void scanOrder(String trackingNumber) {
    if (state.step != AuditStep.scanOrders) return;

    // Tránh trùng lặp
    if (state.scannedTrackings.contains(trackingNumber)) return;

    state = state.copyWith(
      scannedTrackings: [...state.scannedTrackings, trackingNumber],
    );
  }

  /// Gửi kết quả kiểm kê.
  Future<void> submit() async {
    if (state.step != AuditStep.scanOrders) return;
    if (state.selectedAuditId == null || state.locationBarcode == null) return;

    state = state.copyWith(step: AuditStep.submitting);

    try {
      final rawResult = await _repository.submitAuditScan(
        state.selectedAuditId!,
        state.locationBarcode!,
        state.scannedTrackings,
      );

      state = state.copyWith(
        step: AuditStep.results,
        result: AuditResult.fromJson(rawResult),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        step: AuditStep.scanOrders,
        message: _parseError(e),
        hasError: true,
      );
    }
  }

  /// Reset về trạng thái ban đầu.
  void reset() {
    state = const AuditState();
    loadAudits();
  }

  String _parseError(Exception e) {
    final str = e.toString();
    if (str.contains('400')) return 'Yêu cầu không hợp lệ.';
    if (str.contains('404')) return 'Không tìm thấy phiên kiểm kê.';
    if (str.contains('SocketException')) return 'Mất kết nối mạng.';
    return 'Lỗi không xác định. Thử lại sau.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final putawayProvider =
    StateNotifierProvider.autoDispose<PutawayNotifier, PutawayState>((ref) {
  return PutawayNotifier(ref.read(wmsRepositoryProvider));
});

final packagingProvider =
    StateNotifierProvider.autoDispose<PackagingNotifier, PackagingState>((ref) {
  return PackagingNotifier(ref.read(wmsRepositoryProvider));
});

final auditProvider =
    StateNotifierProvider.autoDispose<AuditNotifier, AuditState>((ref) {
  return AuditNotifier(ref.read(wmsRepositoryProvider));
});
