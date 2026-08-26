import '../models/banco.dart';
import 'api_service.dart';

class BancoService {

  static Future<List<Banco>> getBancos() async {
    final data = await ApiService.get("bancos");

    return (data as List)
        .map((e) => Banco.fromJson(e))
        .toList();
  }

  static Future crearBanco(Banco banco) async {
    return await ApiService.post("bancos", banco.toJson());
  }

  static Future eliminarBanco(int id) async {
    return await ApiService.delete("bancos/$id");
  }
}