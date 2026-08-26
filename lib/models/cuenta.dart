class Cuenta {
  final int? id;
  final String numero;
  final String tipo;
  final double saldo;
  final int bancoId;

  Cuenta({
    this.id,
    required this.numero,
    required this.tipo,
    required this.saldo,
    required this.bancoId,
  });

  factory Cuenta.fromJson(Map<String, dynamic> json) {
    return Cuenta(
      id: json['id'],
      numero: json['numeroCuenta']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'CUENTA',
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      bancoId: json['bancoId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "numeroCuenta": numero,
      "saldo": saldo,
      "bancoId": bancoId,
    };
  }
}