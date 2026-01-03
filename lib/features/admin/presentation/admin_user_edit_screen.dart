// lib/features/admin/presentation/admin_user_edit_screen.dart

import 'package:flutter/material.dart';

import '../../../core/api_service.dart';
import '../../../core/theme.dart';
import 'admin_users_screen.dart' show AdminUserItem;
import '../../auth/domain/app_user.dart';

class AdminUserEditScreen extends StatefulWidget {
  final AdminUserItem userItem;
  final AppUser adminUser;

  const AdminUserEditScreen({
    super.key,
    required this.userItem,
    required this.adminUser,
  });

  @override
  State<AdminUserEditScreen> createState() => _AdminUserEditScreenState();
}

class _AdminUserEditScreenState extends State<AdminUserEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  late TextEditingController _rutCtrl;
  late TextEditingController _correoCtrl;
  final TextEditingController _passwordCtrl = TextEditingController();

  String _rol = 'user';
  bool _activo = true;

  // NUEVO: flags de biometría y huella
  bool _biometriaEnabled = false;
  bool _huellaEnabled = false;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.userItem;

    _nombreCtrl = TextEditingController(text: u.nombre);
    _apellidoCtrl = TextEditingController(text: u.apellido);
    _rutCtrl = TextEditingController(text: u.rut);
    _correoCtrl = TextEditingController(text: u.correo);

    _rol = (u.rol.isEmpty ? 'user' : u.rol).toLowerCase();
    if (_rol != 'admin' && _rol != 'superadmin') {
      _rol = 'user';
    }

    _activo = u.activo;

    // 👀 De momento los dejamos en false porque AdminUserItem
    // aún no trae estos campos. Cuando extiendas AdminUserItem
    // puedes inicializarlos desde ahí, por ejemplo:
    //
    // _biometriaEnabled = u.biometriaEnabled;
    // _huellaEnabled     = u.huellaEnabled;
    _biometriaEnabled = false;
    _huellaEnabled = false;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _rutCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.updateUser(
        id: widget.userItem.id,
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        rut: _rutCtrl.text.trim(),
        correo: _correoCtrl.text.trim().isEmpty
            ? null
            : _correoCtrl.text.trim(),
        rol: _rol,
        activo: _activo,

        // NUEVO: enviamos biometría y huella al API
        biometriaEnabled: _biometriaEnabled,
        huellaEnabled: _huellaEnabled,

        password: _passwordCtrl.text.trim().isEmpty
            ? null
            : _passwordCtrl.text.trim(),
      );

      if (res['ok'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado.')),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = res['error']?.toString() ?? 'No se pudo actualizar.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName = widget.adminUser.companyName ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Editar usuario — $companyName'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: AppColors.bgSection,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _apellidoCtrl,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ingresa el apellido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _rutCtrl,
                      decoration: const InputDecoration(labelText: 'RUT'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ingresa el RUT' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _correoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo (opcional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _rol,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('Usuario'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Administrador'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _rol = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // ---- Switch usuario activo ----
                    SwitchListTile(
                      title: const Text('Usuario activo'),
                      value: _activo,
                      onChanged: (v) => setState(() => _activo = v),
                    ),
                    const SizedBox(height: 8),

                    // ---- NUEVOS: switches biometría / huella ----
                    SwitchListTile(
                      title: const Text('Biometría habilitada'),
                      subtitle: const Text(
                        'Marcar asistencia con reconocimiento facial (futuro módulo).',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _biometriaEnabled,
                      onChanged: (v) => setState(() => _biometriaEnabled = v),
                    ),
                    SwitchListTile(
                      title: const Text('Huella habilitada'),
                      subtitle: const Text(
                        'Marcar asistencia con lector de huella (futuro módulo).',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _huellaEnabled,
                      onChanged: (v) => setState(() => _huellaEnabled = v),
                    ),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nueva contraseña (opcional)',
                        helperText:
                            'Déjalo en blanco para mantener la contraseña actual.',
                      ),
                      obscureText: true,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: _loading
                            ? const Text('Guardando...')
                            : const Text('Guardar cambios'),
                        onPressed: _loading ? null : _save,
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
}
