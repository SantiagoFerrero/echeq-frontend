import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../utils/app_navigator.dart';
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

  static Future<void> _invalidarSesion() async {
    await Storage.limpiarSesion();
    AppNavigator.irALoginPorSesionExpirada();
  }

  static Future<Map<String, String>> _headers({
    bool requiereToken = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    if (!requiereToken) {
      return headers;
    }

    final token = await Storage.obtenerToken();

    if (token == null ||
        token.isEmpty ||
        !Storage.esTokenVigente(token)) {
      await _invalidarSesion();

      throw Exception(
        'La sesión expiró. Inicie sesión nuevamente.',
      );
    }

    headers['Authorization'] = 'Bearer $token';

    return headers;
  }

  static String _extraerMensajeError(
    dynamic decoded,
    String body,
    int statusCode,
  ) {
    if (decoded is Map<String, dynamic>) {
      final errors = decoded['errors'];

      // Errores generados por @Valid en Spring.
      if (errors is Map && errors.isNotEmpty) {
        final mensajes = <String>[];

        for (final valor in errors.values) {
          final mensaje = valor?.toString().trim();

          if (mensaje != null &&
              mensaje.isNotEmpty &&
              !mensajes.contains(mensaje)) {
            mensajes.add(mensaje);
          }
        }

        if (mensajes.isNotEmpty) {
          return mensajes.join('\n');
        }
      }

      final mensajeBackend =
          decoded['message'] ??
          decoded['mensaje'] ??
          decoded['error'];

      if (mensajeBackend != null &&
          mensajeBackend.toString().trim().isNotEmpty) {
        return mensajeBackend.toString();
      }
    }

    if (decoded != null &&
        decoded.toString().trim().isNotEmpty) {
      return decoded.toString();
    }

    if (body.trim().isNotEmpty) {
      return body;
    }

    return 'Error HTTP $statusCode';
  }

  static Future<dynamic> _procesarRespuesta(
    http.Response response, {
    bool requiereToken = true,
  }) async {
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

    // Un 401 en un endpoint protegido invalida la sesión.
    if (statusCode == 401 && requiereToken) {
      await _invalidarSesion();

      throw Exception(
        'La sesión expiró. Inicie sesión nuevamente.',
      );
    }

    // Un 403 NO cierra sesión porque puede ser simplemente
    // una operación no autorizada para el rol actual.
    if (statusCode < 200 || statusCode >= 300) {
      final mensaje = _extraerMensajeError(
        decoded,
        body,
        statusCode,
      );

      throw Exception(mensaje);
    }

    return decoded;
  }

  static Future<Uint8List> getBytes(String endpoint) async {
    final headers = await _headers();

    headers['Accept'] =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    final response = await http.get(
      _uri(endpoint),
      headers: headers,
    );

    final statusCode = response.statusCode;

    if (statusCode == 401) {
      await _invalidarSesion();

      throw Exception(
        'La sesión expiró. Inicie sesión nuevamente.',
      );
    }

    if (statusCode < 200 || statusCode >= 300) {
      final body = utf8.decode(response.bodyBytes);

      dynamic decoded;

      if (body.trim().isNotEmpty) {
        try {
          decoded = jsonDecode(body);
        } catch (_) {
          decoded = body;
        }
      }

      final mensaje = _extraerMensajeError(
        decoded,
        body,
        statusCode,
      );

      throw Exception(mensaje);
    }

    return response.bodyBytes;
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      _uri(endpoint),
      headers: await _headers(),
    );

    return await _procesarRespuesta(response);
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

    return await _procesarRespuesta(response);
  }

  static Future<dynamic> postPublic(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _uri(endpoint),
      headers: await _headers(
        requiereToken: false,
      ),
      body: jsonEncode(data),
    );

    return await _procesarRespuesta(
      response,
      requiereToken: false,
    );
  }

  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      _uri(endpoint),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return await _procesarRespuesta(response);
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

    return await _procesarRespuesta(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      _uri(endpoint),
      headers: await _headers(),
    );

    return await _procesarRespuesta(response);
  }
}