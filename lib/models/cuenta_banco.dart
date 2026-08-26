class CuentaBanco {
  final int id;
  final int cuentaId;
  final String numeroCuenta;
  final int usuarioId;
  final String usuarioNombre;
  final int bancoId;
  final String nombreBanco;
  final String estado;
  final String fechaAlta;

  const CuentaBanco({
    required this.id,
    required this.cuentaId,
    required this.numeroCuenta,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.bancoId,
    required this.nombreBanco,
    required this.estado,
    required this.fechaAlta,
  });

  factory CuentaBanco.fromJson(Map<String, dynamic> json) {
    return CuentaBanco(
      id: _toInt(json['id']),
      cuentaId: _toInt(json['cuentaId']),
      numeroCuenta: json['numeroCuenta']?.toString() ?? '',
      usuarioId: _toInt(json['usuarioId']),
      usuarioNombre: json['usuarioNombre']?.toString() ?? '',
      bancoId: _toInt(json['bancoId']),
      nombreBanco: json['nombreBanco']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      fechaAlta: json['fechaAlta']?.toString() ?? '',
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
