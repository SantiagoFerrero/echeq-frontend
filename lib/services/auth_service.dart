import '../utils/storage.dart';
import 'api_service.dart';

class AuthService {
  Future<String?> login(String email, String password) async {
    try {
      final data = await ApiService.postPublic('auth/login', {
        'email': email.trim(),
        'password': password,
      });

      if (data is! Map<String, dynamic>) {
        return null;
      }

      final token = data['token']?.toString();

      final usuarioIdRaw = data['usuarioId'];
      final nombre = data['nombre']?.toString();
      final apellido = data['apellido']?.toString();
      final emailRespuesta = data['email']?.toString();
      final rol = data['rol']?.toString();

      if (token == null ||
          token.isEmpty ||
          usuarioIdRaw == null ||
          nombre == null ||
          apellido == null ||
          emailRespuesta == null ||
          rol == null) {
        return null;
      }

      final usuarioId = usuarioIdRaw is int
          ? usuarioIdRaw
          : int.tryParse(usuarioIdRaw.toString());

      if (usuarioId == null) {
        return null;
      }

      await Storage.guardarSesion(
        token: token,
        usuarioId: usuarioId,
        nombre: nombre,
        apellido: apellido,
        email: emailRespuesta,
        rol: rol,
      );

      return token;
    } catch (_) {
      return null;
    }
  }

  Future<void> registrar({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    await ApiService.postPublic('auth/registro', {
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });
  }

  Future<String?> getToken() {
    return Storage.obtenerToken();
  }

  Future<String?> getRol() {
    return Storage.obtenerRol();
  }

  Future<int?> getUsuarioId() {
    return Storage.obtenerUsuarioId();
  }

  Future<String?> getNombre() {
    return Storage.obtenerNombre();
  }

  Future<String?> getApellido() {
    return Storage.obtenerApellido();
  }

  Future<String?> getEmail() {
    return Storage.obtenerEmail();
  }

  Future<bool> haySesion() {
    return Storage.haySesion();
  }

  Future<void> logout() {
    return Storage.limpiarSesion();
  }
}
