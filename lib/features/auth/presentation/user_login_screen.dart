// lib/features/auth/presentation/user_login_screen.dart

import 'package:flutter/material.dart';

import '../../../core/api_service.dart';
import '../../../core/config.dart';
import '../../../core/theme.dart';
import '../domain/app_user.dart';
import '../domain/user_role.dart';
import '../../user_panel/presentation/user_home_screen.dart';
import '../../superadmin/presentation/superadmin_home_screen.dart';
import '../../admin/presentation/admin_home_screen.dart';


class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rutController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyIdController = TextEditingController(text: '1');

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _rutController.dispose();
    _passwordController.dispose();
    _companyIdController.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rut = _rutController.text.trim();
      final password = _passwordController.text;
      final companyId = int.tryParse(_companyIdController.text) ?? 1;

      final data = await ApiService.login(
        rut: rut,
        password: password,
        companyId: companyId,
      );

      if (data['ok'] == true && data['user'] != null) {
        final userJson = data['user'] as Map<String, dynamic>;
        final appUser = AppUser.fromApiJson(userJson);

        if (!mounted) return;

                Widget destination;

        switch (appUser.rol) {
          case UserRole.superAdmin:
            destination = SuperAdminHomeScreen(user: appUser);
            break;
          case UserRole.admin:
            destination = AdminHomeScreen(user: appUser);
            break;
          case UserRole.user:
          default:
            destination = UserHomeScreen(user: appUser);
            break;
        }


        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => destination),
        );
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'Credenciales inválidas.';
        });
      }
    } catch (_) {
      setState(() {
        _error = 'No se pudo conectar con el servidor.';
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: AppColors.bgSection,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConfig.appName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Accede para ver tu asistencia y horarios',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // RUT
                      TextFormField(
                        controller: _rutController,
                        decoration: const InputDecoration(
                          labelText: 'RUT',
                          hintText: '11111111-1',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu RUT';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // PASSWORD
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // COMPANY ID
                      TextFormField(
                        controller: _companyIdController,
                        decoration: const InputDecoration(
                          labelText: 'ID Empresa',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),

                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _doLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Ingresar'),
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
    );
  }
}
