import '../models/auditoria.dart';
import 'api_service.dart';

class AuditoriaService {
  static Future<List<Auditoria>> obtenerTodas() async {
    final data = await ApiService.get('auditorias');

    return (data as List)
        .map((json) => Auditoria.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
