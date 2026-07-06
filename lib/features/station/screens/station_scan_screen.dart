import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/station_provider.dart';

class StationScanScreen extends ConsumerStatefulWidget {
  const StationScanScreen({super.key});

  @override
  ConsumerState<StationScanScreen> createState() => _StationScanScreenState();
}

class _StationScanScreenState extends ConsumerState<StationScanScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Tắt camera khi app vào background, bật lại khi resumed
    if (state == AppLifecycleState.resumed) {
      _cameraController.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    ref.read(stationProvider.notifier).handleScan(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    final stationState = ref.watch(stationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Hiển thị feedback khi trạng thái thay đổi
    ref.listen<StationState>(stationProvider, (previous, next) {
      if (next.lastMessage != null &&
          next.lastMessage != previous?.lastMessage) {
        _showFeedback(context, next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trạm Xử lý Đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Xoá phiên quét',
            onPressed: stationState.sessionItems.isEmpty
                ? null
                : () => _confirmClearSession(context),
          ),
          ValueListenableBuilder(
            valueListenable: _cameraController,
            builder: (context, value, child) {
              return IconButton(
                icon: Icon(
                  value.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off_outlined,
                ),
                tooltip: 'Đèn flash',
                onPressed: _cameraController.toggleTorch,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Thanh chuyển đổi chế độ ──
          _ModeToggle(
            mode: stationState.mode,
            onChanged: (mode) =>
                ref.read(stationProvider.notifier).setMode(mode),
          ),

          // ── Vùng Camera ──
          _CameraView(
            controller: _cameraController,
            stationState: stationState,
            onDetect: _onBarcodeDetected,
          ),

          // ── Phần phân cách ──
          _SessionHeader(itemCount: stationState.sessionItems.length),

          // ── Danh sách kết quả phiên quét ──
          Expanded(
            child: stationState.sessionItems.isEmpty
                ? _EmptySessionView(mode: stationState.mode)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: stationState.sessionItems.length,
                    itemBuilder: (context, index) {
                      final item = stationState.sessionItems[index];
                      return _ScannedItemTile(
                          item: item, colorScheme: colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFeedback(BuildContext context, StationState state) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              state.hasError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(state.lastMessage ?? '')),
          ],
        ),
        backgroundColor: state.hasError ? Colors.red.shade700 : Colors.green.shade700,
        duration: Duration(seconds: state.hasError ? 2 : 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _confirmClearSession(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá phiên quét'),
        content: const Text(
            'Xoá toàn bộ danh sách đơn đã quét trong phiên này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(stationProvider.notifier).clearSession();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final ScanMode mode;
  final ValueChanged<ScanMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<ScanMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: ScanMode.scanIn,
            label: Text('Nhập kho'),
            icon: Icon(Icons.login),
          ),
          ButtonSegment(
            value: ScanMode.scanOut,
            label: Text('Xuất kho'),
            icon: Icon(Icons.logout),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  final MobileScannerController controller;
  final StationState stationState;
  final void Function(BarcodeCapture) onDetect;

  const _CameraView({
    required this.controller,
    required this.stationState,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Màu overlay theo trạng thái
    Color overlayColor = Colors.transparent;
    if (stationState.status == ScanStatus.success) {
      overlayColor = Colors.green.withValues(alpha: 0.25);
    } else if (stationState.status == ScanStatus.error) {
      overlayColor = Colors.red.withValues(alpha: 0.25);
    }

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
          ),

          // Overlay phản hồi màu sắc
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: overlayColor,
          ),

          // Khung ngắm
          Center(
            child: Container(
              width: 220,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(
                  color: stationState.status == ScanStatus.error
                      ? Colors.red
                      : stationState.status == ScanStatus.success
                          ? Colors.green
                          : Colors.white,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Chỉ báo đang xử lý
          if (stationState.status == ScanStatus.processing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Đang xử lý...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // Nhãn chế độ quét
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stationState.mode == ScanMode.scanIn
                      ? '📦  Chế độ NHẬP KHO'
                      : '🚛  Chế độ XUẤT KHO',
                  style: TextStyle(
                    color: stationState.mode == ScanMode.scanIn
                        ? colorScheme.primaryContainer
                        : colorScheme.secondaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final int itemCount;

  const _SessionHeader({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Icon(Icons.history, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'Phiên hiện tại',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (itemCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$itemCount đơn',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannedItemTile extends StatelessWidget {
  final ScannedItem item;
  final ColorScheme colorScheme;

  const _ScannedItemTile({required this.item, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isIn = item.mode == ScanMode.scanIn;
    final hour = item.timestamp.hour.toString().padLeft(2, '0');
    final minute = item.timestamp.minute.toString().padLeft(2, '0');
    final second = item.timestamp.second.toString().padLeft(2, '0');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: item.isSuccess
              ? (isIn ? Colors.green.shade100 : Colors.blue.shade100)
              : Colors.red.shade100,
          child: Icon(
            item.isSuccess
                ? (isIn ? Icons.login : Icons.logout)
                : Icons.error_outline,
            size: 18,
            color: item.isSuccess
                ? (isIn ? Colors.green.shade700 : Colors.blue.shade700)
                : Colors.red.shade700,
          ),
        ),
        title: Text(
          item.trackingNumber,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
        subtitle: Text(
          item.message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '$hour:$minute:$second',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _EmptySessionView extends StatelessWidget {
  final ScanMode mode;

  const _EmptySessionView({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            mode == ScanMode.scanIn
                ? Icons.qr_code_scanner
                : Icons.qr_code_2_outlined,
            size: 52,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            mode == ScanMode.scanIn
                ? 'Quét mã để nhập kho đơn hàng'
                : 'Quét mã để xuất kho đơn hàng',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
