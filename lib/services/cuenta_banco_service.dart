import '../models/cuenta_banco.dart';
import '../utils/storage.dart';
import 'api_service.dart';

class CuentaBancoService {
  static Future<List<CuentaBanco>> getCuentasBanco() async {
    final rol = await Storage.obtenerRol();

    final endpoint = rol == 'CLIENTE'
        ? 'cuentas-banco/mis-cuentas-banco'
        : 'cuentas-banco';

    final data = await ApiService.get(endpoint);

    return (data as List)
        .map((json) => CuentaBanco.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<CuentaBanco> obtenerPorId(int id) async {
    final data = await ApiService.get('cuentas-banco/$id');

    return CuentaBanco.fromJson(data as Map<String, dynamic>);
  }

  // ADMIN / OPERADOR
  static Future<CuentaBanco> crear({
    required int cuentaId,
    required int bancoId,
  }) async {
    final data = await ApiService.post('cuentas-banco', {
      'cuentaId': cuentaId,
      'bancoId': bancoId,
    });

    return CuentaBanco.fromJson(data as Map<String, dynamic>);
  }

  // CLIENTE
  static Future<CuentaBanco> crearMiCuentaBanco({
    required int cuentaId,
    required int bancoId,
  }) async {
    final data = await ApiService.post('cuentas-banco/mis-cuentas-banco', {
      'cuentaId': cuentaId,
      'bancoId': bancoId,
    });

    return CuentaBanco.fromJson(data as Map<String, dynamic>);
  }

  // ADMIN / OPERADOR
  static Future<CuentaBanco> actualizarEstado({
    required int id,
    required String estado,
  }) async {
    final data = await ApiService.put('cuentas-banco/$id', {'estado': estado});

    return CuentaBanco.fromJson(data as Map<String, dynamic>);
  }

  // ADMIN / OPERADOR
  static Future<void> eliminar(int id) async {
    await ApiService.delete('cuentas-banco/$id');
  }
}
