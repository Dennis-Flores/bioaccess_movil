import 'package:flutter/material.dart';
import 'package:bioaccess_movil/core/api_service.dart';

// IMPORT CORRECTO de AppUser (igual que en UserHomeScreen)
import '../../auth/domain/app_user.dart';

class UserPermissionRequestScreen extends StatefulWidget {
  final AppUser currentUser;

  const UserPermissionRequestScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<UserPermissionRequestScreen> createState() =>
      _UserPermissionRequestScreenState();
}

class _UserPermissionRequestScreenState
    extends State<UserPermissionRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  String _tipo = 'licencia';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _observacion = '';

  bool _sending = false;

  final _tipos = const <String>[
    'licencia',
    'administrativo',
    'vacaciones',
    'especial',
  ];

  Future<void> _pickFechaInicio() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDate: _fechaInicio ?? now,
      helpText: 'Selecciona fecha de inicio',
    );
    if (res != null) {
      setState(() => _fechaInicio = res);
      if (_fechaFin != null && _fechaFin!.isBefore(res)) {
        _fechaFin = res;
      }
    }
  }

  Future<void> _pickFechaFin() async {
    final base = _fechaInicio ?? DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: base,
      lastDate: DateTime(base.year + 2),
      initialDate: _fechaFin ?? base,
      helpText: 'Selecciona fecha de término',
    );
    if (res != null) {
      setState(() => _fechaFin = res);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fechas de inicio y término')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() => _sending = true);
    try {
      final userId = int.tryParse(widget.currentUser.id.toString()) ?? 0;
      if (userId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID de usuario inválido.')),
        );
        return;
      }

      final ok = await ApiService.createPermissionRequest(
        userId: userId,
        tipo: _tipo,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        observacion: _observacion,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Solicitud enviada correctamente (estado: pendiente)'),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar la solicitud')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Seleccionar';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar permiso'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AbsorbPointer(
          absorbing: _sending,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de permiso',
                    border: OutlineInputBorder(),
                  ),
                  value: _tipo,
                  items: _tipos
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t[0].toUpperCase() + t.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _tipo = v ?? 'licencia'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickFechaInicio,
                        child: Text(
                          'Inicio: ${_fmtDate(_fechaInicio)}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickFechaFin,
                        child: Text(
                          'Término: ${_fmtDate(_fechaFin)}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observación (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => _observacion = v?.trim() ?? '',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_sending ? 'Enviando...' : 'Enviar solicitud'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
