import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/ticket_provider.dart';

class TicketCreateScreen extends ConsumerStatefulWidget {
  final String? prefilledOrderId;

  const TicketCreateScreen({super.key, this.prefilledOrderId});

  @override
  ConsumerState<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends ConsumerState<TicketCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _orderIdController;
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Dropdown options
  final List<String> _issueTypes = ['Hư hỏng', 'Thiếu hàng', 'Khác'];
  String _selectedIssueType = 'Hư hỏng';

  @override
  void initState() {
    super.initState();
    _orderIdController = TextEditingController(text: widget.prefilledOrderId);
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        ref.read(ticketProvider.notifier).setImagePath(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(ticketProvider.notifier).submitTicket(
          orderId: _orderIdController.text,
          issueType: _selectedIssueType,
          description: _descriptionController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã ghi nhận sự cố, hệ thống SLA đã tạm dừng!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Lắng nghe lỗi để thông báo
    ref.listen<TicketState>(ticketProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo Sự cố'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hướng dẫn ──
                Card(
                  color: colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Việc báo cáo sự cố sẽ gửi thông báo lên hệ thống và tự động tạm dừng SLA của đơn hàng để tránh quá hạn.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Mã đơn hàng ──
                TextFormField(
                  controller: _orderIdController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Mã đơn hàng liên quan',
                    hintText: 'Nhập ID hoặc mã vận đơn...',
                    prefixIcon: Icon(Icons.qr_code_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng cung cấp mã đơn hàng để đối chiếu.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Loại sự cố ──
                DropdownButtonFormField<String>(
                  initialValue: _selectedIssueType,
                  decoration: const InputDecoration(
                    labelText: 'Phân loại sự cố',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _issueTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedIssueType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // ── Chi tiết mô tả ──
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết sự cố',
                    hintText: 'Nhập thông tin móp méo, bể vỡ, thất lạc hàng hoá...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng cung cấp chi tiết sự cố để xem xét.';
                    }
                    if (value.length < 10) {
                      return 'Nội dung mô tả quá ngắn.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Upload ảnh minh chứng ──
                Text(
                  'Hình ảnh chứng minh',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (ticketState.imagePath != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                          image: DecorationImage(
                            image: FileImage(File(ticketState.imagePath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        onPressed: () => ref.read(ticketProvider.notifier).clearImage(),
                      ),
                    ],
                  )
                else
                  InkWell(
                    onTap: () => _showImageSourceActionSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 36, color: colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            'Chụp ảnh hoặc Chọn từ thư viện',
                            style: TextStyle(color: colorScheme.primary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // ── Nút gửi ──
                FilledButton(
                  onPressed: ticketState.isLoading ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: ticketState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Gửi báo cáo sự cố',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
