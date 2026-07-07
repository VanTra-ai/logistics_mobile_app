import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/wms_provider.dart';

class PutawayScreen extends ConsumerStatefulWidget {
  const PutawayScreen({super.key});

  @override
  ConsumerState<PutawayScreen> createState() => _PutawayScreenState();
}

class _PutawayScreenState extends ConsumerState<PutawayScreen> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _scannerController.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _scannerController.stop();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        final state = ref.read(putawayProvider);
        if (state.step == PutawayStep.scanOrder) {
          ref.read(putawayProvider.notifier).scanOrder(code);
        } else if (state.step == PutawayStep.scanLocation) {
          ref.read(putawayProvider.notifier).scanLocation(code);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(putawayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cất hàng lên kệ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(putawayProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Timeline indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepIndicator(
                  context: context,
                  isActive: state.step == PutawayStep.scanOrder,
                  isDone: state.step.index > PutawayStep.scanOrder.index,
                  label: 'Đơn hàng',
                  icon: Icons.inventory_2_outlined,
                ),
                _buildStepDivider(),
                _buildStepIndicator(
                  context: context,
                  isActive: state.step == PutawayStep.scanLocation,
                  isDone: state.step.index > PutawayStep.scanLocation.index,
                  label: 'Vị trí',
                  icon: Icons.qr_code_scanner,
                ),
                _buildStepDivider(),
                _buildStepIndicator(
                  context: context,
                  isActive: state.step == PutawayStep.confirming,
                  isDone: state.step.index > PutawayStep.confirming.index,
                  label: 'Xác nhận',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _buildBodyContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required BuildContext context,
    required bool isActive,
    required bool isDone,
    required String label,
    required IconData icon,
  }) {
    final color = isDone || isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: isActive 
              ? Theme.of(context).colorScheme.primaryContainer 
              : Colors.transparent,
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        color: Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildBodyContent(PutawayState state) {
    if (state.step == PutawayStep.scanOrder || state.step == PutawayStep.scanLocation) {
      return Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.step == PutawayStep.scanOrder
                    ? 'Hãy quét mã vạch trên ĐƠN HÀNG'
                    : 'Đã quét đơn: ${state.orderTracking}\nHãy quét mã vạch trên KỆ HÀNG',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    if (state.step == PutawayStep.confirming) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text('Xác nhận cất hàng', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 32),
            _buildInfoRow('Đơn hàng:', state.orderTracking ?? ''),
            const SizedBox(height: 16),
            _buildInfoRow('Vị trí kệ:', state.locationBarcode ?? ''),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {
                  ref.read(putawayProvider.notifier).confirm();
                },
                child: const Text('XÁC NHẬN CẤT HÀNG', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    }

    if (state.step == PutawayStep.done) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              state.message ?? 'Thành công',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.step == PutawayStep.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                state.message ?? 'Có lỗi xảy ra',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => ref.read(putawayProvider.notifier).reset(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
