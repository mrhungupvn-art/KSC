import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/employee_report.dart';
import '../services/report_service.dart';

class EmployeeReportScreen extends StatefulWidget {
  const EmployeeReportScreen({super.key});

  @override
  State<EmployeeReportScreen> createState() => _EmployeeReportScreenState();
}

class _EmployeeReportScreenState extends State<EmployeeReportScreen> {
  final _service = ReportService();
  DateTime _month = DateTime.now();
  EmployeeReport? _report;
  bool _loading = true;
  String? _error;

  String get _monthText => DateFormat('yyyy-MM').format(_month);

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
      final r = await _service.getMonthlyReport(_monthText);
      if (mounted) setState(() => _report = r);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : 'Không tải được thống kê công việc.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2024, 1),
      lastDate: DateTime(DateTime.now().year + 1, 12),
      helpText: 'Chọn tháng báo cáo',
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _load();
    }
  }

  int _v(String k) => _report?.value(k) ?? 0;
  double _p(String k) => _report?.percent(k) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả làm việc'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: _pickMonth),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Thống kê tháng $_monthText',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.7,
                        children: [
                          _card('Công việc', _v('jobs'), Icons.assignment),
                          _card('Hoàn thành', _v('done_jobs'), Icons.done_all),
                          _card('Lượt quét QR', _v('scan_visits'), Icons.qr_code_scanner),
                          _card('Vị trí đã ghé', _v('unique_visited_points'), Icons.location_on),
                          _card('Chuột dính bẫy', _v('mouse_caught'), Icons.pest_control),
                          _card('Loài khác', _v('other_pest'), Icons.bug_report),
                          _card('Bả đã đặt', _v('bait_placed'), Icons.inventory_2),
                          _card('Bả bị ăn', _v('bait_eaten'), Icons.restaurant),
                          _card('Bả thay mới', _v('bait_replaced'), Icons.autorenew),
                          _card('Dấu hiệu khác', _v('bait_other_sign'), Icons.warning_amber),
                          _card('Thời gian làm việc', _durationText(_v('duration_seconds')), Icons.timer),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.track_changes),
                          title: const Text('Độ phủ kiểm tra'),
                          subtitle: Text(
                            '${_v('unique_visited_points')} / ${_v('expected_points')} vị trí dự kiến',
                          ),
                          trailing: Text(
                            '${_p('coverage_percent').toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Kết quả kiểm soát',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              _row('Không phát hiện', _v('none_points')),
                              _row('Có dấu hiệu', _v('sign_points')),
                              _row('Đã xử lý', _v('handled_points')),
                              _row('Cần theo dõi', _v('monitor_points')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Công việc trong tháng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...(_report?.jobs ?? const <ReportJob>[]).map(
                        (j) => Card(
                          child: ListTile(
                            title: Text('#${j.jobNo} · ${j.customerName}'),
                            subtitle: Text(
                              '${j.date} · ${j.visits} lượt ghé · ${j.visitedPoints} vị trí · '
                              '${j.checkedPoints} kết quả · ${j.mouseCaught} chuột · ${j.baitEaten} bả ăn',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _durationText(int seconds) {
    if (seconds <= 0) return '0 phút';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}g ${m}p';
    return '${m} phút';
  }

  Widget _card(String title, dynamic value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22),
            const Spacer(),
            Text(value.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
