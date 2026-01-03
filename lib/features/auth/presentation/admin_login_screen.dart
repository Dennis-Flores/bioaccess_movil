// lib/features/auth/presentation/admin_login_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../terminal/presentation/main_menu_screen.dart';
import '../data/fake_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/user_role.dart';
import 'company_selection_screen.dart';

// Attendance (demo)
import '../../terminal/data/fake_attendance_repository.dart';
import '../../terminal/domain/attendance_record.dart';

class AdminLoginScreen extends StatefulWidget {
  final Company company;

  const AdminLoginScreen({super.key, required this.company});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _rutCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final _repo = FakeAuthRepository();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _rutCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final rut = _rutCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (rut.isEmpty || pass.isEmpty) {
      setState(() {
        _error = 'Debe ingresar RUT y contraseña';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final user = await _repo.login(
      rut: rut,
      password: pass,
      companyId: widget.company.id,
    );

    setState(() {
      _loading = false;
    });

    if (user == null) {
      setState(() {
        _error = 'Credenciales inválidas o sin permisos para esta empresa';
      });
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AdminHomeScreen(
          user: user,
          company: widget.company,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgHeader,
        title: const Text('Acceso cliente / administrador'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      company.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingrese con su RUT y contraseña para acceder al panel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _rutCtrl,
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'RUT (sin puntos, con guion)  Ej: 11111111-1',
                        labelText: 'RUT',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Contraseña',
                        labelText: 'Contraseña',
                      ),
                      onSubmitted: (_) => _doLogin(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _doLogin,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Ingresar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Usuarios de prueba:\n'
                      'SUPERADMIN: 11111111-1 / super123\n'
                      'Admin ICP: 22222222-2 / adminicp\n'
                      'Admin Dist.: 33333333-3 / admindll\n'
                      'Admin L3P: 44444444-4 / adminl3p',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================================================================
//  ADMIN HOME SCREEN (panel con buscador + contadores + congelar)
// ===================================================================

class AdminHomeScreen extends StatefulWidget {
  final AppUser user;
  final Company company;

  const AdminHomeScreen({
    super.key,
    required this.user,
    required this.company,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FakeAuthRepository _repo = FakeAuthRepository();
  late List<AppUser> _users;

  // 🔍 Buscador
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchTerm = '';

  bool get _isSuperAdmin => widget.user.isSuperAdmin;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchCtrl.addListener(() {
      setState(() {
        _searchTerm = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadUsers() {
    _users = _repo.usersForCompany(widget.company.id, includeAdmins: true);
    _users.sort(
      (a, b) => a.nombreCompleto.compareTo(b.nombreCompleto),
    );
  }

  void _openAttendanceLog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttendanceLogScreen(company: widget.company),
      ),
    );
  }

  // --- Filtro de lista según el término de búsqueda ---
  List<AppUser> get _filteredUsers {
    if (_searchTerm.isEmpty) return _users;
    return _users.where((u) {
      final nombre = u.nombreCompleto.toLowerCase();
      final rut = u.rut.toLowerCase();
      return nombre.contains(_searchTerm) || rut.contains(_searchTerm);
    }).toList();
  }

  // --- Diálogos para agregar / editar usuarios ---
    Future<void> _showUserForm({AppUser? editing}) async {
    final isEditing = editing != null;

    final nombreCtrl = TextEditingController(text: editing?.nombre ?? '');
    final apellidoCtrl =
        TextEditingController(text: editing?.apellido ?? '');
    final rutCtrl = TextEditingController(text: editing?.rut ?? '');
    final correoCtrl =
        TextEditingController(text: editing?.correo ?? '');
    final passCtrl =
        TextEditingController(text: isEditing ? editing!.passwordPlain : '');

    // 🔐 Estado local del diálogo
    bool obscurePass = true;

    // 🔄 Por ahora solo UI, no se guarda en el modelo todavía
    bool hasFace = false;
    bool hasFingerprint = false;

    UserRole selectedRole;
    if (_isSuperAdmin) {
      selectedRole = editing?.rol ?? UserRole.admin;
    } else {
      selectedRole = editing?.rol ?? UserRole.user;
    }

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bgSection,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(isEditing ? 'Editar usuario' : 'Agregar usuario'),
          content: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Nombre'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: apellidoCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Apellido'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: rutCtrl,
                        decoration: const InputDecoration(
                          labelText: 'RUT',
                          hintText: 'Ej: 12345678-9',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: correoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo (opcional)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passCtrl,
                        obscureText: obscurePass,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePass
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                obscurePass = !obscurePass;
                              });
                            },
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // 🔄 Switch biometría facial
                      SwitchListTile(
                        value: hasFace,
                        onChanged: (v) {
                          setStateDialog(() {
                            hasFace = v;
                          });
                        },
                        title: const Text('Agregar biometría facial'),
                        subtitle: const Text(
                          'Marcar cuando el rostro esté enrolado en el sistema',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),

                      // 🔄 Switch huella digital
                      SwitchListTile(
                        value: hasFingerprint,
                        onChanged: (v) {
                          setStateDialog(() {
                            hasFingerprint = v;
                          });
                        },
                        title: const Text('Agregar huella digital'),
                        subtitle: const Text(
                          'Marcar cuando la huella esté enrolada en el sistema',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 12),

                      if (_isSuperAdmin)
                        DropdownButtonFormField<UserRole>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                              labelText: 'Rol del usuario'),
                          items: const [
                            DropdownMenuItem(
                              value: UserRole.admin,
                              child: Text('Administrador de empresa'),
                            ),
                            DropdownMenuItem(
                              value: UserRole.user,
                              child: Text('Usuario / Funcionario'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              selectedRole = value;
                            }
                          },
                        )
                      else
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Rol: Usuario / Funcionario',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // 👇 OJO: por ahora hasFace / hasFingerprint NO se guardan.
      // Más adelante ampliamos AppUser y el repo para usarlos.

      if (isEditing) {
        final updated = _repo.updateUser(
          id: editing!.id,
          nombre: nombreCtrl.text,
          apellido: apellidoCtrl.text,
          rut: rutCtrl.text,
          correo: correoCtrl.text.isEmpty ? null : correoCtrl.text,
          password: passCtrl.text,
          rol: selectedRole,
        );
        if (updated != null) {
          setState(() {
            final idx = _users.indexWhere((u) => u.id == updated.id);
            if (idx != -1) _users[idx] = updated;
            _users.sort(
              (a, b) => a.nombreCompleto.compareTo(b.nombreCompleto),
            );
          });
        }
      } else {
        final newUser = _repo.createUser(
          companyId: widget.company.id,
          nombre: nombreCtrl.text,
          apellido: apellidoCtrl.text,
          rut: rutCtrl.text,
          password: passCtrl.text,
          correo: correoCtrl.text.isEmpty ? null : correoCtrl.text,
          rol: _isSuperAdmin ? selectedRole : UserRole.user,
        );
        setState(() {
          _users.add(newUser);
          _users.sort(
            (a, b) => a.nombreCompleto.compareTo(b.nombreCompleto),
          );
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Usuario actualizado' : 'Usuario creado correctamente',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }


  Future<void> _confirmDelete(AppUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bgSection,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Eliminar usuario'),
          content: Text(
            '¿Seguro que deseas eliminar a ${user.nombreCompleto}?\n\n'
            'En producción esto sería una desactivación, no un borrado definitivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      final success = _repo.deleteUser(user.id);
      if (success) {
        setState(() {
          _users.removeWhere((u) => u.id == user.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario ${user.nombreCompleto} eliminado'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onUserTap(AppUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSection,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar usuario'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showUserForm(editing: user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Eliminar usuario'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(user);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserTile(AppUser u) {
    final isAdmin = u.isAdmin;
    final isCurrent = u.id == widget.user.id;

    return ListTile(
      onTap: () => _onUserTap(u),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isAdmin
            ? AppColors.primary.withOpacity(0.18)
            : AppColors.bgSection,
        child: Icon(
          isAdmin ? Icons.security : Icons.person_outline,
          size: 18,
          color:
              isAdmin ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      title: Text(
        u.nombreCompleto,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        'RUT: ${u.rut} · Rol: ${u.rol.label}',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
      trailing: isCurrent
          ? const Text(
              'Tú',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
              ),
            )
          : const Icon(
              Icons.more_vert,
              size: 18,
              color: AppColors.textSecondary,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rolText = widget.user.rol.label;
    final filtered = _filteredUsers;
    final admins = filtered.where((u) => u.isAdmin).toList();
    final regulars = filtered.where((u) => !u.isAdmin).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgHeader,
        title: const Text('Panel administrativo (demo)'),
        actions: [
          IconButton(
            tooltip: 'Ver marcaciones (demo)',
            icon: const Icon(Icons.list_alt),
            onPressed: _openAttendanceLog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar usuario'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Column(
          children: [
            // ======= CABECERA EN CARD =======
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSection,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                rolText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.company.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ======= ESTADO EMPRESA (SOLO SUPERADMIN) =======
            if (_isSuperAdmin)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSection,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.company.isFrozen
                          ? Icons.lock
                          : Icons.lock_open,
                      size: 18,
                      color: widget.company.isFrozen
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.company.isFrozen
                            ? 'Empresa congelada · Marcaciones deshabilitadas'
                            : 'Empresa activa · Marcaciones habilitadas',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.company.isFrozen
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          widget.company.isFrozen =
                              !widget.company.isFrozen;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.company.isFrozen
                                  ? 'Empresa congelada.'
                                  : 'Empresa reactivada.',
                            ),
                            backgroundColor: widget.company.isFrozen
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        );
                      },
                      child: Text(
                        widget.company.isFrozen ? 'Reactivar' : 'Congelar',
                      ),
                    ),
                  ],
                ),
              ),

            if (_isSuperAdmin) const SizedBox(height: 16) else const SizedBox(height: 12),

            // 🔍 BUSCADOR
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o RUT…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron usuarios con ese criterio.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        if (admins.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                            child: Text(
                              'Administradores (${admins.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          ...admins.expand((u) => [
                                _buildUserTile(u),
                                const Divider(color: AppColors.bgSection),
                              ]),
                          const SizedBox(height: 8),
                        ],
                        if (regulars.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                            child: Text(
                              'Usuarios / Funcionarios (${regulars.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          ...regulars.expand((u) => [
                                _buildUserTile(u),
                                const Divider(color: AppColors.bgSection),
                              ]),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// ====================  ATTENDANCE LOG SCREEN  ======================
// ==================================================================

class AttendanceLogScreen extends StatefulWidget {
  final Company company;

  const AttendanceLogScreen({super.key, required this.company});

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  final _attendanceRepo = FakeAttendanceRepository();
  final _authRepo = FakeAuthRepository();

  late DateTime _day;
  late List<AttendanceRecord> _records;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _load();
  }

  void _load() {
    _records = _attendanceRepo.recordsForCompany(
      widget.company.id,
      day: _day,
    );
  }

  Future<void> _reload() async {
    setState(_load);
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:' +
        '${dt.minute.toString().padLeft(2, '0')}:' +
        '${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_day.day.toString().padLeft(2, '0')}/'
        '${_day.month.toString().padLeft(2, '0')}/'
        '${_day.year}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgHeader,
        title: const Text('Marcaciones (demo)'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.company.fullName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Marcaciones del día: $dateStr',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _records.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay marcaciones registradas para este día (demo).',
                        style: TextStyle(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _records.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.bgSection),
                      itemBuilder: (context, index) {
                        final r = _records[index];
                        final AppUser? u = _authRepo.getById(r.userId);

                        final nombre = u?.nombreCompleto ?? 'Usuario desconocido';
                        final rut = u?.rut ?? '—';
                        final tipo = r.isEntry ? 'Ingreso' : 'Salida';
                        final timeStr = _formatTime(r.timestamp);

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: r.isEntry
                                ? AppColors.success.withOpacity(0.15)
                                : AppColors.warning.withOpacity(0.15),
                            child: Icon(
                              r.isEntry ? Icons.login : Icons.logout,
                              size: 18,
                              color: r.isEntry
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          title: Text(
                            nombre,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            'RUT: $rut · $tipo a las $timeStr',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
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
