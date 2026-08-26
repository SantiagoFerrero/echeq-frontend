class SolicitudECheq {
  final int? id;
  final double monto;
  final String concepto;
  final DateTime? fechaSolicitud;
  final int usuarioId;
  final String usuarioNombre;
  final int cuentaCorrienteId;
  final String? cuentaCorrienteAlias;
  final String estado;

  const SolicitudECheq({
    this.id,
    required this.monto,
    required this.concepto,
    this.fechaSolicitud,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.cuentaCorrienteId,
    this.cuentaCorrienteAlias,
    required this.estado,
  });

  // Compatibilidad temporal con la pantalla actual.
  String? get aliasCuenta => cuentaCorrienteAlias;

  factory SolicitudECheq.fromJson(Map<String, dynamic> json) {
    return SolicitudECheq(
      id: _toNullableInt(json['id']),
      monto: _toDouble(json['monto']),
      concepto: json['concepto']?.toString() ?? '',
      fechaSolicitud: json['fechaSolicitud'] != null
          ? DateTime.tryParse(json['fechaSolicitud'].toString())
          : null,
      usuarioId: _toInt(json['usuarioId']),
      usuarioNombre: json['usuarioNombre']?.toString() ?? '',
      cuentaCorrienteId: _toInt(json['cuentaCorrienteId']),
      cuentaCorrienteAlias:
          (json['aliasCuenta'] ?? json['cuentaCorrienteAlias'])?.toString(),
      estado: json['estado']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toCrearJson() {
    return {
      'usuarioId': usuarioId,
      'cuentaCorrienteId': cuentaCorrienteId,
      'monto': monto,
      'concepto': concepto,
    };
  }

  Map<String, dynamic> toActualizarJson() {
    return {
      'cuentaCorrienteId': cuentaCorrienteId,
      'monto': monto,
      'concepto': concepto,
    };
  }

  // Compatibilidad con cÃ³digo existente.
  Map<String, dynamic> toJson() {
    return toCrearJson();
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

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    return _toInt(value);
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
