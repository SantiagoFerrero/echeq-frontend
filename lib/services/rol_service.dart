import '../models/rol.dart';
import 'api_service.dart';

class RolService {
  static Future<List<Rol>> getRoles() async {
    final data = await ApiService.get('roles');

    return (data as List)
        .map((json) => Rol.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
