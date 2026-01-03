// lib/features/auth/domain/app_user.dart

import 'user_role.dart';

class AppUser {
  final String id;
  final String nombre;
  final String apellido;
  final String rut;
  final String? correo;

  /// ID de empresa (null solo si es superadmin global)
  final String? companyId;

  /// Nombre de empresa (nuevo)
  final String? companyName;

  /// Ciudad / ubicación (nuevo)
  final String? companyLocation;

  final UserRole rol;

  /// Solo para demo, no se usa en producción
  final String passwordPlain;

  const AppUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.rut,
    this.correo,
    this.companyId,
    this.companyName,
    this.companyLocation,
    required this.rol,
    this.passwordPlain = '',
  });

  AppUser copyWith({
    String? nombre,
    String? apellido,
    String? rut,
    String? correo,
    UserRole? rol,
    String? passwordPlain,
    String? companyId,
    String? companyName,
    String? companyLocation,
  }) {
    return AppUser(
      id: id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      rut: rut ?? this.rut,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyLocation: companyLocation ?? this.companyLocation,
      passwordPlain: passwordPlain ?? this.passwordPlain,
    );
  }

  /// Construcción desde auth_login.php
  factory AppUser.fromApiJson(Map<String, dynamic> json) {
    final dynamicId = json['id'];
    final dynamicCompanyId = json['company_id'];

    // Extraer empresa completa si viene como objeto
    final companyJson = json['company'];
    final companyName =
        companyJson != null ? companyJson['name']?.toString() : null;
    final companyLocation =
        companyJson != null ? companyJson['location']?.toString() : null;

    // Rol
    final roleStr =
        (json['role'] ?? json['rol'] ?? 'user').toString().toLowerCase();

    UserRole role;
    switch (roleStr) {
      case 'superadmin':
      case 'super_admin':
        role = UserRole.superAdmin;
        break;
      case 'admin':
        role = UserRole.admin;
        break;
      default:
        role = UserRole.user;
    }

    return AppUser(
      id: dynamicId?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      rut: json['rut']?.toString() ?? '',
      correo: (json['correo'] ?? json['email'])?.toString(),
      companyId: dynamicCompanyId?.toString(),
      companyName: companyName,
      companyLocation: companyLocation,
      rol: role,
      passwordPlain: '',
    );
  }
}
