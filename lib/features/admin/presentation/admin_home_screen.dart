import 'package:flutter/material.dart';

import '../../../core/api_service.dart';
import '../../../core/theme.dart';
import '../../auth/domain/app_user.dart';
import '../../permissions/presentation/admin_pending_permissions_screen.dart';
import '../../permissions/presentation/admin_permissions_history_screen.dart';
import 'admin_users_screen.dart';
import 'admin_company_month_summary_screen.dart';
import 'clock_terminal_screen.dart';


class AdminHomeScreen extends StatefulWidget {
  final AppUser user;

  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
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

  int _usersCount = 0;
  int _pendingPermissionsCount = 0; // <-- NUEVO: contador de permisos pendientes

  @override
  void initState() {
    super.initState();
    _loadCompanySummary();
  }

  int get _attendancePercent {
    final denom = _daysPresent + _daysAbsent;
    if (denom <= 0) return 0;
    final perc = (_daysPresent * 100 / denom).round();
    return perc.clamp(0, 100);
  }

    Future<void> _loadCompanySummary() async {
    setState(() {
      _loadingSummary = true;
      _errorSummary = null;
    });

    try {
      final companyIdStr = widget.user.companyId?.toString() ?? '';
      final companyId = int.tryParse(companyIdStr) ?? 0;

      if (companyId <= 0) {
        setState(() {
          _errorSummary = 'No se encontró empresa asociada al admin.';
          _loadingSummary = false;
        });
        return;
      }

      final now = DateTime.now();
      final res = await ApiService.getCompanyMonthSummary(
        companyId: companyId,
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

        final users = res['users'];
        if (users is List) {
          _usersCount = users.length;
        } else {
          _usersCount = 0;
        }

        // ===== Permisos pendientes: si falla, no rompemos el resumen =====
        try {
          final pendingList =
              await ApiService.getPendingPermissionsForCompany(companyId);
          _pendingPermissionsCount = pendingList.length;
        } catch (_) {
          _pendingPermissionsCount = 0;
        }

        setState(() {
          _loadingSummary = false;
        });
      } else {
        setState(() {
          _errorSummary = res['error']?.toString() ??
              'No se pudo obtener el resumen mensual de la empresa.';
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
    final adminName = '${widget.user.nombre} ${widget.user.apellido}'.trim();
    final companyName = widget.user.companyName ?? '';
    final companyLocation = widget.user.companyLocation ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('BioAccess — Panel admin'),
        actions: [
          IconButton(
            onPressed: _loadingSummary ? null : _loadCompanySummary,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCompanySummary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Hola, $adminName',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                companyName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (companyLocation.isNotEmpty)
                Text(
                  companyLocation,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              const SizedBox(height: 16),

              _buildDashboardSection(),

              const SizedBox(height: 24),
              const Text(
                'Gestión de empresa',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
                            _buildActionTile(
                icon: Icons.history,
                title: 'Historial de permisos',
                subtitle: 'Aprobados, rechazados y pendientes',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminPermissionsHistoryScreen(
                        currentUser: widget.user,
                      ),
                    ),
                  );
                },
              ),

              _buildActionTile(
                icon: Icons.access_time_filled,
                title: 'Modo reloj de marcaje',
                subtitle: 'Pantalla fija para ingreso y salida',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClockTerminalScreen(
                        adminUser: widget.user,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              _buildActionTile(
                icon: Icons.group,
                title: 'Usuarios de la empresa',
                subtitle: 'Crear, editar, horarios y permisos',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminUsersScreen(
                        adminUser: widget.user,
                      ),
                    ),
                  );
                  _loadCompanySummary();
                },
              ),
              const SizedBox(height: 8),

              _buildActionTile(
                icon: Icons.assignment,
                title: 'Resumen mensual empresa',
                subtitle: 'Totales globales y exportación PDF/Excel',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminCompanyMonthSummaryScreen(
                        adminUser: widget.user,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // NUEVO: Permisos pendientes
              _buildActionTile(
                icon: Icons.pending_actions,
                title: 'Permisos pendientes',
                subtitle:
                    'Revisar, aprobar o rechazar solicitudes (${_pendingPermissionsCount.toString()} pendientes)',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminPendingPermissionsScreen(
                        currentUser: widget.user,
                      ),
                    ),
                  );
                  // Al volver, recargamos el resumen y el contador
                  _loadCompanySummary();
                },
              ),

              const SizedBox(height: 8),
              // 👀 GUIÑO FUTURO:
              // Si más adelante necesitas otra sección (por ejemplo,
              // "Reportes avanzados" o "Configuración de notificaciones"),
              // copia/pega otro _buildActionTile aquí y queda todo ordenado.
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
                onPressed: _loadCompanySummary,
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
          'Resumen empresa — mes actual',
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
                // Fila principal
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Asistencia global',
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
                          const SizedBox(height: 4),
                          Text(
                            '$_usersCount usuarios activos registrados.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
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
                      label: 'Permisos pendientes',
                      value: _pendingPermissionsCount.toString(),
                      icon: Icons.pending_actions,
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Días con permiso aprobado: $_permissionDaysTotal',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
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
          backgroundColor: AppColors.bg, // antes AppColors.accent
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
