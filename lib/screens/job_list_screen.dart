import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../core/session_manager.dart';
import '../models/job.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart';
import '../services/sync_service.dart';
import '../widgets/status_badge.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final _jobService = JobService();
  DateTime _selectedDate = DateTime.now();
  List<Job> _jobs = [];
  bool _loading = true;
  bool _fromCache = false;
  String? _error;
  int _pendingCount = 0;
  String _employeeName = '';

  @override
  void initState() {
    super.initState();
    SyncService.instance.start();
    SyncService.instance.statusStream.listen((_) => _refreshPendingCount());
    _load();
    SessionManager.instance.getEmployee().then((e) {
      if (e != null && mounted) setState(() => _employeeName = e.fullName);
    });
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (jobs, fromCache) = await _jobService.getJobs(date: _dateStr);
      setState(() {
        _jobs = jobs;
        _fromCache = fromCache;
      });
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Không tải được danh sách công việc.');
    } finally {
      setState(() => _loading = false);
    }
    _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    final c = await _jobService.pendingCount();
    if (mounted) setState(() => _pendingCount = c);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _load();
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_employeeName.isEmpty ? 'Công việc của tôi' : _employeeName),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: _pickDate),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          if (_pendingCount > 0)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_pendingCount thao tác đang chờ đồng bộ khi có mạng.',
                      style: const TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (_fromCache)
            Container(
              width: double.infinity,
              color: Colors.blueGrey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text('Đang xem dữ liệu đã lưu offline (chưa kết nối được máy chủ).',
                  style: TextStyle(fontSize: 13)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.event, size: 18),
                const SizedBox(width: 6),
                Text(DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate)),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_jobs.isEmpty) {
      return const Center(child: Text('Không có công việc nào trong ngày này.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final job = _jobs[i];
          return Card(
            child: ListTile(
              title: Text(job.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.customerAddress ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('#${job.jobNo} · ${job.jobType}', style: const TextStyle(fontSize: 12)),
                ],
              ),
              trailing: StatusBadge(code: job.status, label: Job.statusLabels[job.status] ?? job.status),
              isThreeLine: true,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
                );
                _load();
              },
            ),
          );
        },
      ),
    );
  }
}
