import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_service.dart';
import '../../../core/theme.dart';
import '../../auth/domain/app_user.dart';
import 'admin_users_screen.dart';

class AdminUserMonthSummaryScreen extends StatefulWidget {
  final AdminUserItem userItem;
  final AppUser adminUser;

  const AdminUserMonthSummaryScreen({
    super.key,
    required this.userItem,
    required this.adminUser,
  });

  @override
  State<AdminUserMonthSummaryScreen> createState() =>
      _AdminUserMonthSummaryScreenState();
}

class _AdminUserMonthSummaryScreenState
    extends State<AdminUserMonthSummaryScreen> {
  late DateTime _selectedMonth;

  bool _loading = true;
  String? _error;

  Map<String, dynamic> _totals = {};
  List<Map<String, dynamic>> _days = [];

  int _toInt(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;

  int get _attendancePercent {
    final present = _toInt(_totals['days_present']);
    final absent = _toInt(_totals['days_absent']);
    final denom = present + absent;
    if (denom <= 0) return 0;
    final perc = (present * 100 / denom).round();
    return perc.clamp(0, 100);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = widget.userItem.id;

      final res = await ApiService.getUserMonthSummary(
        userId: userId,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );

      if (res['ok'] == true &&
          res['totals'] is Map &&
          res['days'] is List) {
        final totals = Map<String, dynamic>.from(res['totals']);
        final daysList = (res['days'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        setState(() {
          _totals = totals;
          _days = daysList;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['error']?.toString() ??
              'No se pudo obtener el resumen mensual del usuario.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _loading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
    _load();
  }

  Future<void> _export(String format) async {
    final url = ApiService.buildUserMonthExportUrl(
      userId: widget.userItem.id,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
      format: format,
    );

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace de exportación.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.userItem.nombreCompleto;
    final rut = widget.userItem.rut;
    final company = widget.adminUser.companyName ?? '';

    final monthLabel =
        '${_selectedMonth.month.toString().padLeft(2, '0')}-${_selectedMonth.year}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Resumen mensual usuario'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cabecera
              Card(
                color: AppColors.bgSection,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (rut.isNotEmpty)
                        Text(
                          'RUT: $rut',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      if (company.isNotEmpty)
                        Text(
                          company,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mes seleccionado',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _loading ? null : () => _changeMonth(-1),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text(
                                monthLabel,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                onPressed: _loading ? null : () => _changeMonth(1),
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (_loading)
                Card(
                  color: AppColors.bgSection,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_error != null)
                Card(
                  color: AppColors.bgSection,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildDashboardCard(),
                const SizedBox(height: 12),
                _buildPermissionsCard(),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _export('pdf'),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar PDF'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _export('xlsx'),
                        icon: const Icon(Icons.table_view),
                        label: const Text('Exportar Excel'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text(
                  'Detalle diario',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ..._days.map(_buildDayTile),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard() {
    final daysPresent = _toInt(_totals['days_present']);
    final daysAbsent = _toInt(_totals['days_absent']);
    final daysNoSchedule = _toInt(_totals['days_no_schedule']);
    final workedMinutesNet = _toInt(_totals['worked_minutes_net']);
    final lateMinutes = _toInt(_totals['late_minutes']);
    final earlyLeaveMinutes = _toInt(_totals['early_leave_minutes']);
    final permissionDays = _toInt(_totals['permission_days_total']);

    return Card(
      color: AppColors.bgSection,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asistencia del mes',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_attendancePercent%',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _attendancePercent / 100.0,
                        strokeWidth: 7,
                      ),
                      Center(
                        child: Text(
                          '$_attendancePercent%',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _miniMetric(
                  label: 'Días presente',
                  value: '$daysPresent',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _miniMetric(
                  label: 'Días ausente',
                  value: '$daysAbsent',
                  icon: Icons.cancel,
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniMetric(
                  label: 'Sin horario',
                  value: '$daysNoSchedule',
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _miniMetric(
                  label: 'Días con permiso',
                  value: '$permissionDays',
                  icon: Icons.event_available,
                  color: Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniMetric(
                  label: 'Min. trabajados',
                  value: '$workedMinutesNet',
                  icon: Icons.work_history,
                  color: Colors.cyan,
                ),
                const SizedBox(width: 8),
                _miniMetric(
                  label: 'Atrasos (min)',
                  value: '$lateMinutes',
                  icon: Icons.alarm,
                  color: Colors.yellowAccent.shade700,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniMetric(
                  label: 'Salidas ant. (min)',
                  value: '$earlyLeaveMinutes',
                  icon: Icons.logout,
                  color: Colors.pinkAccent,
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard() {
    final pbtRaw = _totals['permissions_by_type'];
    final Map<String, int> pbt = {};
    if (pbtRaw is Map) {
      pbtRaw.forEach((key, value) {
        pbt[key.toString()] = int.tryParse(value.toString()) ?? 0;
      });
    }

    if (pbt.isEmpty) return const SizedBox.shrink();

    return Card(
      color: AppColors.bgSection,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle de permisos',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pbt.entries.map((e) {
                final label = _prettyPermissionType(e.key);
                return Chip(
                  label: Text('$label: ${e.value}'),
                  backgroundColor: AppColors.bg,
                  labelStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _prettyPermissionType(String raw) {
    raw = raw.toLowerCase();
    switch (raw) {
      case 'licencia':
        return 'Licencia médica';
      case 'administrativo':
        return 'Día administrativo';
      case 'vacaciones':
        return 'Vacaciones';
      case 'especial':
        return 'Permiso especial';
      default:
        return raw[0].toUpperCase() + raw.substring(1);
    }
  }

  Widget _miniMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(Map<String, dynamic> d) {
    final date = d['date']?.toString() ?? '';
    final dayName = d['day_name']?.toString() ?? '';
    final status = d['status_label']?.toString() ?? '';
    final worked = _toInt(d['worked_net']);
    final late = _toInt(d['late_minutes']);
    final early = _toInt(d['early_leave_minutes']);

    final hasPermission = d['has_permission'] == true ||
        d['has_permission'] == 1 ||
        d['has_permission'] == '1';
    String permLabel = '';
    if (hasPermission) {
      if (d['permission_label'] != null &&
          d['permission_label'].toString().trim().isNotEmpty) {
        permLabel = d['permission_label'].toString();
      } else if (d['permission_types'] is List) {
        permLabel =
            (d['permission_types'] as List).map((e) => e.toString()).join(', ');
      } else {
        permLabel = 'Permiso';
      }
    }

    return Card(
      color: AppColors.bgSection,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '$date — $dayName',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (worked > 0)
                  _dayBadge(
                    icon: Icons.work_history,
                    text: '$worked min trabajados',
                  ),
                if (late > 0)
                  _dayBadge(
                    icon: Icons.alarm,
                    text: '$late min atraso',
                  ),
                if (early > 0)
                  _dayBadge(
                    icon: Icons.logout,
                    text: '$early min salida ant.',
                  ),
              ],
            ),
            if (hasPermission && permLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              _dayBadge(
                icon: Icons.event_available,
                text: permLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dayBadge({required IconData icon, required String text}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
