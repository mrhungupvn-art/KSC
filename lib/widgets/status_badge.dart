import 'package:flutter/material.dart';

const _jobStatusColor = {
  'PENDING': Colors.grey,
  'IN_PROGRESS': Colors.orange,
  'DONE': Colors.green,
  'OVERDUE': Colors.red,
  'CANCELLED': Colors.grey,
};

const _resultColor = {
  'NONE': Colors.green,
  'SIGN_DETECTED': Colors.red,
  'HANDLED': Colors.blue,
  'MONITOR': Colors.orange,
};

class StatusBadge extends StatelessWidget {
  final String code;
  final String label;
  final bool isJobStatus; // true: dùng bảng màu job status, false: dùng bảng màu kết quả điểm

  const StatusBadge({super.key, required this.code, required this.label, this.isJobStatus = true});

  @override
  Widget build(BuildContext context) {
    final color = (isJobStatus ? _jobStatusColor[code] : _resultColor[code]) ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
