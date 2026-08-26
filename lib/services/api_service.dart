import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import '../utils/storage.dart';

class ApiService {
  ApiService._();

  static String _normalizarEndpoint(String endpoint) {
    if (endpoint.startsWith('/')) {
      return endpoint.substring(1);
    }

    return endpoint;
  }

  static Uri _uri(String endpoint) {
    return Uri.parse(
      '${AppConstants.apiBaseUrl}/${_normalizarEndpoint(endpoint)}',
    );
  }

  static Future<Map<String, String>> _headers({
    bool requiereToken = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    if (requiereToken) {
      final token = await Storage.obtenerToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static dynamic _procesarRespuesta(http.Response response) {
    final statusCode = response.statusCode;
    final body = utf8.decode(response.bodyBytes);

    dynamic decoded;

    if (body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = body;
      }
    }

    if (statusCode < 200 || statusCode >= 300) {
      String mensaje = 'Error HTTP $statusCode';

      if (decoded is Map<String, dynamic>) {
        final mensajeBackend =
            decoded['message'] ?? decoded['mensaje'] ?? decoded['error'];

        if (mensajeBackend != null) {
          mensaje = mensajeBackend.toString();
        } else if (body.isNotEmpty) {
          mensaje = body;
        }
      } else if (decoded != null) {
        mensaje = decoded.toString();
      }

      throw Exception(mensaje);
    }

    return decoded;
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(_uri(endpoint), headers: await _headers());

    return _procesarRespuesta(response);
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _uri(endpoint),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return _procesarRespuesta(response);
  }

  static Future<dynamic> postPublic(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _uri(endpoint),
      headers: await _headers(requiereToken: false),
      body: jsonEncode(data),
    );

    return _procesarRespuesta(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      _uri(endpoint),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return _procesarRespuesta(response);
  }

  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic>? data,
  ) async {
    final response = await http.patch(
      _uri(endpoint),
      headers: await _headers(),
      body: data == null ? null : jsonEncode(data),
    );

    return _procesarRespuesta(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      _uri(endpoint),
      headers: await _headers(),
    );

    return _procesarRespuesta(response);
  }
}
