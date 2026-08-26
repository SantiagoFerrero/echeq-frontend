import '../models/cuenta.dart';
import '../utils/storage.dart';
import 'api_service.dart';

class CuentaService {
  static Future<List<Cuenta>> getCuentas() async {
    final rol = await Storage.obtenerRol();

    final endpoint = rol == 'CLIENTE' ? 'cuentas/mis-cuentas' : 'cuentas';

    final data = await ApiService.get(endpoint);

    return (data as List)
        .map((json) => Cuenta.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ADMIN / OPERADOR
  static Future<dynamic> crearCuenta(Cuenta cuenta) async {
    return ApiService.post('cuentas', cuenta.toJson());
  }

  // CLIENTE
  static Future<dynamic> crearMiCuenta(Cuenta cuenta) async {
    return ApiService.post('cuentas/mis-cuentas', {
      'numeroCuenta': cuenta.numero,
      'saldo': cuenta.saldo,
      'bancoId': cuenta.bancoId,
    });
  }

  // ADMIN / OPERADOR
  static Future<dynamic> eliminarCuenta(int id) async {
    return ApiService.delete('cuentas/$id');
  }
}
