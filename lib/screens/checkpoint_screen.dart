import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/job_point.dart';
import '../services/job_service.dart';
import 'qr_scan_screen.dart';

class CheckpointScreen extends StatefulWidget {
  final int jobId;
  final JobPoint point;
  const CheckpointScreen({super.key, required this.jobId, required this.point});

  @override
  State<CheckpointScreen> createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends State<CheckpointScreen> {
  final _jobService = JobService();
  final _actionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _mouseCtrl = TextEditingController(text: '0');
  final _otherPestCtrl = TextEditingController(text: '0');
  final _baitPlacedCtrl = TextEditingController(text: '0');
  final _baitEatenCtrl = TextEditingController(text: '0');
  final _baitOtherSignCtrl = TextEditingController(text: '0');
  final _baitReplacedCtrl = TextEditingController(text: '0');
  String _result = 'NONE';
  String _photoType = 'LOCATION';
  bool _saving = false;
  bool _uploadingPhoto = false;

  // Ảnh chụp trong phiên này. Ảnh đầu tiên được gửi cùng kết quả để
  // server có thể ghi nhận luôn dữ liệu hiện trường + ảnh + thời điểm.
  final List<String> _localPhotoPaths = [];

  // ---- Kiểm soát QR: điểm nào có mã QR thì bắt buộc quét đúng mã trước khi
  // được phép lưu kết quả lần đầu, để đảm bảo nhân viên có mặt đúng vị trí.
  bool get _requiresQr => (widget.point.qrCode ?? '').isNotEmpty;
  bool _qrVerified = false;
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    _qrVerified = !_requiresQr || widget.point.result != null;
    final r = widget.point.result;
    if (r != null) {
      _result = r.result;
      _actionCtrl.text = r.actionTaken ?? '';
      _notesCtrl.text = r.notes ?? '';
      _mouseCtrl.text = r.mouseCaughtCount.toString();
      _otherPestCtrl.text = r.otherPestCount.toString();
      _baitPlacedCtrl.text = r.baitPlacedCount.toString();
      _baitEatenCtrl.text = r.baitEatenCount.toString();
      _baitOtherSignCtrl.text = r.baitOtherSignCount.toString();
      _baitReplacedCtrl.text = r.baitReplacedCount.toString();
    }
  }

  @override
  void dispose() {
    _actionCtrl.dispose();
    _notesCtrl.dispose();
    _mouseCtrl.dispose();
    _otherPestCtrl.dispose();
    _baitPlacedCtrl.dispose();
    _baitEatenCtrl.dispose();
    _baitOtherSignCtrl.dispose();
    _baitReplacedCtrl.dispose();
    super.dispose();
  }

  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _scanQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScanScreen(
          title: 'Quét QR — ${widget.point.pointNumber}. ${widget.point.name}',
          hint: 'Quét mã QR dán trên hộp bẫy tại điểm này để xác nhận đúng vị trí.',
        ),
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;

    final matches = code.trim().toUpperCase() == (widget.point.qrCode ?? '').toUpperCase();
    setState(() {
      _scannedCode = code.trim();
      _qrVerified = matches;
    });
    _snack(matches
        ? 'Đã xác nhận đúng vị trí.'
        : 'Mã QR quét được không khớp với điểm kiểm soát này — kiểm tra lại đúng hộp bẫy.');
  }

  Future<void> _save() async {
    if (_requiresQr && !_qrVerified) {
      _snack('Vui lòng quét đúng mã QR trên hộp bẫy trước khi lưu kết quả.');
      return;
    }
    setState(() => _saving = true);
    try {
      final photoPath = _localPhotoPaths.isNotEmpty ? _localPhotoPaths.first : null;
      final sentNow = await _jobService.savePointResult(
        widget.jobId,
        widget.point.id,
        _result,
        visitId: widget.point.visitId,
        mouseCaughtCount: _int(_mouseCtrl),
        otherPestCount: _int(_otherPestCtrl),
        baitPlacedCount: _int(_baitPlacedCtrl),
        baitEatenCount: _int(_baitEatenCtrl),
        baitOtherSignCount: _int(_baitOtherSignCtrl),
        baitReplacedCount: _int(_baitReplacedCtrl),
        actionTaken: _actionCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        qrCode: _scannedCode,
        photoPath: photoPath,
        photoType: _photoType,
      );

      // Khi có ảnh LOCATION và đã có visit, đánh dấu kết thúc lượt ghé.
      // Nếu offline, save_point_result sẽ được đồng bộ trước; thao tác này
      // được xếp tiếp theo trong hàng đợi.
      if (photoPath != null && _photoType == 'LOCATION' && widget.point.visitId != null) {
        // Khi offline, completePoint được xếp sau save_point_result trong cùng
        // hàng đợi nên thứ tự vẫn đúng.
        await _jobService.completePoint(widget.jobId, widget.point.id, widget.point.visitId!);
      }

      // Nếu người dùng chụp thêm ảnh, gửi các ảnh còn lại sau khi kết quả đã có.
      for (var i = 1; i < _localPhotoPaths.length; i++) {
        try {
          await _jobService.uploadPhoto(
            widget.jobId,
            widget.point.id,
            _localPhotoPaths[i],
            photoType: 'EVIDENCE',
          );
        } catch (_) {
          // Ảnh lỗi/mất mạng sẽ được xử lý bởi hàng đợi của JobService.
        }
      }

      _snack(sentNow ? 'Đã lưu đầy đủ kết quả hiện trường.' : 'Đã lưu — sẽ đồng bộ khi có mạng.');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Có lỗi xảy ra.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 65,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (xfile == null) return;
    setState(() => _localPhotoPaths.add(xfile.path));
    _snack('Đã chụp ảnh và tối ưu dung lượng. Ảnh sẽ được gửi cùng kết quả khi bấm Lưu.');
  }

  Widget _numberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.numbers),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serverPhotos = widget.point.result?.photos ?? [];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.point.pointNumber}. ${widget.point.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Khu vực: ${widget.point.zoneName}', style: const TextStyle(color: Colors.grey)),
          if (widget.point.trapType != null) Text('Loại bẫy: ${widget.point.trapType}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          if (_requiresQr) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _qrVerified ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _qrVerified ? Colors.green.shade200 : Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(_qrVerified ? Icons.verified : Icons.qr_code_scanner,
                      color: _qrVerified ? Colors.green : Colors.orange.shade800),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _qrVerified
                          ? 'Đã xác nhận đúng hộp bẫy bằng QR.'
                          : 'Bắt buộc quét mã QR trên hộp bẫy trước khi lưu kết quả.',
                      style: TextStyle(color: _qrVerified ? Colors.green.shade900 : Colors.orange.shade900),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _scanQr,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(_qrVerified ? 'Quét lại' : 'Quét QR'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text('Kết quả kiểm tra', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...PointResult.labels.entries.map(
            (e) => RadioListTile<String>(
              value: e.key,
              groupValue: _result,
              onChanged: (v) => setState(() => _result = v!),
              title: Text(e.value),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Số liệu hiện trường', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _numberField(_mouseCtrl, 'Số chuột dính bẫy'),
          _numberField(_otherPestCtrl, 'Số loài khác ghi nhận'),
          _numberField(_baitPlacedCtrl, 'Số viên bả đã đặt'),
          _numberField(_baitEatenCtrl, 'Số viên bả bị ăn'),
          _numberField(_baitOtherSignCtrl, 'Dấu hiệu khác tại trạm bả'),
          _numberField(_baitReplacedCtrl, 'Số viên bả thay mới'),
          const SizedBox(height: 4),
          TextField(
            controller: _actionCtrl,
            decoration: const InputDecoration(labelText: 'Xử lý đã thực hiện (nếu có)', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_saving || (_requiresQr && !_qrVerified)) ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Đang lưu...' : 'Lưu kết quả'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _photoType,
            decoration: const InputDecoration(
              labelText: 'Loại ảnh đầu tiên',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'LOCATION', child: Text('Vị trí đặt bẫy')),
              DropdownMenuItem(value: 'TRAP', child: Text('Hộp bẫy / trạm bả')),
              DropdownMenuItem(value: 'RODENT', child: Text('Chuột / dấu vết')),
              DropdownMenuItem(value: 'EVIDENCE', child: Text('Ảnh bằng chứng')),
              DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
            ],
            onChanged: (v) => setState(() => _photoType = v ?? 'LOCATION'),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ảnh bằng chứng', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _saving ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Chụp ảnh'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...serverPhotos.map(
                (url) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url.startsWith('http') ? url : '$kMediaBaseUrl$url',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              ..._localPhotoPaths.map(
                (path) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    if (_uploadingPhoto)
                      const Positioned.fill(
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
