// lib/features/auth/domain/user_role.dart

enum UserRole { superAdmin, admin, user }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Superadministrador';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.user:
        return 'Usuario';
    }
  }
}
