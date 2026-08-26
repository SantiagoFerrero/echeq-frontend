import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  Storage._();

  static const String _tokenKey = 'token';
  static const String _usuarioIdKey = 'usuarioId';
  static const String _nombreKey = 'nombre';
  static const String _apellidoKey = 'apellido';
  static const String _emailKey = 'email';
  static const String _rolKey = 'rol';

  static Future<void> guardarSesion({
    required String token,
    required int usuarioId,
    required String nombre,
    required String apellido,
    required String email,
    required String rol,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_usuarioIdKey, usuarioId);
    await prefs.setString(_nombreKey, nombre);
    await prefs.setString(_apellidoKey, apellido);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_rolKey, rol);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<int?> obtenerUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_usuarioIdKey);
  }

  static Future<String?> obtenerNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nombreKey);
  }

  static Future<String?> obtenerApellido() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apellidoKey);
  }

  static Future<String?> obtenerEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> obtenerRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rolKey);
  }

  static Future<bool> haySesion() async {
    final token = await obtenerToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> limpiarSesion() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_usuarioIdKey);
    await prefs.remove(_nombreKey);
    await prefs.remove(_apellidoKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_rolKey);
  }
}
