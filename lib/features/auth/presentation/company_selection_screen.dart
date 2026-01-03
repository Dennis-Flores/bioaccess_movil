// lib/features/auth/presentation/company_selection_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../terminal/presentation/main_menu_screen.dart';

class Company {
  final String id;
  final String name;
  final String city;
  bool isFrozen; // empresa congelada o no

  Company({
    required this.id,
    required this.name,
    required this.city,
    this.isFrozen = false,
  });

  String get fullName => '$name, $city';
}

/// Registro central de empresas (en memoria por ahora)
class CompanyRegistry {
  static final List<Company> companies = [
    Company(
      id: 'icp',
      name: 'Liceo Ignacio Carrera Pinto',
      city: 'Frutillar',
    ),
    Company(
      id: 'dll',
      name: 'Distribuidora Los Lagos',
      city: 'Puerto Montt',
    ),
    Company(
      id: 'l3p',
      name: 'Restaurant Los 3 Platos',
      city: 'Puerto Montt',
    ),
  ];
}

class CompanySelectionScreen extends StatefulWidget {
  const CompanySelectionScreen({super.key});

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  Company? _selectedCompany;

  @override
  void initState() {
    super.initState();
    if (CompanyRegistry.companies.isNotEmpty) {
      _selectedCompany = CompanyRegistry.companies.first;
    }
  }

  void _goNext() {
    final company = _selectedCompany;
    if (company == null) return;

    if (company.isFrozen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta empresa está congelada. Contacte a BioAccess.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MainMenuScreen(company: company),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companies = CompanyRegistry.companies;
    final isFrozen = _selectedCompany?.isFrozen ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo + título
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.bgSection,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'BioAccess',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sistema de control de acceso biométrico',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Combobox de empresas
                  DropdownButtonFormField<Company>(
                    value: _selectedCompany,
                    decoration: const InputDecoration(
                      labelText: 'Empresa / institución',
                    ),
                    items: companies
                        .map(
                          (c) => DropdownMenuItem<Company>(
                            value: c,
                            child: Row(
                              children: [
                                Text(c.name),
                                if (c.isFrozen) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.lock,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCompany = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (isFrozen)
                    const Text(
                      'Esta empresa se encuentra congelada.\n'
                      'Las marcaciones están deshabilitadas hasta regularizar el servicio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _selectedCompany == null ? null : _goNext,
                      child: const Text('Comenzar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
