// lib/features/superadmin/presentation/superadmin_home_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../auth/domain/app_user.dart';
import 'superadmin_companies_screen.dart';

class SuperAdminHomeScreen extends StatelessWidget {
  final AppUser user;

  const SuperAdminHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Panel SuperAdmin'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${user.nombre} ${user.apellido}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Desde aquí puedes administrar las empresas que usan BioAccess.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: AppColors.bgSection,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.business, color: AppColors.primary),
                  title: const Text(
                    'Empresas',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Ver estado, congelar o reactivar empresas',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SuperAdminCompaniesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
