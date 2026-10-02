import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Màn hình quét mã QR dùng chung (dán trên hộp bẫy ngoài hiện trường).
/// Trả về chuỗi mã QR đọc được qua Navigator.pop, hoặc null nếu người dùng huỷ.
///
/// Dùng qr_code_scanner_plus (zxing / Camera1 API trên Android) thay vì
/// mobile_scanner (CameraX/MLKit) vì các máy đời thấp (Oppo A5i, chip MediaTek
/// cũ, camera2 chỉ ở mức LEGACY) hay bị lỗi "genericError" khi CameraX mở
/// camera. zxing dùng API Camera1 cũ hơn nhưng ổn định hơn trên các máy này,
/// và cũng không phụ thuộc Google Play Services / MLKit.
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
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _handled = false; // tránh pop nhiều lần khi camera bắt được nhiều frame liên tiếp
  bool _flashOn = false;
  bool? _permissionGranted; // null = chưa rõ, true/false = đã có câu trả lời

  // Hot reload trên Android cần pause/resume lại camera, không thì camera bị treo.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller?.pauseCamera();
    } else if (Platform.isIOS) {
      _controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen(_onDetect);
  }

  void _onPermissionSet(QRViewController controller, bool granted) {
    if (!mounted) return;
    setState(() => _permissionGranted = granted);
  }

  void _onDetect(Barcode capture) {
    if (_handled) return;
    final raw = capture.code;
    if (raw == null || raw.trim().isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(raw.trim());
  }

  Future<void> _toggleFlash() async {
    try {
      await _controller?.toggleFlash();
      final status = await _controller?.getFlashStatus();
      if (mounted) setState(() => _flashOn = status ?? false);
    } catch (_) {
      // Một số máy/camera không hỗ trợ đèn flash -> bỏ qua, không chặn màn hình.
    }
  }

  void _retry() {
    setState(() => _permissionGranted = null);
    _controller?.resumeCamera();
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

  Widget _buildPermissionDeniedOverlay() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Chưa được cấp quyền Camera.\n'
            'Vào Cài đặt điện thoại → Ứng dụng → app này → Quyền → bật Camera, '
            'rồi quay lại màn hình này.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _retry, child: const Text('Thử lại')),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _enterManually,
            icon: const Icon(Icons.keyboard, color: Colors.white70),
            label: const Text('Nhập mã tay thay vì quét', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
            tooltip: 'Bật/tắt đèn flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_permissionGranted == false)
            _buildPermissionDeniedOverlay()
          else
            QRView(
              key: _qrKey,
              onQRViewCreated: _onQRViewCreated,
              onPermissionSet: _onPermissionSet,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.white,
                borderRadius: 16,
                borderLength: 28,
                borderWidth: 6,
                cutOutSize: 240,
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
