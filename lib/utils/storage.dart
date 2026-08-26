import 'dart:convert';

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

  static bool esTokenVigente(String token) {
    try {
      final partes = token.split('.');

      if (partes.length != 3) {
        return false;
      }

      final payloadNormalizado =
          base64Url.normalize(partes[1]);

      final payloadTexto = utf8.decode(
        base64Url.decode(payloadNormalizado),
      );

      final decoded = jsonDecode(payloadTexto);

      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final exp = decoded['exp'];

      if (exp is! num) {
        return false;
      }

      final expiracion = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );

      // Margen de 5 segundos para evitar que el token
      // venza mientras una petición está llegando al backend.
      final ahoraConMargen = DateTime.now()
          .toUtc()
          .add(const Duration(seconds: 5));

      return ahoraConMargen.isBefore(expiracion);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> haySesion() async {
    final token = await obtenerToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    if (!esTokenVigente(token)) {
      await limpiarSesion();
      return false;
    }

    return true;
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