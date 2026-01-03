// lib/features/superadmin/presentation/superadmin_companies_screen.dart

import 'package:flutter/material.dart';

import '../../../core/api_service.dart';
import '../../../core/theme.dart';

class AdminCompany {
  final int id;
  final String name;
  final String location;
  bool isFrozen;

  AdminCompany({
    required this.id,
    required this.name,
    required this.location,
    required this.isFrozen,
  });

  factory AdminCompany.fromJson(Map<String, dynamic> json) {
    final rawFrozen = json['is_frozen'];

    final frozen = rawFrozen == 1 ||
        rawFrozen == '1' ||
        rawFrozen == true ||
        rawFrozen?.toString() == 'true';

    return AdminCompany(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      isFrozen: frozen,
    );
  }
}

class SuperAdminCompaniesScreen extends StatefulWidget {
  const SuperAdminCompaniesScreen({super.key});

  @override
  State<SuperAdminCompaniesScreen> createState() =>
      _SuperAdminCompaniesScreenState();
}

class _SuperAdminCompaniesScreenState
    extends State<SuperAdminCompaniesScreen> {
  bool _loading = true;
  String? _error;
  List<AdminCompany> _companies = [];
  int? _updatingId;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getCompaniesList();

      if (data['ok'] == true && data['companies'] is List) {
        final list = data['companies'] as List;
        final companies = list
            .whereType<Map<String, dynamic>>()
            .map((json) => AdminCompany.fromJson(json))
            .toList();

        setState(() {
          _companies = companies;
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ??
              'No se pudo cargar el listado de empresas.';
          _loading = false;
        });
      }
    } catch (e, st) {
      // Log en consola para ver exactamente qué está pasando
      debugPrint('Error cargando empresas: $e');
      debugPrint('$st');

      setState(() {
        _error = 'Error de conexión: $e';
        _loading = false;
      });
    }
  }

  Future<void> _toggleFrozen(AdminCompany company, bool newValue) async {
    setState(() {
      _updatingId = company.id;
    });

    final previous = company.isFrozen;
    setState(() {
      company.isFrozen = newValue;
    });

    try {
      final data = await ApiService.setCompanyFrozen(
        companyId: company.id,
        isFrozen: newValue,
      );

      if (data['ok'] != true) {
        // Revertimos si hubo error
        setState(() {
          company.isFrozen = previous;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['error']?.toString() ??
                    'No se pudo actualizar el estado de la empresa.',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          final msg = data['message']?.toString() ??
              (newValue
                  ? 'Empresa congelada correctamente.'
                  : 'Empresa reactivada correctamente.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      }
    } catch (_) {
      // Error de red: revertimos
      setState(() {
        company.isFrozen = previous;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión al actualizar la empresa.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Empresas'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadCompanies,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
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
                            onPressed: _loadCompanies,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _companies.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay empresas registradas.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _companies.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final c = _companies[index];
                            final updating = _updatingId == c.id;

                            return Card(
                              color: AppColors.bgSection,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                title: Text(
                                  c.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  c.location.isEmpty
                                      ? 'Sin ubicación'
                                      : c.location,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      c.isFrozen ? 'Suspendida' : 'Activa',
                                      style: TextStyle(
                                        color: c.isFrozen
                                            ? AppColors.error
                                            : AppColors.success,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: c.isFrozen,
                                      onChanged: updating
                                          ? null
                                          : (value) =>
                                              _toggleFrozen(c, value),
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
