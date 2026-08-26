class Usuario {
  final int? id;
  final String nombre;
  final String apellido;
  final String email;
  final bool activo;
  final int rolId;

  const Usuario({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.activo,
    required this.rolId,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: _toNullableInt(json['id']),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      activo: json['activo'] == true,
      rolId: _toInt(json['rolId']),
    );
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

  String get nombreCompleto {
    return '$nombre $apellido'.trim();
  }
}
