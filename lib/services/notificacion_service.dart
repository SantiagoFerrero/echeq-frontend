import '../models/notificacion.dart';
import 'api_service.dart';

class NotificacionService {
  static Future<List<Notificacion>> obtenerMisNotificaciones() async {
    final data = await ApiService.get('notificaciones/mis-notificaciones');

    return (data as List)
        .map((json) => Notificacion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<Notificacion> marcarComoLeida(int id) async {
    final data = await ApiService.patch('notificaciones/$id/leida', null);

    return Notificacion.fromJson(data as Map<String, dynamic>);
  }
}
