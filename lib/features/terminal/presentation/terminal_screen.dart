// lib/features/terminal/presentation/terminal_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../auth/presentation/company_selection_screen.dart';
import '../../auth/data/fake_auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../data/fake_attendance_repository.dart';

  final _authRepo = FakeAuthRepository();
  final _attendanceRepo = FakeAttendanceRepository();


/// Modo del terminal: ingreso o salida
enum TerminalMode { checkIn, checkOut }

class TerminalScreen extends StatefulWidget {
  final Company company;
  final TerminalMode mode;

  const TerminalScreen({
    super.key,
    required this.company,
    required this.mode,
  });

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _rutCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final _authRepo = FakeAuthRepository();

  bool _processing = false;
  String? _lastMessage;
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Actualizar reloj cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rutCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String get _modeText =>
      widget.mode == TerminalMode.checkIn ? 'Ingreso' : 'Salida';

  Color get _modeColor =>
      widget.mode == TerminalMode.checkIn ? AppColors.success : AppColors.warning;

    Future<void> _register() async {
    // Seguridad extra: no permitir fichar si la empresa está congelada
    if (widget.company.isFrozen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empresa congelada. No es posible registrar marcaciones.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final rut = _rutCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (rut.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese RUT y contraseña')),
      );
      return;
    }

    setState(() {
      _processing = true;
      _lastMessage = null;
    });

    try {
      // Validar usuario contra el repositorio (solo empresa actual)
      final AppUser? user = await _authRepo.login(
        rut: rut,
        password: pass,
        companyId: widget.company.id,
      );

      if (user == null || !user.isUser) {
        setState(() {
          _lastMessage =
              'No se pudo registrar $_modeText: usuario no válido para esta empresa o credenciales incorrectas.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario no válido o sin permisos para fichar aquí'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Momento exacto de la marcación
      final now = DateTime.now();
      final timestampStr =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';

      // 👉 Guardar marcación en el repositorio de asistencia (demo)
      _attendanceRepo.addRecord(
        userId: user.id,
        companyId: widget.company.id,
        timestamp: now,
        isEntry: widget.mode == TerminalMode.checkIn,
      );

      setState(() {
        _lastMessage =
            '$_modeText registrado para ${user.nombreCompleto} ($rut) a las $timestampStr (demo)';
      });

      _rutCtrl.clear();
      _passCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_modeText registrado para ${user.nombreCompleto}'),
          backgroundColor: _modeColor,
        ),
      );

      // 🔁 Después de unos segundos, volver automáticamente al menú principal
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        Navigator.of(context).pop(); // vuelve a MainMenuScreen
      });
    } catch (e) {
      setState(() {
        _lastMessage = 'Error al registrar $_modeText';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al registrar'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${_now.day.toString().padLeft(2, '0')}/${_now.month.toString().padLeft(2, '0')}/${_now.year}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgHeader,
        title: Text('${widget.company.name} — $_modeText'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Reloj grande + fecha + modo
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _modeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _modeColor.withOpacity(0.6)),
                      ),
                      child: Text(
                        'Modo $_modeText',
                        style: TextStyle(
                          color: _modeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Métodos de identificación (visual)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _MethodChip(
                          icon: Icons.face_retouching_natural,
                          label: 'Biométrico facial',
                          enabled: false,
                        ),
                        _MethodChip(
                          icon: Icons.fingerprint,
                          label: 'Huella digital',
                          enabled: false,
                        ),
                        _MethodChip(
                          icon: Icons.badge,
                          label: 'RUT + contraseña',
                          enabled: true, // método activo en esta etapa
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Por seguridad, el acceso por RUT y contraseña\nse usa como respaldo cuando los métodos biométricos no están disponibles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Área de autenticación por RUT + contraseña
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Identificación por RUT + contraseña',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rutCtrl,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'RUT (sin puntos, con guion)  Ej: 12345678-9',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'Contraseña',
                    ),
                    onSubmitted: (_) => _register(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _processing ? null : _register,
                      child: _processing
                          ? const CircularProgressIndicator()
                          : Text('Registrar $_modeText'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_lastMessage != null)
                    Text(
                      _lastMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;

  const _MethodChip({
    required this.icon,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        enabled ? AppColors.primary : AppColors.textMuted.withOpacity(0.7);
    final borderColor =
        enabled ? AppColors.primary : AppColors.bgSection;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        color: enabled ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
