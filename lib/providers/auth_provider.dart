import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool isLoading = false;
  String? error;
  String? nombreUsuario;

  Future<bool> checkLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.login(email, password);
      nombreUsuario = data['usuario']?['nombre'];
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String nombre, String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.register(nombre, email, password);
      nombreUsuario = data['usuario']?['nombre'];
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    nombreUsuario = null;
    notifyListeners();
  }
}
