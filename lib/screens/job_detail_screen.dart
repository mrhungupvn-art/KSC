import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api_client.dart';
import '../models/job.dart';
import '../models/job_point.dart';
import '../services/job_service.dart';
import '../widgets/status_badge.dart';
import 'checkpoint_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _jobService = JobService();
  JobDetail? _detail;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _jobService.getJobDetail(widget.jobId);
      setState(() => _detail = d);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Không tải được chi tiết công việc.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      final sentNow = await _jobService.accept(widget.jobId);
      _snack(sentNow ? 'Đã nhận việc.' : 'Đã lưu — sẽ đồng bộ khi có mạng.');
      await _load();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Có lỗi xảy ra.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    double? lat, lng;
    try {
      lat = null;
      lng = null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
        if (await Geolocator.isLocationServiceEnabled()) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
          );
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }
    } catch (_) {
      // Không lấy được GPS thì vẫn cho bắt đầu công việc, chỉ là thiếu toạ độ.
    }
    try {
      final sentNow = await _jobService.start(widget.jobId, lat: lat, lng: lng);
      _snack(sentNow ? 'Đã bắt đầu công việc.' : 'Đã lưu — sẽ đồng bộ khi có mạng.');
      await _load();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Có lỗi xảy ra.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _customerConfirm() async {
    setState(() => _busy = true);
    try {
      final sentNow = await _jobService.customerConfirm(widget.jobId);
      _snack(sentNow ? 'Đã ghi nhận xác nhận của khách hàng.' : 'Đã lưu — sẽ đồng bộ khi có mạng.');
      await _load();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Có lỗi xảy ra.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete() async {
    final points = _detail?.points ?? [];
    final unrecorded = points.where((p) => p.result == null).length;
    if (unrecorded > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Còn điểm chưa ghi kết quả'),
          content: Text('Còn $unrecorded điểm kiểm soát chưa có kết quả. Vẫn muốn hoàn thành công việc?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Để sau')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Vẫn hoàn thành')),
          ],
        ),
      );
      if (confirm != true) return;
    }
    setState(() => _busy = true);
    try {
      final sentNow = await _jobService.complete(widget.jobId);
      _snack(sentNow ? 'Đã hoàn thành công việc.' : 'Đã lưu — sẽ đồng bộ khi có mạng.');
      await _load();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Có lỗi xảy ra.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_detail == null ? 'Chi tiết công việc' : '#${_detail!.job.jobNo}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _detail == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Thử lại')),
                    ]),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    final job = d.job;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (d.fromCache)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              color: Colors.blueGrey.shade50,
              child: const Text('Đang xem dữ liệu offline, một số thao tác sẽ đồng bộ sau khi có mạng.'),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(job.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              StatusBadge(code: job.status, label: Job.statusLabels[job.status] ?? job.status),
            ],
          ),
          if (job.customerAddress != null) ...[
            const SizedBox(height: 4),
            Text(job.customerAddress!),
          ],
          if (job.customerPhone != null) ...[
            const SizedBox(height: 4),
            Text('SĐT: ${job.customerPhone}'),
          ],
          const SizedBox(height: 4),
          Text('Loại công việc: ${job.jobType}'),
          if (job.notes != null && job.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Ghi chú: ${job.notes}'),
          ],
          const Divider(height: 32),
          _buildStepper(job),
          const Divider(height: 32),
          Text('Điểm kiểm soát (${d.points.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...d.points.map(_buildPointTile),
          const SizedBox(height: 24),
          _buildActionButtons(job),
        ],
      ),
    );
  }

  Widget _buildStepper(Job job) {
    final steps = [
      ('Nhận việc', job.acceptedAt != null),
      ('Bắt đầu', job.startedAt != null),
      ('Ghi kết quả', job.recordedAt != null),
      ('Chụp ảnh', job.photographedAt != null),
      ('Khách xác nhận', job.customerConfirmedAt != null),
      ('Hoàn thành', job.completedAt != null),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: steps
          .map((s) => Chip(
                avatar: Icon(s.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18, color: s.$2 ? Colors.green : Colors.grey),
                label: Text(s.$1),
                backgroundColor: s.$2 ? Colors.green.shade50 : null,
              ))
          .toList(),
    );
  }

  Widget _buildPointTile(JobPoint p) {
    final hasResult = p.result != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${p.pointNumber}. ${p.name}'),
        subtitle: Text('${p.zoneName}${p.trapType != null ? ' · ${p.trapType}' : ''}'),
        trailing: hasResult
            ? StatusBadge(code: p.result!.result, label: PointResult.labels[p.result!.result] ?? p.result!.result, isJobStatus: false)
            : const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CheckpointScreen(jobId: widget.jobId, point: p)),
          );
          _load();
        },
      ),
    );
  }

  Widget _buildActionButtons(Job job) {
    final buttons = <Widget>[];

    if (job.acceptedAt == null) {
      buttons.add(FilledButton.icon(
        onPressed: _busy ? null : _accept,
        icon: const Icon(Icons.check),
        label: const Text('Nhận việc'),
      ));
    } else if (job.startedAt == null) {
      buttons.add(FilledButton.icon(
        onPressed: _busy ? null : _start,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Bắt đầu (ghi GPS)'),
      ));
    } else {
      if (job.customerConfirmedAt == null) {
        buttons.add(OutlinedButton.icon(
          onPressed: _busy ? null : _customerConfirm,
          icon: const Icon(Icons.person_pin_circle),
          label: const Text('Khách hàng đã xác nhận'),
        ));
      }
      if (job.completedAt == null) {
        buttons.add(FilledButton.icon(
          onPressed: _busy ? null : _complete,
          icon: const Icon(Icons.done_all),
          label: const Text('Hoàn thành công việc'),
        ));
      }
    }

    if (buttons.isEmpty) {
      return const Center(child: Text('Công việc đã hoàn thành.', style: TextStyle(color: Colors.green)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in buttons) ...[b, const SizedBox(height: 8)],
      ],
    );
  }
}
