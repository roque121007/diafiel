import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Excepción amigable que ya trae un mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  final String mensaje;
  ApiException(this.mensaje);
  @override
  String toString() => mensaje;
}

class ApiService {
  // Cambia esta URL si tu dominio de Railway cambia
  static const String baseUrl =
      'https://apitareas-production-4f16.up.railway.app';
  final _storage = const FlutterSecureStorage();
  static const _timeout = Duration(seconds: 12);

  Future<String?> getToken() async => _storage.read(key: 'jwt_token');
  Future<void> saveToken(String token) async =>
      _storage.write(key: 'jwt_token', value: token);
  Future<void> clearToken() async => _storage.delete(key: 'jwt_token');

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Convierte cualquier error técnico (de red, timeout, JSON inválido, etc.)
  /// en un mensaje amigable y consistente en español.
  Future<T> _ejecutar<T>(Future<T> Function() peticion) async {
    try {
      return await peticion().timeout(_timeout);
    } on SocketException {
      throw ApiException(
          'No hay conexión a internet. Revisa tu WiFi o datos móviles.');
    } on HttpException {
      throw ApiException(
          'No se pudo conectar con el servidor. Intenta más tarde.');
    } on FormatException {
      throw ApiException(
          'Respuesta inesperada del servidor. Intenta de nuevo.');
    } on http.ClientException {
      throw ApiException('No se pudo establecer conexión con el servidor.');
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(
            'El servidor tardó demasiado en responder. Intenta de nuevo.');
      }
      throw ApiException('Ocurrió un error inesperado. Intenta de nuevo.');
    }
  }

  String _mensajeDelServidor(Map<String, dynamic> data, String fallback) {
    return (data['mensaje'] as String?) ?? fallback;
  }

  // ---------- AUTH ----------
  Future<Map<String, dynamic>> register(
      String nombre, String email, String password) {
    return _ejecutar(() async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: await _headers(auth: false),
        body: jsonEncode(
            {'nombre': nombre, 'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        await saveToken(data['token']);
        return data;
      }
      throw ApiException(
          _mensajeDelServidor(data, 'No se pudo crear la cuenta.'));
    });
  }

  Future<Map<String, dynamic>> login(String email, String password) {
    return _ejecutar(() async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: await _headers(auth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await saveToken(data['token']);
        return data;
      }
      if (res.statusCode == 401) {
        throw ApiException('Correo o contraseña incorrectos.');
      }
      throw ApiException(
          _mensajeDelServidor(data, 'No se pudo iniciar sesión.'));
    });
  }

  // ---------- CATEGORIAS ----------
  Future<List<dynamic>> getCategorias() {
    return _ejecutar(() async {
      final res = await http.get(
        Uri.parse('$baseUrl/api/categorias'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw ApiException('No se pudieron cargar las categorías.');
    });
  }

  // ---------- TAREAS ----------
  Future<List<dynamic>> getTareas() {
    return _ejecutar(() async {
      final res = await http.get(
        Uri.parse('$baseUrl/api/tareas'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw ApiException('No se pudieron cargar tus tareas.');
    });
  }

  Future<Map<String, dynamic>> createTarea(Map<String, dynamic> tarea) {
    return _ejecutar(() async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/tareas'),
        headers: await _headers(),
        body: jsonEncode(tarea),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) return data;
      throw ApiException(
          _mensajeDelServidor(data, 'No se pudo crear la tarea.'));
    });
  }

  Future<void> updateTarea(int id, Map<String, dynamic> tarea) {
    return _ejecutar(() async {
      final res = await http.put(
        Uri.parse('$baseUrl/api/tareas/$id'),
        headers: await _headers(),
        body: jsonEncode(tarea),
      );
      if (res.statusCode != 200) {
        final data = jsonDecode(res.body);
        throw ApiException(
            _mensajeDelServidor(data, 'No se pudo actualizar la tarea.'));
      }
    });
  }

  Future<void> deleteTarea(int id) {
    return _ejecutar(() async {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/tareas/$id'),
        headers: await _headers(),
      );
      if (res.statusCode != 200) {
        final data = jsonDecode(res.body);
        throw ApiException(
            _mensajeDelServidor(data, 'No se pudo eliminar la tarea.'));
      }
    });
  }
}
