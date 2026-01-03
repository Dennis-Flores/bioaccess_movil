import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../auth/presentation/company_selection_screen.dart';
import '../../auth/data/fake_auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../terminal/data/fake_attendance_repository.dart';
import '../../terminal/domain/attendance_record.dart';

class AttendanceLogScreen extends StatefulWidget {
  final Company company;

  const AttendanceLogScreen({super.key, required this.company});

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  final _attendanceRepo = FakeAttendanceRepository();
  final _authRepo = FakeAuthRepository();

  late DateTime _day;
  late List<AttendanceRecord> _records;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _load();
  }

  void _load() {
    _records = _attendanceRepo.recordsForCompany(
      widget.company.id,
      day: _day,
    );
  }

  Future<void> _reload() async {
    setState(_load);
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_day.day.toString().padLeft(2, '0')}/'
        '${_day.month.toString().padLeft(2, '0')}/'
        '${_day.year}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgHeader,
        title: const Text('Marcaciones (demo)'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.company.fullName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Marcaciones del día: $dateStr',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _records.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay marcaciones registradas para este día (demo).',
                        style: TextStyle(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _records.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.bgSection),
                      itemBuilder: (context, index) {
                        final r = _records[index];
                        final AppUser? u = _authRepo.getById(r.userId);

                        final nombre = u?.nombreCompleto ?? 'Usuario desconocido';
                        final rut = u?.rut ?? '—';
                        final tipo = r.isEntry ? 'Ingreso' : 'Salida';
                        final timeStr = _formatTime(r.timestamp);

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: r.isEntry
                                ? AppColors.success.withOpacity(0.15)
                                : AppColors.warning.withOpacity(0.15),
                            child: Icon(
                              r.isEntry
                                  ? Icons.login
                                  : Icons.logout,
                              size: 18,
                              color: r.isEntry
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          title: Text(
                            nombre,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            'RUT: $rut · $tipo a las $timeStr',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
