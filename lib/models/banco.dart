class Banco {
  final int? id;
  final String nombre;
  final String codigo;

  Banco({
    this.id,
    required this.nombre,
    required this.codigo,
  });

  factory Banco.fromJson(Map<String, dynamic> json) {
    return Banco(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      codigo: json['codigoBanco'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "codigoBanco": codigo,
    };
  }
}