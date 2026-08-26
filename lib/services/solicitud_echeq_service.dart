import '../models/solicitud_echeq.dart';
import '../utils/storage.dart';
import 'api_service.dart';

class SolicitudECheqService {
  Future<List<SolicitudECheq>> obtenerTodas() async {
    final rol = await Storage.obtenerRol();

    final endpoint = rol == 'CLIENTE'
        ? 'solicitudes/mis-solicitudes'
        : 'solicitudes';

    final data = await ApiService.get(endpoint);

    return (data as List)
        .map((json) => SolicitudECheq.fromJson(json as Map<String, dynamic>))
        .toList();
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
