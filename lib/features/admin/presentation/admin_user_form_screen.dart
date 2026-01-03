// lib/features/admin/presentation/admin_user_form_screen.dart
import 'package:flutter/material.dart';

import '../../../core/api_service.dart';
import '../../../core/theme.dart';
import '../../auth/domain/app_user.dart';

class AdminUserFormScreen extends StatefulWidget {
  final AppUser adminUser;

  const AdminUserFormScreen({
    super.key,
    required this.adminUser,
  });

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _rutController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _activo = true;
  String _selectedRol = 'user';

  // NUEVO: flags de biometría y huella
  bool _biometriaEnabled = false;
  bool _huellaEnabled = false;

  bool _saving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _rutController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final companyId =
        int.tryParse(widget.adminUser.companyId?.toString() ?? '') ?? 0;
    if (companyId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa inválida para crear usuario.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final nombre = _nombreController.text.trim();
      final apellido = _apellidoController.text.trim();
      final rut = _rutController.text.trim();
      final correo = _correoController.text.trim().isEmpty
          ? null
          : _correoController.text.trim();
      final password = _passwordController.text.trim();

      final res = await ApiService.createUser(
        companyId: companyId,
        nombre: nombre,
        apellido: apellido,
        rut: rut,
        correo: correo,
        password: password,
        rol: _selectedRol,
        biometriaEnabled: _biometriaEnabled, // NUEVO
        huellaEnabled: _huellaEnabled,       // NUEVO
        activo: _activo,
      );

      if (!mounted) return;

      if (res['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado correctamente.')),
        );
        Navigator.of(context).pop(true); // devolvemos "ok" al listado
      } else {
        final msg = res['error']?.toString() ?? 'No se pudo crear el usuario.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
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
    final companyName = widget.adminUser.companyName ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Crear usuario'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: AppColors.bgSection,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (companyName.isNotEmpty) ...[
                          Text(
                            companyName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const Text(
                          'Datos básicos',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingrese el nombre.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _apellidoController,
                          decoration: const InputDecoration(
                            labelText: 'Apellido',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingrese el apellido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _rutController,
                          decoration: const InputDecoration(
                            labelText: 'RUT',
                            hintText: '11111111-1',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingrese el RUT.';
                            }
                            // Aquí podrías agregar validación de formato chileno si quieres.
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _correoController,
                          decoration: const InputDecoration(
                            labelText: 'Correo (opcional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Seguridad y rol',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña inicial',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingrese una contraseña.';
                            }
                            if (v.trim().length < 4) {
                              return 'Use al menos 4 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedRol,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('Funcionario'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Administrador empresa'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selectedRol = v;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: _activo,
                          onChanged: (v) => setState(() => _activo = v),
                          title: const Text('Usuario activo'),
                          subtitle: const Text(
                            'Si está inactivo, no podrá iniciar sesión.',
                          ),
                        ),

                        // ===== NUEVA SECCIÓN: BIOMETRÍA / HUELLA =====
                        const SizedBox(height: 8),
                        const Text(
                          'Métodos de marcaje',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Estos ajustes no cambian el modo de marcaje actual '
                          'por RUT/código, pero dejan listo al usuario para '
                          'usar biometría o huella cuando se habiliten.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: _biometriaEnabled,
                          onChanged: (v) =>
                              setState(() => _biometriaEnabled = v),
                          title: const Text('Habilitar biometría (rostro)'),
                          subtitle: const Text(
                            'Marcaje con reconocimiento facial.',
                          ),
                        ),
                        SwitchListTile(
                          value: _huellaEnabled,
                          onChanged: (v) =>
                              setState(() => _huellaEnabled = v),
                          title: const Text('Habilitar huella'),
                          subtitle: const Text(
                            'Marcaje con lector de huella.',
                          ),
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _saving ? 'Guardando...' : 'Crear usuario',
                            ),
                            onPressed: _saving ? null : _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
