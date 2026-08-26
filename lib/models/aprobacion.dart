class Aprobacion {
  final int id;
  final int solicitudId;
  final int usuarioId;
  final String usuarioNombre;
  final String decision;
  final DateTime? fechaDecision;
  final String? observacion;

  const Aprobacion({
    required this.id,
    required this.solicitudId,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.decision,
    this.fechaDecision,
    this.observacion,
  });

  factory Aprobacion.fromJson(Map<String, dynamic> json) {
    return Aprobacion(
      id: _toInt(json['id']),
      solicitudId: _toInt(json['solicitudId']),
      usuarioId: _toInt(json['usuarioId']),
      usuarioNombre: json['usuarioNombre']?.toString() ?? '',
      decision: json['decision']?.toString() ?? '',
      fechaDecision: json['fechaDecision'] != null
          ? DateTime.tryParse(json['fechaDecision'].toString())
          : null,
      observacion: json['observacion']?.toString(),
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
