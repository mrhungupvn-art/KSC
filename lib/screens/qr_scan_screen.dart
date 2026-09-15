import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Màn hình quét mã QR dùng chung (dán trên hộp bẫy ngoài hiện trường).
/// Trả về chuỗi mã QR đọc được qua Navigator.pop, hoặc null nếu người dùng huỷ.
///
/// [title]: tiêu đề hiển thị trên thanh AppBar.
/// [hint]: dòng gợi ý phía dưới khung quét.
class QrScanScreen extends StatefulWidget {
  final String title;
  final String? hint;
  const QrScanScreen({super.key, this.title = 'Quét mã QR', this.hint});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false; // tránh pop nhiều lần khi camera bắt được nhiều frame liên tiếp

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    final raw = codes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(raw.trim());
  }

  void _enterManually() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nhập mã QR thủ công'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Mã in bên dưới tem QR',
            hintText: 'Vd: KSC7Q9F2A',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (code != null && code.isNotEmpty && mounted) {
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Bật/tắt đèn flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            // Mặc định mobile_scanner chỉ hiện 1 icon dấu chấm than khi camera lỗi,
            // không nói rõ nguyên nhân -> người dùng tưởng máy hỏng. Hiện rõ lý do
            // + nút thử lại để tự khắc phục được (thường là do chưa cấp quyền Camera).
            errorBuilder: (context, error, child) {
              String msg;
              switch (error.errorCode) {
                case MobileScannerErrorCode.permissionDenied:
                  msg = 'Chưa được cấp quyền Camera.\n'
                      'Vào Cài đặt điện thoại → Ứng dụng → app này → Quyền → bật Camera, '
                      'rồi quay lại màn hình này.';
                  break;
                case MobileScannerErrorCode.unsupported:
                  msg = 'Thiết bị này không hỗ trợ quét mã QR bằng camera.';
                  break;
                default:
                  msg = 'Không mở được camera (${error.errorCode.name}).\n'
                      'Hãy tắt các app khác đang dùng camera rồi thử lại.';
              }
              return Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: () => _controller.start(), child: const Text('Thử lại')),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _enterManually,
                      icon: const Icon(Icons.keyboard, color: Colors.white70),
                      label: const Text('Nhập mã tay thay vì quét', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              );
            },
          ),
          // Khung ngắm ở giữa để nhân viên căn mã QR cho dễ.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.hint ?? 'Đưa camera vào mã QR dán trên hộp bẫy.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _enterManually,
                    icon: const Icon(Icons.keyboard, color: Colors.white),
                    label: const Text('Tem mờ/hỏng? Nhập mã tay', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
