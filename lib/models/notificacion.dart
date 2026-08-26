class Notificacion {
  final int id;
  final int usuarioId;
  final int solicitudId;
  final String mensaje;
  final bool leida;
  final DateTime? fechaEnvio;

  const Notificacion({
    required this.id,
    required this.usuarioId,
    required this.solicitudId,
    required this.mensaje,
    required this.leida,
    this.fechaEnvio,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: _toInt(json['id']),
      usuarioId: _toInt(json['usuarioId']),
      solicitudId: _toInt(json['solicitudId']),
      mensaje: json['mensaje']?.toString() ?? '',
      leida: json['leida'] == true,
      fechaEnvio: json['fechaEnvio'] != null
          ? DateTime.tryParse(json['fechaEnvio'].toString())
          : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
