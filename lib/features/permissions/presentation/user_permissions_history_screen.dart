import 'package:flutter/material.dart';
import 'package:bioaccess_movil/core/api_service.dart';
import 'package:bioaccess_movil/features/auth/domain/app_user.dart';
import 'package:bioaccess_movil/features/permissions/domain/user_permission.dart';

class UserPermissionsHistoryScreen extends StatefulWidget {
  final AppUser currentUser;

  const UserPermissionsHistoryScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<UserPermissionsHistoryScreen> createState() =>
      _UserPermissionsHistoryScreenState();
}

class _UserPermissionsHistoryScreenState
    extends State<UserPermissionsHistoryScreen> {
  late Future<List<UserPermission>> _future;

  @override
  void initState() {
    super.initState();
    final userId = int.tryParse(widget.currentUser.id.toString()) ?? 0;
    if (userId > 0) {
      _future = ApiService.getUserPermissionsSimple(userId);
    } else {
      _future = Future.value([]);
    }
  }

  Color _estadoColor(UserPermission p) {
    if (p.isPendiente) return Colors.orange;
    if (p.isAprobado) return Colors.green;
    return Colors.red;
  }

  String _estadoLabel(UserPermission p) {
    if (p.isPendiente) return 'Pendiente';
    if (p.isAprobado) return 'Aprobado';
    return 'Rechazado';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes de permiso'),
      ),
      body: FutureBuilder<List<UserPermission>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar permisos: ${snapshot.error}'),
            );
          }
          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(
              child: Text('No tienes solicitudes registradas.'),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final p = data[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _estadoColor(p).withOpacity(0.15),
                    child: Icon(
                      Icons.event_note,
                      color: _estadoColor(p),
                    ),
                  ),
                  title: Text(
                    '${p.tipo.toUpperCase()} — ${p.rangoFechas}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Estado: ${_estadoLabel(p)}',
                        style: TextStyle(
                          color: _estadoColor(p),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (p.observacion != null &&
                          p.observacion!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Obs.: ${p.observacion}'),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
