class Employee {
  final int id;
  final String code;
  final String fullName;
  final String? phone;
  final String? area;

  Employee({
    required this.id,
    required this.code,
    required this.fullName,
    this.phone,
    this.area,
  });

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: j['id'] as int,
        code: j['code'] as String? ?? '',
        fullName: j['full_name'] as String? ?? '',
        phone: j['phone'] as String?,
        area: j['area'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'full_name': fullName,
        'phone': phone,
        'area': area,
      };
}
