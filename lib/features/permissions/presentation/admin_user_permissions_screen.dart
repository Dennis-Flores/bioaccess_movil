// lib/features/permissions/presentation/admin_user_permissions_screen.dart

import 'package:flutter/material.dart';
import 'package:bioaccess_movil/core/api_service.dart';
import 'package:bioaccess_movil/core/theme.dart';
import 'package:bioaccess_movil/features/auth/domain/app_user.dart';
import 'package:bioaccess_movil/features/permissions/domain/user_permission.dart';
import 'package:bioaccess_movil/features/permissions/presentation/permission_form_screen.dart';

class AdminUserPermissionsScreen extends StatefulWidget {
  final AppUser adminUser;
  final int userId;
  final String userName;

  const AdminUserPermissionsScreen({
    super.key,
    required this.adminUser,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUserPermissionsScreen> createState() =>
      _AdminUserPermissionsScreenState();
}

class _AdminUserPermissionsScreenState
    extends State<AdminUserPermissionsScreen> {
  late Future<List<UserPermission>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _fetchPermissions();
    });
  }

  Future<List<UserPermission>> _fetchPermissions() async {
    final res = await ApiService.getUserPermissions(userId: widget.userId);

    if (res['ok'] != true) {
      throw Exception(res['error']?.toString() ?? 'Error al cargar permisos');
    }

    final list = res['permissions'];
    if (list is! List) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => UserPermission.fromJson(e))
        .toList();
  }

  Future<void> _goToNewPermission() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PermissionFormScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
    if (created == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Permisos de ${widget.userName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToNewPermission,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<UserPermission>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            );
          }
          final perms = snap.data ?? [];
          if (perms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.event_busy, size: 48, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Text(
                      'Sin permisos registrados para este usuario.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: perms.length,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemBuilder: (context, index) {
                final p = perms[index];
                final rango =
                    '${_fmt(p.fechaInicio)} al ${_fmt(p.fechaFin)}';

                final statusColor =
                    p.aprobado ? AppColors.success : Colors.orange;
                final statusLabel =
                    p.aprobado ? 'Aprobado' : 'Pendiente';

                final iconData = _iconForType(p.tipo);

                return Card(
                  color: AppColors.bgSection,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.15),
                      child: Icon(iconData, color: statusColor),
                    ),
                    title: Text(
                      _labelForType(p.tipo),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          rango,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                statusLabel,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: statusColor.withOpacity(0.15),
                              labelStyle: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if ((p.observacion ?? '').trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              p.observacion!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PermissionFormScreen(
                            userId: widget.userId,
                            userName: widget.userName,
                            existing: p,
                          ),
                        ),
                      );
                      if (updated == true) {
                        _load();
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  String _labelForType(String tipo) {
    final t = (tipo.trim().toLowerCase());
    switch (t) {
      case 'licencia':
        return 'Licencia';
      case 'administrativo':
        return 'Permiso administrativo';
      case 'especial':
        return 'Permiso especial';
      case 'vacaciones':
        return 'Vacaciones';
      default:
        return tipo.isEmpty ? 'Permiso' : tipo;
    }
  }

  IconData _iconForType(String tipo) {
    final t = (tipo.trim().toLowerCase());
    switch (t) {
      case 'licencia':
        return Icons.medical_information;
      case 'administrativo':
        return Icons.work_history;
      case 'especial':
        return Icons.star;
      case 'vacaciones':
        return Icons.beach_access;
      default:
        return Icons.event_note;
    }
  }
}
