import 'package:flutter/material.dart';

import '../../../core/api_service.dart';
import '../../../core/theme.dart';
import '../../../features/auth/domain/app_user.dart';

class DaySummaryScreen extends StatefulWidget {
  final AppUser user;

  const DaySummaryScreen({super.key, required this.user});

  @override
  State<DaySummaryScreen> createState() => _DaySummaryScreenState();
}

class _DaySummaryScreenState extends State<DaySummaryScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? data;

  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadSummary();
  }

  String get _dateParam =>
      "${selectedDate.year.toString().padLeft(4, '0')}-"
      "${selectedDate.month.toString().padLeft(2, '0')}-"
      "${selectedDate.day.toString().padLeft(2, '0')}";

  Future<void> _loadSummary() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final userId = int.tryParse(widget.user.id) ?? 0;
      if (userId <= 0) {
        setState(() {
          loading = false;
          error = 'ID de usuario inválido.';
        });
        return;
      }

      final resp = await ApiService.getUserDaySummary(
        userId: userId,
        date: _dateParam,
      );

      if (resp['ok'] == true) {
        setState(() {
          data = resp;
          loading = false;
        });
      } else {
        setState(() {
          error = resp['error']?.toString() ?? 'Error cargando resumen diario.';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'No se pudo conectar con el servidor.';
        loading = false;
      });
    }
  }

  void _changeDay(int delta) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: delta));
    });
    _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final info = data ?? {};

    // Estructura flexible por si en el futuro cambian nombres
    final summary = (info['summary'] as Map?) ?? info;
    final schedule = (info['schedule'] as Map?) ?? summary['schedule'];

    final entrada =
        summary['entrada_real'] ?? summary['entry_time'] ?? summary['entrada'];
    final salida =
        summary['salida_real'] ?? summary['exit_time'] ?? summary['salida'];
    final workedMin = summary['worked_minutes_net'] ??
        summary['worked_net'] ??
        summary['minutes_worked'] ??
        0;
    final lateMin = summary['late_minutes'] ??
        summary['minutes_late'] ??
        summary['atraso_minutos'] ??
        0;
    final earlyMin = summary['early_leave_minutes'] ??
        summary['minutes_early'] ??
        summary['salida_anticipada_minutos'] ??
        0;
    final statusLabel =
        summary['status_label'] ?? summary['status'] ?? 'Sin información';

    final horarioInicio = schedule?['start_time'];
    final horarioFin = schedule?['end_time'];

    // 🔧 AQUÍ EL ARREGLO: parsear break_minutes a int
    final rawBreak = schedule?['break_minutes'];
    int breakMinutes = 0;
    if (rawBreak is int) {
      breakMinutes = rawBreak;
    } else if (rawBreak is String) {
      breakMinutes = int.tryParse(rawBreak) ?? 0;
    }

    final fechaTexto =
        "${selectedDate.day.toString().padLeft(2, '0')}-"
        "${selectedDate.month.toString().padLeft(2, '0')}-"
        "${selectedDate.year}";

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgHeader,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Jornada del día',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selector de día
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: loading ? null : () => _changeDay(-1),
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.textPrimary,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      fechaTexto,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _dateParam,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: loading ? null : () => _changeDay(1),
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),

            if (!loading && error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),

            if (!loading && error == null) ...[
              // Estado general del día
              Card(
                color: AppColors.bgSection,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusLabel.toString(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Horario esperado
              if (horarioInicio != null && horarioFin != null)
                Card(
                  color: AppColors.bgSection,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.schedule,
                        color: AppColors.primary),
                    title: const Text(
                      'Horario programado',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '$horarioInicio - $horarioFin'
                      '${breakMinutes > 0 ? ' · $breakMinutes min colación' : ''}',
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),

              // Marcas reales
              Card(
                color: AppColors.bgSection,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.access_time, color: AppColors.primary),
                  title: const Text(
                    'Marcas del día',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Entrada: ${entrada ?? '-'}\n'
                    'Salida:  ${salida ?? '-'}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),

              // Totales de minutos
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniStat(
                    label: 'Trabajados (neto)',
                    value: '$workedMin min',
                  ),
                  _MiniStat(
                    label: 'Atraso',
                    value: '$lateMin min',
                  ),
                  _MiniStat(
                    label: 'Salida anticipada',
                    value: '$earlyMin min',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        color: AppColors.bgSection,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
