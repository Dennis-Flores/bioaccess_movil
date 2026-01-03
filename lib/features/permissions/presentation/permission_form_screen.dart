// lib/features/permissions/presentation/permission_form_screen.dart

import 'package:flutter/material.dart';
import 'package:bioaccess_movil/core/api_service.dart';
import 'package:bioaccess_movil/core/theme.dart';
import 'package:bioaccess_movil/features/permissions/domain/user_permission.dart';

class PermissionFormScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final UserPermission? existing;

  const PermissionFormScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.existing,
  });

  @override
  State<PermissionFormScreen> createState() => _PermissionFormScreenState();
}

class _PermissionFormScreenState extends State<PermissionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  String _tipo = 'licencia';
  String _observacion = '';
  bool _aprobado = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fechaInicio = widget.existing?.fechaInicio ?? now;
    _fechaFin = widget.existing?.fechaFin ?? now;
    _tipo = widget.existing?.tipo ?? 'licencia';
    _observacion = widget.existing?.observacion ?? '';
    _aprobado = widget.existing?.aprobado ?? true;
  }

  Future<void> _pickDateInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaInicio = picked;
        if (_fechaFin.isBefore(_fechaInicio)) {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _pickDateFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaFin = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _saving = true);

    try {
      if (widget.existing == null) {
        await ApiService.createUserPermission(
          userId: widget.userId,
          tipo: _tipo,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
          observacion: _observacion,
          aprobado: _aprobado,
        );
      } else {
        await ApiService.updateUserPermission(
          id: widget.existing!.id,
          tipo: _tipo,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
          observacion: _observacion,
          aprobado: _aprobado,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar permiso: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'Editar permiso de ${widget.userName}'
              : 'Nuevo permiso para ${widget.userName}',
        ),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: AppColors.bgSection,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de permiso',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'licencia',
                          child: Text('Licencia'),
                        ),
                        DropdownMenuItem(
                          value: 'administrativo',
                          child: Text('Permiso administrativo'),
                        ),
                        DropdownMenuItem(
                          value: 'especial',
                          child: Text('Permiso especial'),
                        ),
                        DropdownMenuItem(
                          value: 'vacaciones',
                          child: Text('Vacaciones'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _tipo = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDateInicio,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label:
                                Text('Inicio: ${_fmt(_fechaInicio)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDateFin,
                            icon: const Icon(Icons.calendar_month, size: 18),
                            label: Text('Fin: ${_fmt(_fechaFin)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _observacion,
                      decoration: const InputDecoration(
                        labelText: 'Observación (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onSaved: (val) => _observacion = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Marcar como aprobado'),
                      subtitle: const Text(
                        'Si lo desactivas, quedará como permiso pendiente.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _aprobado,
                      onChanged: (val) => setState(() => _aprobado = val),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          isEdit ? 'Guardar cambios' : 'Crear permiso',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}
