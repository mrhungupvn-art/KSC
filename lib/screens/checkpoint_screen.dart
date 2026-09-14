import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/job_point.dart';
import '../services/job_service.dart';

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
  String _result = 'NONE';
  bool _saving = false;
  bool _uploadingPhoto = false;

  // Ảnh vừa chụp trong phiên này (chưa chắc đã upload xong nếu mất mạng),
  // hiển thị gộp cùng ảnh đã có sẵn trả về từ server.
  final List<String> _localPhotoPaths = [];

  @override
  void initState() {
    super.initState();
    final r = widget.point.result;
    if (r != null) {
      _result = r.result;
      _actionCtrl.text = r.actionTaken ?? '';
      _notesCtrl.text = r.notes ?? '';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final sentNow = await _jobService.recordPoint(
        widget.jobId,
        widget.point.id,
        _result,
        actionTaken: _actionCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );
      _snack(sentNow ? 'Đã lưu kết quả.' : 'Đã lưu — sẽ đồng bộ khi có mạng.');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Có lỗi xảy ra.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _takePhoto() async {
    final r = widget.point.result;
    if (r == null) {
      _snack('Hãy lưu kết quả trước khi chụp ảnh.');
      return;
    }
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1600);
    if (xfile == null) return;

    setState(() {
      _uploadingPhoto = true;
      _localPhotoPaths.add(xfile.path);
    });
    try {
      final sentNow = await _jobService.uploadPhoto(widget.jobId, widget.point.id, xfile.path);
      _snack(sentNow ? 'Đã tải ảnh lên.' : 'Đã lưu ảnh trên máy — sẽ tự tải lên khi có mạng.');
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Không tải được ảnh.');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
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
          const SizedBox(height: 8),
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
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Đang lưu...' : 'Lưu kết quả'),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ảnh bằng chứng', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _uploadingPhoto ? null : _takePhoto,
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
