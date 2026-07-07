import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/wms_provider.dart';

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    
    // Tải danh sách các phiên kiểm kê
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auditProvider.notifier).loadAudits();
    });
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
        final state = ref.read(auditProvider);
        if (state.step == AuditStep.scanLocation) {
          ref.read(auditProvider.notifier).scanLocation(code);
        } else if (state.step == AuditStep.scanOrders) {
          ref.read(auditProvider.notifier).scanOrder(code);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditProvider);

    // Xử lý thông báo
    ref.listen<AuditState>(auditProvider, (previous, next) {
      if (previous?.message != next.message && next.message != null && next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm kê Kho'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(auditProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AuditState state) {
    switch (state.step) {
      case AuditStep.selectAudit:
        return _buildAuditList(state);
      case AuditStep.scanLocation:
        return _buildLocationScanner();
      case AuditStep.scanOrders:
        return _buildOrdersScanner(state);
      case AuditStep.submitting:
        return const Center(child: CircularProgressIndicator());
      case AuditStep.results:
        return _buildResults(state);
    }
  }

  Widget _buildAuditList(AuditState state) {
    if (state.audits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Không có phiên kiểm kê nào đang diễn ra.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(auditProvider.notifier).loadAudits(),
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.audits.length,
      itemBuilder: (context, index) {
        final audit = state.audits[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.assignment, color: Colors.white),
            ),
            title: Text(audit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(audit.description ?? 'Đang thực hiện...'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(auditProvider.notifier).selectAudit(audit.id),
          ),
        );
      },
    );
  }

  Widget _buildLocationScanner() {
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
              'Hãy quét mã vạch trên KỆ HÀNG bạn muốn kiểm kê',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersScanner(AuditState state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kệ hàng: ${state.locationBarcode}', style: Theme.of(context).textTheme.titleMedium),
              Text('Đã quét: ${state.scannedTrackings.length}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Danh sách mã đã quét:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: state.scannedTrackings.length,
                  itemBuilder: (context, index) {
                    final tracking = state.scannedTrackings.reversed.toList()[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.inventory_2, size: 20),
                      title: Text(tracking),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => ref.read(auditProvider.notifier).submit(),
                    child: const Text('GỬI KẾT QUẢ', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults(AuditState state) {
    final result = state.result;
    if (result == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Icon(Icons.analytics, size: 64, color: Colors.blue),
          const SizedBox(height: 24),
          Text('Kết quả Kiểm kê', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  'Khớp',
                  result.matched,
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultCard(
                  'Thiếu',
                  result.missing,
                  Colors.red,
                  Icons.cancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultCard(
                  'Sai vị trí',
                  result.wrong,
                  Colors.orange,
                  Icons.warning,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () => ref.read(auditProvider.notifier).reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Kiểm kê vị trí khác', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
