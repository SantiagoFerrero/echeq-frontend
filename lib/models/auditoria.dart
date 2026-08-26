class Auditoria {
  final int id;
  final String accion;
  final String detalle;
  final DateTime? fechaHora;
  final int usuarioId;
  final String usuarioNombre;

  const Auditoria({
    required this.id,
    required this.accion,
    required this.detalle,
    this.fechaHora,
    required this.usuarioId,
    required this.usuarioNombre,
  });

  factory Auditoria.fromJson(Map<String, dynamic> json) {
    return Auditoria(
      id: _toInt(json['id']),
      accion: json['accion']?.toString() ?? '',
      detalle: json['detalle']?.toString() ?? '',
      fechaHora: json['fechaHora'] != null
          ? DateTime.tryParse(json['fechaHora'].toString())
          : null,
      usuarioId: _toInt(json['usuarioId']),
      usuarioNombre: json['usuarioNombre']?.toString() ?? '',
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
