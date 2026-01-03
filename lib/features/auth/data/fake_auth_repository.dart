// lib/features/auth/data/fake_auth_repository.dart

import '../domain/app_user.dart';
import '../domain/user_role.dart';

class FakeAuthRepository {
  // Lista base de usuarios demo (mutable)
  static final List<AppUser> _users = [
    // SUPERADMIN (sin empresa asociada)
    const AppUser(
      id: 'u1',
      nombre: 'Dennis',
      apellido: 'Flores',
      rut: '11111111-1',
      correo: 'dennis@bioaccess.cl',
      rol: UserRole.superAdmin,
      passwordPlain: 'super123',
      companyId: null,
    ),

    // Admins por empresa
    const AppUser(
      id: 'u2',
      nombre: 'Admin',
      apellido: 'ICP',
      rut: '22222222-2',
      correo: 'admin.icp@bioaccess.cl',
      rol: UserRole.admin,
      passwordPlain: 'adminicp',
      companyId: 'icp',
    ),
    const AppUser(
      id: 'u3',
      nombre: 'Admin',
      apellido: 'Distribuidora',
      rut: '33333333-3',
      correo: 'admin.dll@bioaccess.cl',
      rol: UserRole.admin,
      passwordPlain: 'admindll',
      companyId: 'dll',
    ),
    const AppUser(
      id: 'u4',
      nombre: 'Admin',
      apellido: 'Los 3 Platos',
      rut: '44444444-4',
      correo: 'admin.l3p@bioaccess.cl',
      rol: UserRole.admin,
      passwordPlain: 'adminl3p',
      companyId: 'l3p',
    ),

    // Usuario de prueba (funcionario)
    const AppUser(
      id: 'u5',
      nombre: 'Juan',
      apellido: 'Pérez',
      rut: '12345678-9',
      correo: 'juan.perez@icp.cl',
      rol: UserRole.user,
      passwordPlain: 'user123',
      companyId: 'icp',
    ),
  ];

  /// Login por RUT + contraseña.
  /// Si [companyId] no es null, se limita a esa empresa
  /// (excepto SUPERADMIN que puede entrar siempre).
  Future<AppUser?> login({
    required String rut,
    required String password,
    required String companyId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final normalizedRut = rut.trim();
    final normalizedPass = password.trim();

    for (final user in _users) {
      if (user.rut == normalizedRut &&
          user.passwordPlain == normalizedPass) {
        if (user.isSuperAdmin) return user; // ve todas
        if (user.companyId == companyId) return user;
      }
    }
    return null;
  }

  /// Usuarios visibles para una empresa (admins y usuarios).
  /// Si [includeAdmins] es false, devuelve solo usuarios (rol USER).
  List<AppUser> usersForCompany(String companyId,
      {bool includeAdmins = true}) {
    return _users.where((u) {
      if (u.companyId != companyId) return false;
      if (!includeAdmins && !u.isUser) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
  }

  AppUser? getById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Crea un nuevo usuario para una empresa.
  AppUser createUser({
    required String companyId,
    required String nombre,
    required String apellido,
    required String rut,
    required String password,
    required UserRole rol,
    String? correo,
  }) {
    final newUser = AppUser(
      id: 'u${_users.length + 1}',
      nombre: nombre,
      apellido: apellido,
      rut: rut.trim(),
      correo: correo,
      rol: rol,
      passwordPlain: password.trim(),
      companyId: companyId,
    );

    _users.add(newUser);
    return newUser;
  }

  /// Actualiza un usuario existente (nombre, apellido, correo, rut, rol, pass).
  AppUser? updateUser({
    required String id,
    String? nombre,
    String? apellido,
    String? rut,
    String? correo,
    String? password,
    UserRole? rol,
  }) {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return null;

    final current = _users[index];
    final updated = current.copyWith(
      nombre: nombre,
      apellido: apellido,
      rut: rut,
      correo: correo,
      passwordPlain: password,
      rol: rol,
    );

    _users[index] = updated;
    return updated;
  }

  /// Elimina definitivamente un usuario (en producción sería "desactivar").
  bool deleteUser(String id) {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return false;
    _users.removeAt(index);
    return true;
  }
}
