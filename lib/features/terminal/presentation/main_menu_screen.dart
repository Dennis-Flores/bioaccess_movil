// lib/features/terminal/presentation/main_menu_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../auth/presentation/admin_login_screen.dart';
import '../../auth/presentation/company_selection_screen.dart';
import 'terminal_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final Company company;

  const MainMenuScreen({super.key, required this.company});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeStr =>
      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';

  String get _dateStr =>
      '${_now.day.toString().padLeft(2, '0')}/${_now.month.toString().padLeft(2, '0')}/${_now.year}';

  @override
  Widget build(BuildContext context) {
    final company = widget.company;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgHeader,
        title: Text(company.name),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ====== RELOJ GRANDE CON GLOW ======
              Column(
                children: [
                  Text(
                    _timeStr,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: AppColors.primary.withOpacity(0.45),
                            ),
                            Shadow(
                              blurRadius: 40,
                              color: AppColors.primary.withOpacity(0.20),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateStr,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),


              // ====== CARD CENTRAL DE PUNTO DE CONTROL ======
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgSection,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Punto de control',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Empresa: ${company.fullName}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TerminalScreen(
                                      company: company,
                                      mode: TerminalMode.checkIn,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Realizar ingreso'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TerminalScreen(
                                      company: company,
                                      mode: TerminalMode.checkOut,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Realizar salida'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(
                            height: 24,
                            color: AppColors.bg,
                          ),
                          const Text(
                            'Otras opciones',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdminLoginScreen(
                                      company: company,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Ingresar como cliente / administrador',
                                style: TextStyle(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
