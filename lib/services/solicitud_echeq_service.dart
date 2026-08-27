import 'dart:typed_data';

import '../models/solicitud_echeq.dart';
import '../utils/storage.dart';
import 'api_service.dart';

class SolicitudECheqService {
  Future<List<SolicitudECheq>> obtenerTodas({
    int? usuarioId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? estado,
    String? concepto,
  }) async {
    final rol = await Storage.obtenerRol();

    final endpointBase = rol == 'CLIENTE'
        ? 'solicitudes/mis-solicitudes'
        : 'solicitudes';

    final parametros = <String, String>{};

    if (rol != 'CLIENTE' && usuarioId != null) {
      parametros['usuarioId'] = usuarioId.toString();
    }

    if (fechaDesde != null) {
      parametros['fechaDesde'] = _formatearFecha(fechaDesde);
    }

    if (fechaHasta != null) {
      parametros['fechaHasta'] = _formatearFecha(fechaHasta);
    }

    if (estado != null &&
        estado.trim().isNotEmpty &&
        estado != 'TODOS') {
      parametros['estado'] = estado.trim();
    }

    if (concepto != null && concepto.trim().isNotEmpty) {
      parametros['concepto'] = concepto.trim();
    }

    final endpoint = Uri(
      path: endpointBase,
      queryParameters: parametros.isEmpty ? null : parametros,
    ).toString();

    final data = await ApiService.get(endpoint);

    return (data as List)
        .map(
          (json) => SolicitudECheq.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  String _formatearFecha(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '$anio-$mes-$dia';
  }

  Future<Uint8List> exportar({
    int? usuarioId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? estado,
    String? concepto,
  }) async {
    final parametros = <String, String>{};

    if (usuarioId != null) {
      parametros['usuarioId'] = usuarioId.toString();
    }

    if (fechaDesde != null) {
      parametros['fechaDesde'] = _formatearFecha(fechaDesde);
    }

    if (fechaHasta != null) {
      parametros['fechaHasta'] = _formatearFecha(fechaHasta);
    }

    if (estado != null &&
        estado.trim().isNotEmpty &&
        estado != 'TODOS') {
      parametros['estado'] = estado.trim();
    }

    if (concepto != null && concepto.trim().isNotEmpty) {
      parametros['concepto'] = concepto.trim();
    }

    final endpoint = Uri(
      path: 'solicitudes/exportar',
      queryParameters: parametros.isEmpty ? null : parametros,
    ).toString();

    return ApiService.getBytes(endpoint);
  }

  Future<SolicitudECheq> obtenerPorId(int id) async {
    final data = await ApiService.get('solicitudes/$id');

    return SolicitudECheq.fromJson(data as Map<String, dynamic>);
  }

  Future<SolicitudECheq> crear(SolicitudECheq solicitud) async {
    final data = await ApiService.post('solicitudes', solicitud.toCrearJson());

    return SolicitudECheq.fromJson(data as Map<String, dynamic>);
  }

  Future<SolicitudECheq> actualizar(int id, SolicitudECheq solicitud) async {
    final data = await ApiService.put(
      'solicitudes/$id',
      solicitud.toActualizarJson(),
    );

    return SolicitudECheq.fromJson(data as Map<String, dynamic>);
  }

  Future<SolicitudECheq> actualizarEstado(
    int id,
    String estado, {
    String? observacion,
  }) async {
    final data = await ApiService.patch('solicitudes/$id/estado', {
      'estado': estado,
      if (observacion != null && observacion.trim().isNotEmpty)
        'observacion': observacion.trim(),
    });

    return SolicitudECheq.fromJson(data as Map<String, dynamic>);
  }

  Future<void> eliminar(int id) async {
    await ApiService.delete('solicitudes/$id');
  }
}
