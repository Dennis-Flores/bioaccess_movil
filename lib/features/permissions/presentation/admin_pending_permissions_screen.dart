import 'package:flutter/material.dart';
import 'package:bioaccess_movil/core/api_service.dart';
import 'package:bioaccess_movil/features/auth/domain/app_user.dart';
import 'package:bioaccess_movil/features/permissions/domain/user_permission.dart';

class AdminPendingPermissionsScreen extends StatefulWidget {
  final AppUser currentUser;

  const AdminPendingPermissionsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<AdminPendingPermissionsScreen> createState() =>
      _AdminPendingPermissionsScreenState();
}

class _AdminPendingPermissionsScreenState
    extends State<AdminPendingPermissionsScreen> {
  late Future<List<UserPermission>> _future;
  final _obsControllers = <int, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UserPermission>> _load() {
    final companyId =
        int.tryParse(widget.currentUser.companyId?.toString() ?? '') ?? 0;
    if (companyId <= 0) {
      return Future.value([]);
    }
    return ApiService.getPendingPermissionsForCompany(companyId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _changeStatus(UserPermission p, String estado) async {
    final ctrl = _obsControllers[p.id];
    final obs = ctrl?.text.trim().isNotEmpty == true ? ctrl!.text.trim() : null;

    final adminId = int.tryParse(widget.currentUser.id.toString());

    final ok = await ApiService.setPermissionStatus(
      id: p.id,
      estado: estado,
      observacion: obs,
      adminId: adminId,
    );

    if (!mounted) return;

    if (ok) {
      final totalDias =
          p.fechaFin.difference(p.fechaInicio).inDays + 1; // incl. ambos días
      final ahora = DateTime.now();
      final diasEntreDecision =
          ahora.difference(p.createdAt).inDays; // "cuántos días después"

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(
              estado == 'aprobado'
                  ? 'Permiso aprobado'
                  : 'Permiso rechazado',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre: ${p.displayName}'),
                if ((p.rut ?? '').isNotEmpty) Text('RUT: ${p.rut}'),
                const SizedBox(height: 8),
                Text('Tipo: ${p.tipo}'),
                Text('Desde: ${_fmtDate(p.fechaInicio)}'),
                Text('Hasta: ${_fmtDate(p.fechaFin)}'),
                Text('Total días: $totalDias'),
                const SizedBox(height: 8),
                Text('Fecha solicitud: ${_fmtDate(p.createdAt)}'),
                Text('Fecha decisión: ${_fmtDate(ahora)}'),
                if (diasEntreDecision > 0)
                  Text('Decisión tomada $diasEntreDecision días después.'),
                const SizedBox(height: 8),
                if (obs != null && obs.isNotEmpty) ...[
                  const Text('Observación registrada:'),
                  Text(
                    obs,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permiso ${estado == 'aprobado' ? 'aprobado' : 'rechazado'}',
          ),
        ),
      );
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el permiso')),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _obsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getCtrl(UserPermission p) {
    return _obsControllers.putIfAbsent(
      p.id,
      () => TextEditingController(text: p.observacion ?? ''),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permisos pendientes'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<UserPermission>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                ],
              );
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 40),
                  Center(child: Text('No hay solicitudes pendientes.')),
                ],
              );
            }

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final p = data[index];
                final ctrl = _getCtrl(p);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.tipo.toUpperCase()} — ${p.rangoFechas}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.displayName +
                              ((p.rut ?? '').isNotEmpty ? ' (${p.rut})' : ''),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: ctrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Observación (opcional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('Rechazar'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => _changeStatus(
                                  p,
                                  'rechazado',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Aprobar'),
                                onPressed: () => _changeStatus(
                                  p,
                                  'aprobado',
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
