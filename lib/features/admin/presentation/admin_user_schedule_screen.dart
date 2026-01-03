// lib/features/admin/presentation/admin_user_schedule_screen.dart

import 'package:flutter/material.dart';

import '../../../core/api_service.dart';
import '../../../core/theme.dart';
import 'admin_users_screen.dart' show AdminUserItem;
import '../../auth/domain/app_user.dart';

class AdminUserScheduleScreen extends StatefulWidget {
  final AdminUserItem userItem; // viene desde la lista
  final AppUser adminUser;

  const AdminUserScheduleScreen({
    super.key,
    required this.userItem,
    required this.adminUser,
  });

  @override
  State<AdminUserScheduleScreen> createState() =>
      _AdminUserScheduleScreenState();
}

class _AdminUserScheduleScreenState extends State<AdminUserScheduleScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  /// Lista de días con sus campos:
  /// day_of_week, day_name, start_time, end_time, break_minutes, enabled
  List<Map<String, dynamic>> _schedule = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getUserSchedule(widget.userItem.id);

      debugPrint('user_schedule_get response: $data');

      if (data['ok'] != true) {
        setState(() {
          _error = data['error']?.toString() ?? 'Error cargando horario.';
          _loading = false;
        });
        return;
      }

      dynamic rawList;
      if (data['schedule'] is List) {
        rawList = data['schedule'];
      } else if (data['schedules'] is List) {
        rawList = data['schedules'];
      } else if (data['items'] is List) {
        rawList = data['items'];
      } else if (data['days'] is List) {
        rawList = data['days'];
      }

      if (rawList is! List) {
        setState(() {
          _error = 'Formato inesperado al recibir el horario.';
          _loading = false;
        });
        return;
      }

      final list = rawList as List;

      setState(() {
        _schedule = list
            .map((e) => Map<String, dynamic>.from(
                  e as Map<String, dynamic>,
                ))
            .toList();
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Error cargando horario: $e\n$st');
      setState(() {
        _error = 'Error de conexión: $e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final body = {
        "user_id": widget.userItem.id,
        "items": _schedule,
      };

      final data = await ApiService.saveUserSchedule(body);

      debugPrint('user_schedule_save response: $data');

      if (data['ok'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario actualizado.')),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error =
              data['error']?.toString() ?? 'No se pudo guardar el horario.';
        });
      }
    } catch (e, st) {
      debugPrint('Error guardando horario: $e\n$st');
      setState(() {
        _error = 'Error guardando: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userItem;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Horario — ${user.nombreCompleto}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _schedule.length,
                  itemBuilder: (context, index) {
                    final item = _schedule[index];

                    return _buildDayCard(item);
                  },
                ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> item) {
    final enabled = item["enabled"] == true ||
        item["enabled"] == 1 ||
        item["enabled"] == "1";

    final breakRaw = item["break_minutes"];
    final breakMinutes = breakRaw is int
        ? breakRaw
        : int.tryParse(breakRaw?.toString() ?? '') ?? 0;

    return Card(
      color: AppColors.bgSection,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item["day_name"]?.toString() ?? 'Día',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SwitchListTile(
              title: const Text("Habilitado"),
              value: enabled,
              onChanged: (v) {
                setState(() {
                  item["enabled"] = v ? 1 : 0;
                });
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _timeButton(
                    label: "Inicio",
                    value: item["start_time"]?.toString(),
                    onChanged: (str) => setState(() {
                      item["start_time"] = str;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _timeButton(
                    label: "Fin",
                    value: item["end_time"]?.toString(),
                    onChanged: (str) => setState(() {
                      item["end_time"] = str;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: breakMinutes,
              decoration: const InputDecoration(
                labelText: 'Minutos colación',
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Sin colación')),
                DropdownMenuItem(value: 30, child: Text('30 minutos')),
                DropdownMenuItem(value: 45, child: Text('45 minutos')),
                DropdownMenuItem(value: 60, child: Text('60 minutos')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  item["break_minutes"] = v;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Botón que abre showTimePicker y guarda en formato HH:MM o HH:MM:SS
  Widget _timeButton({
    required String label,
    required String? value,
    required void Function(String) onChanged,
  }) {
    final display = (value == null || value.isEmpty)
        ? '--:--'
        : value.substring(0, 5); // HH:MM

    return OutlinedButton(
      onPressed: () async {
        final initial = _parseTimeOfDay(value) ?? const TimeOfDay(hour: 8, minute: 0);
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null) {
          final str = _formatTimeForDb(picked);
          onChanged(str);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(display),
        ],
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String? v) {
    if (v == null || v.isEmpty) return null;
    final parts = v.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Devuelve HH:MM:SS (para que el backend quede contento)
  String _formatTimeForDb(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }
}
