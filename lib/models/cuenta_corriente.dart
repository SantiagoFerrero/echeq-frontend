class CuentaCorriente {
  final int? id;

  final int cuentaBancoId;

  final int cuentaId;
  final String numeroCuenta;

  final int usuarioId;
  final String usuarioNombre;

  final int bancoId;
  final String nombreBanco;

  final String cbu;
  final String alias;

  final String fechaApertura;
  final double limiteDescubierto;
  final String numeroCuentaCorriente;

  const CuentaCorriente({
    this.id,
    required this.cbu,
    required this.alias,
    required this.cuentaBancoId,
    this.cuentaId = 0,
    this.numeroCuenta = '',
    this.usuarioId = 0,
    this.usuarioNombre = '',
    this.bancoId = 0,
    this.nombreBanco = '',
    this.fechaApertura = '',
    this.limiteDescubierto = 0,
    this.numeroCuentaCorriente = '',
  });

  factory CuentaCorriente.fromJson(Map<String, dynamic> json) {
    return CuentaCorriente(
      id: _toNullableInt(json['id']),
      cuentaBancoId: _toInt(json['cuentaBancoId']),
      cuentaId: _toInt(json['cuentaId']),
      numeroCuenta: json['numeroCuenta']?.toString() ?? '',
      usuarioId: _toInt(json['usuarioId']),
      usuarioNombre: json['usuarioNombre']?.toString() ?? '',
      bancoId: _toInt(json['bancoId']),
      nombreBanco: json['nombreBanco']?.toString() ?? '',
      cbu: json['cbu']?.toString() ?? '',
      alias: json['alias']?.toString() ?? '',
      fechaApertura: json['fechaApertura']?.toString() ?? '',
      limiteDescubierto: _toDouble(json['limiteDescubierto']),
      numeroCuentaCorriente: json['numeroCuentaCorriente']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toCrearJson() {
    return {
      'cuentaBancoId': cuentaBancoId,
      'cbu': cbu,
      'alias': alias,
      'numeroCuentaCorriente': numeroCuentaCorriente,
      'limiteDescubierto': limiteDescubierto,
    };
  }

  Map<String, dynamic> toJson() {
    return toCrearJson();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
