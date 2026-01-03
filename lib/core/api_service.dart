// lib/core/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bioaccess_movil/features/permissions/domain/user_permission.dart';


import 'config.dart';

class ApiService {
  // URL base según AppConfig (web, desktop, android, etc.)
  static String get _baseUrl => AppConfig.apiBaseUrl;

  // ===== LOGIN =====
  static Future<Map<String, dynamic>> login({
  required String rut,
  required String password,
  required int companyId,
}) async {
  final urlStr = '$_baseUrl/auth_login.php';
  final url = Uri.parse(urlStr);

  print('=== LOGIN ===');
  print('BASE: $_baseUrl');
  print('URL : $urlStr');

  try {
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'rut': rut,
            'password': password,
            'company_id': companyId,
          }),
        )
        .timeout(const Duration(seconds: 12));

    print('HTTP ${response.statusCode}');
    print('BODY: ${utf8.decode(response.bodyBytes)}');

    return _decode(response);
  } catch (e, st) {
    print('❌ LOGIN EXCEPTION: $e');
    print(st);
    rethrow;
  }
}


  // =====================================================
  // SUPERADMIN — EMPRESAS
  // =====================================================

  static Future<Map<String, dynamic>> getCompaniesList() async {
    final url = Uri.parse('$_baseUrl/companies_list.php');
    final res = await http.get(url);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> setCompanyFrozen({
    required int companyId,
    required bool isFrozen,
  }) async {
    final url = Uri.parse('$_baseUrl/company_set_frozen.php');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'company_id': companyId,
        'is_frozen': isFrozen ? 1 : 0,
      }),
    );

    return _decode(res);
  }

  // =====================================================
  // ADMIN — USUARIOS DE EMPRESA
  // =====================================================

  static Future<Map<String, dynamic>> getCompanyUsers({
    required int companyId,
  }) async {
    final url = Uri.parse('$_baseUrl/company_users.php?company_id=$companyId');
    final res = await http.get(url);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> createUser({
    required int companyId,
    required String nombre,
    required String apellido,
    required String rut,
    String? correo,
    required String password,
    required String rol,
    bool biometriaEnabled = false,
    bool huellaEnabled = false,
    bool activo = true,
  }) async {
    final url = Uri.parse('$_baseUrl/user_create.php');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'company_id': companyId,
        'nombre': nombre,
        'apellido': apellido,
        'rut': rut,
        'correo': correo,
        'password': password,
        'rol': rol,
        'biometria_enabled': biometriaEnabled ? 1 : 0,
        'huella_enabled': huellaEnabled ? 1 : 0,
        'activo': activo ? 1 : 0,
      }),
    );

    return _decode(res);
  }

    static Future<Map<String, dynamic>> updateUser({
    required int id,
    required String nombre,
    required String apellido,
    required String rut,
    String? correo,
    required String rol,
    required bool activo,
    String? password,
    bool biometriaEnabled = false,
    bool huellaEnabled = false,
  }) async {
    final url = Uri.parse('$_baseUrl/user_update.php');

    final body = <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'rut': rut,
      'correo': correo,
      'rol': rol,
      'activo': activo,
      // NUEVO:
      'biometria_enabled': biometriaEnabled ? 1 : 0,
      'huella_enabled': huellaEnabled ? 1 : 0,
    };

    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    return _decode(res);
  }


  static Future<Map<String, dynamic>> deleteUser({
    required int userId,
    required int companyId,
  }) async {
    final url = Uri.parse('$_baseUrl/user_delete.php');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'user_id': userId,
        'company_id': companyId,
      }),
    );

    return _decode(res);
  }

  // =====================================================
  // HORARIOS
  // =====================================================

  static Future<Map<String, dynamic>> getUserSchedule(int userId) async {
    final url = Uri.parse('$_baseUrl/user_schedule_get.php?user_id=$userId');
    final res = await http.get(url);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> saveUserSchedule(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$_baseUrl/user_schedule_save.php');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    return _decode(res);
  }

  // =====================================================
  // RESUMEN USUARIO / DIARIO
  // =====================================================

  // =====================================================
  // MODO RELOJ / MARCA ASISTENCIA
  // =====================================================

  /// Marca asistencia desde modo reloj (kiosko).
  /// Envía company_id (del admin conectado) + rut del funcionario.
  static Future<Map<String, dynamic>> markAttendanceKiosk({
    required int companyId,
    required String rut,
  }) async {
    final url = Uri.parse('$_baseUrl/attendance_mark.php');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'company_id': companyId,
        'rut': rut,
      }),
    );

    return _decode(res);
  }

  static Future<Map<String, dynamic>> getUserMonthSummary({
    required int userId,
    required int year,
    required int month,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/attendance_month_summary.php'
      '?user_id=$userId&year=$year&month=$month',
    );

    final res = await http.get(url);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> getUserDaySummary({
    required int userId,
    required String date,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/attendance_day_summary.php'
      '?user_id=$userId&date=$date',
    );

    final res = await http.get(url);
    return _decode(res);
  }

  // =====================================================
  // RESUMEN EMPRESA COMPLETA
  // =====================================================

  static Future<Map<String, dynamic>> getCompanyMonthSummary({
    required int companyId,
    required int year,
    required int month,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/attendance_month_company.php'
      '?company_id=$companyId&year=$year&month=$month',
    );

    final res = await http.get(url);
    return _decode(res);
  }

  // EXPORT

  static String buildUserMonthExportUrl({
    required int userId,
    required int year,
    required int month,
    String format = 'pdf',
  }) {
    return '$_baseUrl/attendance_month_export.php'
        '?user_id=$userId&year=$year&month=$month&format=$format';
  }

  static String buildCompanyMonthExportUrl({
    required int companyId,
    required int year,
    required int month,
    String format = 'pdf',
  }) {
    return '$_baseUrl/attendance_month_company_export.php'
        '?company_id=$companyId&year=$year&month=$month&format=$format';
  }

    // =====================================================
  // PERMISOS / LICENCIAS
  // =====================================================

  /// Lista permisos de un usuario (modo "crudo", devuelve Map con data).
  ///
  /// Parámetros opcionales:
  ///  - [aprobado]: si se pasa, filtra por true (1) / false (0)
  ///  - [dateFrom], [dateTo]: rango de fechas (YYYY-MM-DD) usando fechas inclusivas
  static Future<Map<String, dynamic>> getUserPermissions({
    required int userId,
    bool? aprobado,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final query = <String, String>{
      'user_id': userId.toString(),
      if (aprobado != null) 'aprobado': aprobado ? '1' : '0',
      if (dateFrom != null) 'date_from': _fmtDate(dateFrom),
      if (dateTo != null) 'date_to': _fmtDate(dateTo),
    };

    final url = Uri.parse('$_baseUrl/user_permissions_list.php')
        .replace(queryParameters: query);

    final res = await http.get(url);
    return _decode(res);
  }

  /// Crea un nuevo permiso para un usuario (modo "crudo").
  static Future<Map<String, dynamic>> createUserPermission({
    required int userId,
    required String tipo, // 'licencia', 'administrativo', etc.
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? observacion,
    bool aprobado = true,
  }) async {
    final url = Uri.parse('$_baseUrl/user_permissions_create.php');

    final body = {
      'user_id': userId,
      'tipo': tipo,
      'fecha_inicio': _fmtDate(fechaInicio),
      'fecha_fin': _fmtDate(fechaFin),
      'observacion': observacion ?? '',
      'aprobado': aprobado ? 1 : 0,
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    return _decode(res);
  }

  /// Actualiza un permiso existente (ej: aprobar/rechazar, cambiar fechas, etc.).
  static Future<Map<String, dynamic>> updateUserPermission({
    required int id,
    String? tipo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? observacion,
    bool? aprobado,
  }) async {
    final url = Uri.parse('$_baseUrl/user_permissions_update.php');

    final body = <String, dynamic>{
      'id': id,
    };

    if (tipo != null) body['tipo'] = tipo;
    if (fechaInicio != null) body['fecha_inicio'] = _fmtDate(fechaInicio);
    if (fechaFin != null) body['fecha_fin'] = _fmtDate(fechaFin);
    if (observacion != null) body['observacion'] = observacion;
    if (aprobado != null) body['aprobado'] = aprobado ? 1 : 0;

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    return _decode(res);
  }

  // =====================================================
  // WORKFLOW SOLICITUDES (USUARIO / ADMIN)
  // =====================================================

  /// Solicitud de permiso hecha por el usuario (queda en estado 'pendiente').
  static Future<bool> createPermissionRequest({
    required int userId,
    required String tipo,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? observacion,
  }) async {
    final url = Uri.parse('$_baseUrl/permission_request_create.php');

    final body = {
      'user_id': userId,
      'tipo': tipo,
      'fecha_inicio': _fmtDate(fechaInicio),
      'fecha_fin': _fmtDate(fechaFin),
      'observacion': observacion ?? '',
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    final decoded = _safeDecode(res);
    return decoded['success'] == true || decoded['ok'] == true;
  }

  /// Lista de permisos del usuario (para "Mis solicitudes"), en modelo.
  static Future<List<UserPermission>> getUserPermissionsSimple(int userId) async {
    if (userId <= 0) return [];

    try {
      final url =
          Uri.parse('$_baseUrl/user_permissions_list.php?user_id=$userId');

      final res = await http.get(url);
      final raw = utf8.decode(res.bodyBytes);
      final data = jsonDecode(raw);

      if (data is List) {
        return data
            .map((e) => UserPermission.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }

      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => UserPermission.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getUserPermissionsSimple: $e');
    }

    return [];
  }

  /// Permisos pendientes para la empresa (Admin), en modelo.
  static Future<List<UserPermission>> getPendingPermissionsForCompany(
      int companyId) async {
    if (companyId <= 0) return [];

    try {
      final url = Uri.parse(
          '$_baseUrl/permissions_pending_list.php?company_id=$companyId');

      final res = await http.get(url);
      final raw = utf8.decode(res.bodyBytes);
      final data = jsonDecode(raw);

      if (data is List) {
        return data
            .map((e) => UserPermission.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }

      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => UserPermission.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getPendingPermissionsForCompany: $e');
    }

    return [];
  }

    /// Historial de permisos de la empresa (todos los estados).
  ///
  /// [estado] opcional: 'pendiente', 'aprobado', 'rechazado'
  static Future<List<UserPermission>> getCompanyPermissionsHistory({
    required int companyId,
    String? estado,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    if (companyId <= 0) return [];

    final params = <String, String>{
      'company_id': companyId.toString(),
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (dateFrom != null) 'date_from': _fmtDate(dateFrom),
      if (dateTo != null) 'date_to': _fmtDate(dateTo),
    };

    try {
      final url = Uri.parse('$_baseUrl/permissions_history.php')
          .replace(queryParameters: params);

      final res = await http.get(url);
      final raw = utf8.decode(res.bodyBytes);
      final data = jsonDecode(raw);

      if (data is List) {
        return data
            .map((e) => UserPermission.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getCompanyPermissionsHistory: $e');
    }

    return [];
  }


  /// Admin aprueba o rechaza un permiso.
    static Future<bool> setPermissionStatus({
    required int id,
    required String estado, // 'aprobado' o 'rechazado'
    String? observacion,
    int? adminId,
  }) async {
    final url = Uri.parse('$_baseUrl/permission_set_status.php');

    final body = {
      'id': id,
      'estado': estado,
      'observacion': observacion ?? '',
      if (adminId != null) 'admin_id': adminId,
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    final decoded = _safeDecode(res);
    return decoded['success'] == true || decoded['ok'] == true;
  }


  /// Decoder "flexible" usado en los endpoints de permisos.
  static Map<String, dynamic> _safeDecode(http.Response response) {
    try {
      final raw = utf8.decode(response.bodyBytes);
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) return data;
      return {'ok': false, 'error': 'Respuesta inesperada del servidor.'};
    } catch (_) {
      return {'ok': false, 'error': 'Error procesando respuesta del servidor.'};
    }
  }


  /// Helper interno para formatear fechas como 'YYYY-MM-DD'
  static String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // =====================================================
  // DECODER CENTRAL
  // =====================================================

  static Map<String, dynamic> _decode(http.Response response) {
    try {
      final raw = utf8.decode(response.bodyBytes);
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) return data;

      return {'ok': false, 'error': 'Respuesta inesperada del servidor.'};
    } catch (_) {
      return {'ok': false, 'error': 'Error procesando respuesta del servidor.'};
    }
  }
}
