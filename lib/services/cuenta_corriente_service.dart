import '../models/cuenta_corriente.dart';
import '../utils/storage.dart';
import 'api_service.dart';

class CuentaCorrienteService {
  static Future<List<CuentaCorriente>> getCuentasCorrientes() async {
    final rol = await Storage.obtenerRol();

    final endpoint = rol == 'CLIENTE'
        ? 'cuentas-corrientes/mis-cuentas-corrientes'
        : 'cuentas-corrientes';

    final data = await ApiService.get(endpoint);

    return (data as List)
        .map((json) => CuentaCorriente.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ADMIN / OPERADOR
  static Future<dynamic> crearCuentaCorriente(CuentaCorriente cuenta) async {
    return ApiService.post('cuentas-corrientes', cuenta.toCrearJson());
  }

  // CLIENTE
  static Future<dynamic> crearMiCuentaCorriente(CuentaCorriente cuenta) async {
    return ApiService.post(
      'cuentas-corrientes/mis-cuentas-corrientes',
      cuenta.toCrearJson(),
    );
  }

  // ADMIN / OPERADOR
  static Future<dynamic> eliminarCuentaCorriente(int id) async {
    return ApiService.delete('cuentas-corrientes/$id');
  }
}
