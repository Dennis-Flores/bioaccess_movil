import 'package:flutter/material.dart';

import '../../../core/api_service.dart';
import '../../../core/theme.dart';
import '../../auth/domain/app_user.dart';
import '../../permissions/presentation/user_permission_request_screen.dart';
import '../../permissions/presentation/user_permissions_history_screen.dart';
import 'day_summary_screen.dart';
import 'month_summary_screen.dart';

class UserHomeScreen extends StatefulWidget {
  final AppUser user;

  const UserHomeScreen({super.key, required this.user});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool _loadingSummary = true;
  String? _errorSummary;

  int _daysPresent = 0;
  int _daysAbsent = 0;
  int _daysNoSchedule = 0;
  int _workedMinutesNet = 0;
  int _lateMinutes = 0;
  int _earlyLeaveMinutes = 0;

  int _permissionDaysTotal = 0;
  Map<String, int> _permissionsByType = {};

  int get _attendancePercent {
    final denom = _daysPresent + _daysAbsent;
    if (denom <= 0) return 0;
    final perc = (_daysPresent * 100 / denom).round();
    return perc.clamp(0, 100);
  }

  @override
  void initState() {
    super.initState();
    _loadMonthSummary();
  }

  Future<void> _loadMonthSummary() async {
    setState(() {
      _loadingSummary = true;
      _errorSummary = null;
    });

    try {
      // id viene como String → parseamos a int
      final userId = int.tryParse(widget.user.id.toString()) ?? 0;

      if (userId <= 0) {
        setState(() {
          _errorSummary = 'ID de usuario inválido para el resumen.';
          _loadingSummary = false;
        });
        return;
      }

      final now = DateTime.now();
      final res = await ApiService.getUserMonthSummary(
        userId: userId,
        year: now.year,
        month: now.month,
      );

      if (res['ok'] == true && res['totals'] is Map) {
        final t = res['totals'] as Map<String, dynamic>;

        _daysPresent = (t['days_present'] ?? 0) as int;
        _daysAbsent = (t['days_absent'] ?? 0) as int;
        _daysNoSchedule = (t['days_no_schedule'] ?? 0) as int;
        _workedMinutesNet = (t['worked_minutes_net'] ?? 0) as int;
        _lateMinutes = (t['late_minutes'] ?? 0) as int;
        _earlyLeaveMinutes = (t['early_leave_minutes'] ?? 0) as int;

        _permissionDaysTotal = (t['permission_days_total'] ?? 0) as int;

        final pbtRaw = t['permissions_by_type'];
        if (pbtRaw is Map) {
          _permissionsByType = pbtRaw.map(
            (k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0),
          );
        } else {
          _permissionsByType = {};
        }

        setState(() {
          _loadingSummary = false;
        });
      } else {
        setState(() {
          _errorSummary =
              res['error']?.toString() ?? 'No se pudo obtener el resumen mensual.';
          _loadingSummary = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorSummary = 'Error de conexión: $e';
        _loadingSummary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = '${widget.user.nombre} ${widget.user.apellido}'.trim();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('BioAccess — Panel usuario'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMonthSummary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Hola, $userName',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.companyName ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // ===== DASHBOARD CARDS =====
              _buildDashboardSection(),

              const SizedBox(height: 24),

              const Text(
                'Acciones rápidas',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Jornada de hoy
              _buildActionTile(
                icon: Icons.today,
                title: 'Ver jornada de hoy',
                subtitle: 'Entrada, salida, minutos trabajados',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DaySummaryScreen(user: widget.user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Resumen mensual
              _buildActionTile(
                icon: Icons.calendar_month,
                title: 'Resumen mensual',
                subtitle: 'Detalle día a día y exportación',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MonthSummaryScreen(user: widget.user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // NUEVO: Solicitar permiso
              _buildActionTile(
                icon: Icons.event_note,
                title: 'Solicitar permiso',
                subtitle: 'Crear una nueva solicitud (estado pendiente)',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserPermissionRequestScreen(
                        currentUser: widget.user,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // NUEVO: Mis solicitudes
              _buildActionTile(
                icon: Icons.history,
                title: 'Mis solicitudes de permiso',
                subtitle: 'Ver estado de tus permisos (pendiente, aprobado, rechazado)',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserPermissionsHistoryScreen(
                        currentUser: widget.user,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // 👀 GUIÑO FUTURO:
              // Si más adelante necesitas otra acción rápida (por ejemplo,
              // "Historial de marcajes" o "Descargar certificados"),
              // solo copia/pega otro _buildActionTile aquí y listo.
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSection() {
    if (_loadingSummary) {
      return Card(
        color: AppColors.bgSection,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorSummary != null) {
      return Card(
        color: AppColors.bgSection,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(height: 8),
              Text(
                _errorSummary!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadMonthSummary,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen mes actual',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: AppColors.bgSection,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Porcentaje grande
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Asistencia este mes',
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

                // Fila de mini métricas
                Row(
                  children: [
                    _miniMetric(
                      label: 'Días presente',
                      value: _daysPresent.toString(),
                      icon: Icons.check_circle,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _miniMetric(
                      label: 'Días ausente',
                      value: _daysAbsent.toString(),
                      icon: Icons.cancel,
                      color: AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniMetric(
                      label: 'Días sin horario',
                      value: _daysNoSchedule.toString(),
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _miniMetric(
                      label: 'Días con permiso',
                      value: _permissionDaysTotal.toString(),
                      icon: Icons.event_available,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
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

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.bgSection,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.bg,
          child: Icon(icon, color: AppColors.textPrimary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
