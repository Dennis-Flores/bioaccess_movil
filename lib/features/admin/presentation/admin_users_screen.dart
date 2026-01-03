// lib/features/admin/presentation/admin_users_screen.dart

import 'package:flutter/material.dart';

import '../../../core/api_service.dart';
import '../../../core/theme.dart';
import '../../auth/domain/app_user.dart';
import 'admin_user_form_screen.dart';
import 'admin_user_schedule_screen.dart';
import 'admin_user_month_summary_screen.dart';
import 'admin_user_edit_screen.dart';

// NUEVO: import de la pantalla de permisos
import 'package:bioaccess_movil/features/permissions/presentation/admin_user_permissions_screen.dart';

class AdminUserItem {
  final int id;
  final String nombre;
  final String apellido;
  final String rut;
  final String correo;
  final String rol;
  final bool activo;

  AdminUserItem({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.rut,
    required this.correo,
    required this.rol,
    required this.activo,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    final rawActivo = json['activo'];
    final activo = rawActivo == 1 ||
        rawActivo == '1' ||
        rawActivo == true ||
        rawActivo?.toString() == 'true';

    return AdminUserItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      apellido: (json['apellido'] ?? '').toString(),
      rut: (json['rut'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      rol: (json['rol'] ?? '').toString(),
      activo: activo,
    );
  }

  String get nombreCompleto => '$nombre $apellido';
}

class AdminUsersScreen extends StatefulWidget {
  final AppUser adminUser;

  const AdminUsersScreen({super.key, required this.adminUser});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  String? _error;
  List<AdminUserItem> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // companyId viene como String en AppUser → lo parseamos
      final companyIdStr = widget.adminUser.companyId?.toString() ?? '';
      final companyId = int.tryParse(companyIdStr) ?? 0;

      if (companyId <= 0) {
        setState(() {
          _error = 'No se encontró ID de empresa para este admin.';
          _loading = false;
        });
        return;
      }

      final data = await ApiService.getCompanyUsers(companyId: companyId);

      if (data['ok'] == true && data['users'] is List) {
        final list = data['users'] as List;
        final users = list
            .whereType<Map<String, dynamic>>()
            .map((json) => AdminUserItem.fromJson(json))
            .toList();

        setState(() {
          _users = users;
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ??
              'No se pudo cargar la lista de usuarios.';
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

  Future<void> _deleteUser(AdminUserItem u) async {
    final companyId = int.tryParse(widget.adminUser.companyId ?? '') ?? 0;

    final res = await ApiService.deleteUser(
      userId: u.id,
      companyId: companyId,
    );

    if (!mounted) return;

    if (res['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado')),
      );
      _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['error']?.toString() ?? 'No se pudo eliminar el usuario.',
          ),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, AdminUserItem u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar usuario'),
          content: Text(
            '¿Seguro que deseas eliminar a:\n\n'
            '${u.nombreCompleto}\nRUT: ${u.rut}\n\n'
            'Se eliminarán también sus horarios y registros de asistencia.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await _deleteUser(u);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName = widget.adminUser.companyName ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Usuarios — $companyName'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AdminUserFormScreen(
                adminUser: widget.adminUser,
              ),
            ),
          );

          if (created == true) {
            _loadUsers();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadUsers,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _users.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay usuarios registrados para esta empresa.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final u = _users[index];

                            return Card(
                              color: AppColors.bgSection,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                title: Text(
                                  u.nombreCompleto,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.rut,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (u.correo.isNotEmpty)
                                      Text(
                                        u.correo,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    Text(
                                      'Rol: ${u.rol} · ${u.activo ? 'Activo' : 'Inactivo'}',
                                      style: TextStyle(
                                        color: u.activo
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                // Tap = Editar horario
                                onTap: () async {
                                  final updated =
                                      await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => AdminUserScheduleScreen(
                                        userItem: u,
                                        adminUser: widget.adminUser,
                                      ),
                                    ),
                                  );
                                  if (updated == true) {
                                    _loadUsers();
                                  }
                                },

                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'schedule') {
                                      final updated =
                                          await Navigator.of(context)
                                              .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AdminUserScheduleScreen(
                                            userItem: u,
                                            adminUser: widget.adminUser,
                                          ),
                                        ),
                                      );
                                      if (updated == true) {
                                        _loadUsers();
                                      }
                                    } else if (value == 'month') {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AdminUserMonthSummaryScreen(
                                            userItem: u,
                                            adminUser: widget.adminUser,
                                          ),
                                        ),
                                      );
                                    } else if (value == 'edit') {
                                      final updated =
                                          await Navigator.of(context)
                                              .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => AdminUserEditScreen(
                                            userItem: u,
                                            adminUser: widget.adminUser,
                                          ),
                                        ),
                                      );
                                      if (updated == true) {
                                        _loadUsers();
                                      }
                                    } else if (value == 'permisos') {
                                      final refreshed =
                                          await Navigator.of(context)
                                              .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AdminUserPermissionsScreen(
                                            adminUser: widget.adminUser,
                                            userId: u.id,
                                            userName: u.nombreCompleto,
                                          ),
                                        ),
                                      );
                                      if (refreshed == true) {
                                        _loadUsers();
                                      }
                                    } else if (value == 'delete') {
                                      _confirmDelete(context, u);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'schedule',
                                      child: Text('Editar horario'),
                                    ),
                                    PopupMenuItem(
                                      value: 'month',
                                      child: Text('Resumen mensual'),
                                    ),
                                    PopupMenuItem(
                                      value: 'permisos',
                                      child: Text('Permisos / licencias'),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Editar datos'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Eliminar usuario',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
