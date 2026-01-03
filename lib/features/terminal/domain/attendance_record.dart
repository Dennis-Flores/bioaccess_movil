class AttendanceRecord {
  final String id;
  final String userId;
  final String companyId;
  final DateTime timestamp;
  final bool isEntry; // true = ingreso, false = salida

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.timestamp,
    required this.isEntry,
  });
}
