import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';


import '../../../core/network/api_client.dart';
import '../providers/shipper_orders_provider.dart';

class ShipperScanScreen extends ConsumerStatefulWidget {
  const ShipperScanScreen({super.key});

  @override
  ConsumerState<ShipperScanScreen> createState() => _ShipperScanScreenState();
}

class _ShipperScanScreenState extends ConsumerState<ShipperScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String code = barcodes.first.rawValue ?? '';
    if (code.isEmpty) return;

    _isProcessing = true;
    _scannerController.stop();

    String trackingNumber = code;
    try {
      final parsed = jsonDecode(code);
      if (parsed['tn'] != null) trackingNumber = parsed['tn'];
    } catch (_) {}

    await _fetchOrderAndShowSheet(trackingNumber);
  }

  Future<void> _fetchOrderAndShowSheet(String trackingNumber) async {
    try {
      final dio = ref.read(dioProvider);
      
      // Gọi API GET /orders/me và lọc ra đơn tương ứng
      final response = await dio.get('/orders/me');
      final data = response.data['data'] as List;
      
      final orderJson = data.firstWhere(
        (o) => o['tracking_number'] == trackingNumber,
        orElse: () => null,
      );

      if (orderJson == null) {
        throw Exception('Không tìm thấy đơn hàng này trong danh sách của bạn!');
      }

      if (mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _DeliveryBottomSheet(order: orderJson),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      _isProcessing = false;
      if (mounted) _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã giao hàng')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Đưa mã QR đơn hàng vào khung hình',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
            ),
          )
        ],
      ),
    );
  }
}

class _DeliveryBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;

  const _DeliveryBottomSheet({required this.order});

  @override
  ConsumerState<_DeliveryBottomSheet> createState() => _DeliveryBottomSheetState();
}

class _DeliveryBottomSheetState extends ConsumerState<_DeliveryBottomSheet> {
  bool _isLoading = false;
  String? _returnReason;

  Future<void> _updateStatus(String action) async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      
      if (action == 'complete') {
        // Có thể bổ sung tính năng chụp ảnh ký nhận ở đây
        await dio.patch('/orders/${widget.order['id']}/complete', data: {
          'delivery_image_url': 'http://example.com/signature.png' // Mock
        });
      } else {
        if (_returnReason == null || _returnReason!.isEmpty) {
          throw Exception('Vui lòng nhập lý do hoàn hàng');
        }
        await dio.patch('/orders/${widget.order['id']}/return', data: {
          'reason': _returnReason
        });
      }
      
      // Refresh list
      ref.read(shipperOrdersProvider.notifier).refresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(action == 'complete' ? 'Giao hàng thành công!' : 'Đã báo hoàn hàng!'), backgroundColor: Colors.green),
        );
        context.pop(); // Đóng BottomSheet
        context.pop(); // Quay về dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Chi tiết giao hàng', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Mã: ${widget.order['tracking_number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Người nhận: ${widget.order['receiver_name']} - ${widget.order['receiver_phone']}'),
          Text('Địa chỉ: ${widget.order['receiver_address']}'),
          const SizedBox(height: 8),
          Text('COD thu khách: ${widget.order['cod_amount']} đ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Lý do (Bắt buộc nếu hoàn hàng)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => _returnReason = val,
          ),
          
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('return'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    child: const Text('Hoàn hàng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('complete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Thành công'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
