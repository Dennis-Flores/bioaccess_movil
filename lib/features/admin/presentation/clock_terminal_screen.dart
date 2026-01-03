import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:bioaccess_movil/core/config.dart';
import 'package:bioaccess_movil/core/theme.dart';
import 'package:bioaccess_movil/core/api_service.dart';
import 'package:bioaccess_movil/features/auth/domain/app_user.dart';

/// Métodos de marcaje disponibles (por ahora solo funciona RUT/código)
enum ClockMethod {
  rut,
  face,
  fingerprint,
}

class ClockTerminalScreen extends StatefulWidget {
  final AppUser adminUser;

  const ClockTerminalScreen({
    super.key,
    required this.adminUser,
  });

  @override
  State<ClockTerminalScreen> createState() => _ClockTerminalScreenState();
}

class _ClockTerminalScreenState extends State<ClockTerminalScreen> {
  final TextEditingController _rutController = TextEditingController();
  final FocusNode _rutFocus = FocusNode();

  bool _sending = false;
  String _nowTime = '';
  Timer? _clockTimer;

  String? _lastMessage;
  Color _lastColor = AppColors.textSecondary;

  // NUEVO: método de marcaje actual
  ClockMethod _method = ClockMethod.rut;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
    });
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _nowTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _rutController.dispose();
    _rutFocus.dispose();
    super.dispose();
  }

  Future<void> _doMark() async {
    // ===== POR AHORA SOLO RUT/CÓDIGO =====
    if (_method != ClockMethod.rut) {
      setState(() {
        _lastMessage =
            'Por ahora solo está habilitado el marcaje por RUT o código.';
        _lastColor = Colors.orange;
      });
      return;
    }

    final rut = _rutController.text.trim();
    if (rut.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese RUT o código del funcionario.')),
      );
      return;
    }

    final companyId =
        int.tryParse(widget.adminUser.companyId?.toString() ?? '') ?? 0;
    if (companyId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa inválida para este dispositivo.')),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final baseUrl = AppConfig.apiBaseUrl;
      final url = Uri.parse('$baseUrl/attendance_mark.php');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'company_id': companyId,
          'rut': rut,
        }),
      );

      final raw = utf8.decode(res.bodyBytes);
      final data = jsonDecode(raw);

      if (!mounted) return;

      if (data is Map && data['ok'] == true) {
        final tipo = (data['tipo'] ?? '').toString();
        final message = data['message']?.toString() ??
            'Marca registrada correctamente.';

        Color c = Colors.blue;
        if (tipo == 'IN') c = AppColors.success;
        if (tipo == 'OUT') c = AppColors.error;

        setState(() {
          _lastMessage = message;
          _lastColor = c;
        });

        _rutController.clear();
        _rutFocus.requestFocus();
      } else {
        final errorMsg =
            (data is Map && data['error'] != null)
                ? data['error'].toString()
                : 'No se pudo registrar la asistencia.';
        setState(() {
          _lastMessage = errorMsg;
          _lastColor = AppColors.error;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMessage = 'Error de conexión: $e';
        _lastColor = AppColors.error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _requestExit() async {
    final passController = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Salir de modo reloj'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Para salir, ingresa la contraseña del administrador.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pass = passController.text.trim();
                    if (pass.isEmpty) {
                      setStateDialog(() {
                        errorText = 'Ingresa la contraseña.';
                      });
                      return;
                    }

                    final rutAdmin = widget.adminUser.rut ?? '';
                    final companyId = int.tryParse(
                            widget.adminUser.companyId?.toString() ?? '') ??
                        0;

                    try {
                      final res = await ApiService.login(
                        rut: rutAdmin,
                        password: pass,
                        companyId: companyId,
                      );

                      if (res['ok'] == true) {
                        if (!context.mounted) return;
                        Navigator.of(context).pop(); // cierra diálogo
                        Navigator.of(context).pop(); // vuelve al panel admin
                      } else {
                        setStateDialog(() {
                          errorText =
                              res['error']?.toString() ?? 'Credenciales inválidas.';
                        });
                      }
                    } catch (e) {
                      setStateDialog(() {
                        errorText = 'Error de conexión: $e';
                      });
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyName = widget.adminUser.companyName ?? '';
    final companyLocation = widget.adminUser.companyLocation ?? '';

    return WillPopScope(
      onWillPop: () async => false, // bloquea botón físico/back navegador
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Modo reloj de marcaje'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Salir de modo reloj',
              onPressed: _requestExit,
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (companyName.isNotEmpty) ...[
                    Text(
                      companyName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (companyLocation.isNotEmpty)
                      Text(
                        companyLocation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // ===== Selector de método =====
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('RUT / código'),
                        selected: _method == ClockMethod.rut,
                        onSelected: (v) {
                          if (!v) return;
                          setState(() => _method = ClockMethod.rut);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Biometría (próx.)'),
                        selected: _method == ClockMethod.face,
                        onSelected: null, // deshabilitado por ahora
                      ),
                      ChoiceChip(
                        label: const Text('Huella (próx.)'),
                        selected: _method == ClockMethod.fingerprint,
                        onSelected: null, // deshabilitado por ahora
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    _nowTime,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campo solo para RUT/código
                  if (_method == ClockMethod.rut) ...[
                    TextField(
                      controller: _rutController,
                      focusNode: _rutFocus,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Ingrese RUT o código',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sending ? null : _doMark(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.how_to_reg),
                        label: Text(
                          _sending
                              ? 'Registrando...'
                              : 'Marcar entrada / salida',
                        ),
                        onPressed: _sending ? null : _doMark,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  if (_lastMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _lastColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _lastMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _lastColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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
