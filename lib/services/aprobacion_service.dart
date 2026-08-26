import '../models/aprobacion.dart';
import 'api_service.dart';

class AprobacionService {
  static Future<List<Aprobacion>> obtenerTodas() async {
    final data = await ApiService.get('aprobaciones');

    final aprobaciones = (data as List)
        .map((json) => Aprobacion.fromJson(json as Map<String, dynamic>))
        .toList();

    aprobaciones.sort((a, b) {
      final fechaA = a.fechaDecision;
      final fechaB = b.fechaDecision;

      if (fechaA == null && fechaB == null) {
        return 0;
      }

      if (fechaA == null) {
        return 1;
      }

      if (fechaB == null) {
        return -1;
      }

      return fechaB.compareTo(fechaA);
    });

    return aprobaciones;
  }

  static Future<Aprobacion> obtenerPorSolicitud(int solicitudId) async {
    final data = await ApiService.get('aprobaciones/solicitud/$solicitudId');

    return Aprobacion.fromJson(data as Map<String, dynamic>);
  }
}
