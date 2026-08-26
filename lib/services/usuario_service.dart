import '../models/usuario.dart';
import 'api_service.dart';

class UsuarioService {
  static Future<List<Usuario>> getUsuarios() async {
    final data = await ApiService.get('usuarios');

    return (data as List)
        .map((json) => Usuario.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<dynamic> cambiarRol(int usuarioId, int rolId) async {
    return ApiService.patch('usuarios/$usuarioId/rol', {'rolId': rolId});
  }

  static Future<dynamic> eliminarUsuario(int id) async {
    return ApiService.delete('usuarios/$id');
  }
}
