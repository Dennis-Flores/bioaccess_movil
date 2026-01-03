import 'package:flutter/material.dart';
import 'package:bioaccess_movil/core/api_service.dart';
import 'package:bioaccess_movil/features/auth/domain/app_user.dart';
import 'package:bioaccess_movil/features/permissions/domain/user_permission.dart';

class AdminPermissionsHistoryScreen extends StatefulWidget {
  final AppUser currentUser;

  const AdminPermissionsHistoryScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<AdminPermissionsHistoryScreen> createState() =>
      _AdminPermissionsHistoryScreenState();
}

class _AdminPermissionsHistoryScreenState
    extends State<AdminPermissionsHistoryScreen> {
  late Future<List<UserPermission>> _future;
  String _estadoFilter = 'todos'; // todos / pendiente / aprobado / rechazado
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UserPermission>> _load() {
    final companyId =
        int.tryParse(widget.currentUser.companyId?.toString() ?? '') ?? 0;

    String? estadoParam;
    if (_estadoFilter != 'todos') {
      estadoParam = _estadoFilter;
    }

    return ApiService.getCompanyPermissionsHistory(
      companyId: companyId,
      estado: estadoParam,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
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

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de permisos'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // Filtros arriba
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o RUT',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _search = v.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _estadoFilter,
                    items: const [
                      DropdownMenuItem(
                        value: 'todos',
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem(
                        value: 'pendiente',
                        child: Text('Pendientes'),
                      ),
                      DropdownMenuItem(
                        value: 'aprobado',
                        child: Text('Aprobados'),
                      ),
                      DropdownMenuItem(
                        value: 'rechazado',
                        child: Text('Rechazados'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _estadoFilter = v;
                        _future = _load();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<UserPermission>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  var data = snapshot.data ?? [];

                  // filtro local por texto
                  if (_search.isNotEmpty) {
                    data = data.where((p) {
                      final n = (p.displayName).toLowerCase();
                      final r = (p.rut ?? '').toLowerCase();
                      return n.contains(_search) || r.contains(_search);
                    }).toList();
                  }

                  if (data.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron permisos.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final p = data[index];
                      final totalDias =
                          p.fechaFin.difference(p.fechaInicio).inDays + 1;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _estadoColor(p).withOpacity(0.15),
                            child: Icon(
                              Icons.event_note,
                              color: _estadoColor(p),
                            ),
                          ),
                          title: Text(
                            '${p.displayName}'
                            '${(p.rut ?? '').isNotEmpty ? ' (${p.rut})' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${p.tipo.toUpperCase()} — ${_fmtDate(p.fechaInicio)} → ${_fmtDate(p.fechaFin)}'
                                '  ($totalDias día${totalDias == 1 ? '' : 's'})',
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Estado: ${_estadoLabel(p)}',
                                style: TextStyle(
                                  color: _estadoColor(p),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Solicitado: ${_fmtDate(p.createdAt)}'
                                '${p.decidedAt != null ? ' · Decidido: ${_fmtDate(p.decidedAt!)}' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (p.observacion != null &&
                                  p.observacion!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Obs.: ${p.observacion}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
