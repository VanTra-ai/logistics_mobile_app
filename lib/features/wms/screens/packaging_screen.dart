import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/wms_provider.dart';

class PackagingScreen extends ConsumerStatefulWidget {
  const PackagingScreen({super.key});

  @override
  ConsumerState<PackagingScreen> createState() => _PackagingScreenState();
}

class _PackagingScreenState extends ConsumerState<PackagingScreen> with WidgetsBindingObserver {
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
        final state = ref.read(packagingProvider);
        if (state.isScanning) {
          ref.read(packagingProvider.notifier).scanOrder(code);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packagingProvider);

    // Xử lý thông báo lỗi hoặc thành công
    ref.listen<PackagingState>(packagingProvider, (previous, next) {
      if (previous?.message != next.message && next.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message!),
            backgroundColor: next.hasError ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (!next.hasError && next.message!.contains('thành công')) {
          // Thành công thì reset sau 2 giây
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) ref.read(packagingProvider.notifier).reset();
          });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đóng gói & Vật tư'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(packagingProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: state.isScanning ? _buildScanner() : _buildPackagingForm(state),
    );
  }

  Widget _buildScanner() {
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
            child: const Text(
              'Quét mã vạch ĐƠN HÀNG cần đóng gói',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackagingForm(PackagingState state) {
    return Column(
      children: [
        // Thông tin đơn hàng
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mã vận đơn:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                state.orderTracking ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Danh sách vật tư
        Expanded(
          child: state.materials.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.materials.length,
                  itemBuilder: (context, index) {
                    final material = state.materials[index];
                    final isSelected = state.selected.any((s) => s.material.id == material.id);
                    final selectedItem = isSelected ? state.selected.firstWhere((s) => s.material.id == material.id) : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          ref.read(packagingProvider.notifier).toggleMaterial(material, val ?? false);
                        },
                        title: Text(material.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${material.unitPrice} đ / cái'),
                        secondary: isSelected
                            ? SizedBox(
                                width: 120,
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        if (selectedItem!.quantity > 1) {
                                          ref.read(packagingProvider.notifier).updateQuantity(material.id, selectedItem.quantity - 1);
                                        }
                                      },
                                    ),
                                    Text('${selectedItem?.quantity ?? 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        ref.read(packagingProvider.notifier).updateQuantity(material.id, selectedItem!.quantity + 1);
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : const Icon(Icons.inventory_2_outlined),
                      ),
                    );
                  },
                ),
        ),

        // Tổng phí & Nút xác nhận
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng phụ phí:', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${state.totalFee} đ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: state.isSubmitting || state.selected.isEmpty
                        ? null
                        : () {
                            ref.read(packagingProvider.notifier).submit();
                          },
                    child: state.isSubmitting
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                        : const Text('XÁC NHẬN ĐÓNG GÓI', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
