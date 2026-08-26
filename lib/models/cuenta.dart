class Cuenta {
  final int? id;
  final String numero;
  final String tipo;
  final double saldo;
  final int bancoId;
  final String bancoNombre;
  final int? usuarioId;
  final String usuarioNombre;

  const Cuenta({
    this.id,
    required this.numero,
    required this.tipo,
    required this.saldo,
    required this.bancoId,
    this.bancoNombre = '',
    this.usuarioId,
    this.usuarioNombre = '',
  });

  factory Cuenta.fromJson(Map<String, dynamic> json) {
    return Cuenta(
      id: _toNullableInt(json['id']),
      numero: json['numeroCuenta']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'CUENTA',
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      bancoId: _toInt(json['bancoId']),
      bancoNombre: json['bancoNombre']?.toString() ?? '',
      usuarioId: _toNullableInt(json['usuarioId']),
      usuarioNombre: json['usuarioNombre']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numeroCuenta': numero,
      'saldo': saldo,
      'bancoId': bancoId,
    };
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
}