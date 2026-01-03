import 'package:uuid/uuid.dart';
import '../domain/attendance_record.dart';

class FakeAttendanceRepository {
  static final List<AttendanceRecord> _records = [];
  static final Uuid _uuid = const Uuid();

  /// Agregar una marcación (demo)
  AttendanceRecord addRecord({
    required String userId,
    required String companyId,
    required DateTime timestamp,
    required bool isEntry,
  }) {
    final record = AttendanceRecord(
      id: _uuid.v4(),
      userId: userId,
      companyId: companyId,
      timestamp: timestamp,
      isEntry: isEntry,
    );

    _records.add(record);
    return record;
  }

  /// Obtener marcaciones por empresa (opcionalmente por día)
  List<AttendanceRecord> recordsForCompany(
    String companyId, {
    DateTime? day,
  }) {
    Iterable<AttendanceRecord> list =
        _records.where((r) => r.companyId == companyId);

    if (day != null) {
      list = list.where((r) =>
          r.timestamp.year == day.year &&
          r.timestamp.month == day.month &&
          r.timestamp.day == day.day);
    }

    return list.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Obtener marcaciones por usuario
  List<AttendanceRecord> recordsForUser(String userId) {
    final list = _records.where((r) => r.userId == userId);

    return list.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}
