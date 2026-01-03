class UserPermission {
  final int id;
  final int userId;
  final String tipo; // administrativo, especial, licencia, vacaciones
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado; // pendiente, aprobado, rechazado
  final bool aprobado; // compatibilidad bool
  final String? observacion;
  final DateTime createdAt;

  // Nuevos campos opcionales
  final String? nombre;
  final String? apellido;
  final String? rut;
  final DateTime? decidedAt;
  final int? decidedBy;

  const UserPermission({
    required this.id,
    required this.userId,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.aprobado,
    required this.createdAt,
    this.observacion,
    this.nombre,
    this.apellido,
    this.rut,
    this.decidedAt,
    this.decidedBy,
  });

  bool get isPendiente => estado == 'pendiente';
  bool get isAprobado => estado == 'aprobado' || aprobado == true;
  bool get isRechazado => estado == 'rechazado';

  String get rangoFechas =>
      '${_formatDate(fechaInicio)}  →  ${_formatDate(fechaFin)}';

  String get displayName {
    final n = (nombre ?? '').trim();
    final a = (apellido ?? '').trim();
    if (n.isEmpty && a.isEmpty) return 'Usuario ID $userId';
    return '$n $a'.trim();
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String? v) {
      if (v == null || v.isEmpty) return DateTime.now();
      return DateTime.parse(v);
    }

    final estadoStr = (json['estado'] ?? 'pendiente').toString();

    final rawAprobado = json['aprobado'];
    bool aprobadoBool;
    if (rawAprobado is bool) {
      aprobadoBool = rawAprobado;
    } else if (rawAprobado is num) {
      aprobadoBool = rawAprobado == 1;
    } else if (rawAprobado is String) {
      aprobadoBool = rawAprobado == '1' || rawAprobado.toLowerCase() == 'true';
    } else {
      aprobadoBool = estadoStr == 'aprobado';
    }

    return UserPermission(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      tipo: json['tipo'] ?? '',
      fechaInicio: parseDate(json['fecha_inicio']),
      fechaFin: parseDate(json['fecha_fin']),
      estado: estadoStr,
      aprobado: aprobadoBool,
      observacion: json['observacion'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      nombre: json['nombre'],
      apellido: json['apellido'],
      rut: json['rut'],
      decidedAt: json['decided_at'] != null && json['decided_at'] != ''
          ? DateTime.tryParse(json['decided_at'].toString())
          : null,
      decidedBy: json['decided_by'] != null
          ? int.tryParse(json['decided_by'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    return {
      'id': id,
      'user_id': userId,
      'tipo': tipo,
      'fecha_inicio': fmt(fechaInicio),
      'fecha_fin': fmt(fechaFin),
      'estado': estado,
      'aprobado': aprobado ? 1 : 0,
      'observacion': observacion,
      'created_at': createdAt.toIso8601String(),
      'nombre': nombre,
      'apellido': apellido,
      'rut': rut,
      'decided_at': decidedAt?.toIso8601String(),
      'decided_by': decidedBy,
    };
  }
}
