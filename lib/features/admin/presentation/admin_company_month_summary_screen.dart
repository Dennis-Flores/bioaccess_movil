// lib/features/admin/presentation/admin_company_month_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_service.dart';
import '../../../core/theme.dart';
import '../../auth/domain/app_user.dart';

class AdminCompanyMonthSummaryScreen extends StatefulWidget {
  final AppUser adminUser;

  const AdminCompanyMonthSummaryScreen({
    super.key,
    required this.adminUser,
  });

  @override
  State<AdminCompanyMonthSummaryScreen> createState() =>
      _AdminCompanyMonthSummaryScreenState();
}

class _AdminCompanyMonthSummaryScreenState
    extends State<AdminCompanyMonthSummaryScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _summary;

  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final companyId = int.tryParse(widget.adminUser.companyId ?? '') ?? 0;

      final data = await ApiService.getCompanyMonthSummary(
        companyId: companyId,
        year: _currentMonth.year,
        month: _currentMonth.month,
      );

      if (data['ok'] == true) {
        setState(() {
          _summary = data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ??
              'No se pudo obtener el resumen mensual de la empresa.';
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
    final newMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + delta,
    );
    setState(() {
      _currentMonth = newMonth;
    });
    _loadSummary();
  }

  /// ========================
  /// EXPORTACIÓN
  /// ========================
  Future<void> _openCompanyExport(String format) async {
    final companyId = int.tryParse(widget.adminUser.companyId ?? '') ?? 0;

    final url = ApiService.buildCompanyMonthExportUrl(
      companyId: companyId,
      year: _currentMonth.year,
      month: _currentMonth.month,
      format: format,
    );

    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace de exportación'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName = widget.adminUser.companyName ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Resumen Empresa — $companyName'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            /// Selector de mes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _loading ? null : () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "${_monthName(_currentMonth.month)} ${_currentMonth.year}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            /// Botones de exportación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _loading ? null : () => _openCompanyExport('pdf'),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF empresa'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _loading ? null : () => _openCompanyExport('xlsx'),
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Excel empresa'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: AppColors.error),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadSummary,
                                child: const Text('Reintentar'),
                              )
                            ],
                          ),
                        )
                      : _buildSummary(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final sum = _summary!;
    final totals = sum['totals'] as Map<String, dynamic>? ?? {};
    final users = sum['users'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTotalsCard(totals),
        const SizedBox(height: 16),
        const Text(
          'Usuarios',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...users.map((u) => _buildUserRow(
              (u as Map).cast<String, dynamic>(),
            )),
      ],
    );
  }

  Widget _buildTotalsCard(Map<String, dynamic> t) {
    int _asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    return Card(
      color: AppColors.bgSection,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Totales globales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _totalRow('Días presentes', _asInt(t['days_present'])),
            _totalRow('Días ausentes', _asInt(t['days_absent'])),
            _totalRow('Sin horario', _asInt(t['days_no_schedule'])),
            _totalRow('Min. trabajados', _asInt(t['worked_minutes_net'])),
            _totalRow('Atrasos (min)', _asInt(t['late_minutes'])),
            _totalRow(
                'Salidas anticipadas (min)', _asInt(t['early_leave_minutes'])),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> u) {
    // Nombre con fallbacks
    final nombreCompleto =
        (u['nombre_completo'] ?? '').toString().trim();
    final nombre = (u['nombre'] ?? '').toString().trim();
    final apellido = (u['apellido'] ?? '').toString().trim();

    final displayName = nombreCompleto.isNotEmpty
        ? nombreCompleto
        : ('$nombre $apellido').trim().isEmpty
            ? 'Sin nombre'
            : ('$nombre $apellido').trim();

    int _asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    // Fallbacks por si el backend usa otros nombres
    final present = _asInt(
        u['days_present'] ?? u['present'] ?? u['present_days'] ?? 0);
    final absent = _asInt(
        u['days_absent'] ?? u['absent'] ?? u['absent_days'] ?? 0);
    final worked = _asInt(
        u['worked_minutes_net'] ?? u['minutes'] ?? u['worked_minutes'] ?? 0);

    return Card(
      color: AppColors.bgSection,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(
          displayName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Presente: $present · Ausente: $absent · Min: $worked',
          style: const TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _totalRow(String label, int val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            '$val',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const nombres = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return nombres[m - 1];
  }
}
