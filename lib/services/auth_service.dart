import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class AuthUser {
  final String token;
  final String username;
  final String role;

  AuthUser({
    required this.token,
    required this.username,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      token: json['token']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';
  static const String _roleKey = 'auth_role';

  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim().toLowerCase(),
        'password': password,
      }),
    );

    return _handleAuthResponse(res);
  }

  Future<AuthUser> register({
    required String username,
    required String password,
    required String role,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim().toLowerCase(),
        'password': password,
        'role': role,
      }),
    );

    return _handleAuthResponse(res);
  }

  Future<AuthUser> _handleAuthResponse(http.Response res) async {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Respuesta de autenticación no válida.');
      }

      final user = AuthUser.fromJson(decoded);

      if (user.token.isEmpty) {
        throw Exception('La API no devolvió token.');
      }

      await saveSession(user);

      return user;
    }

    String message = 'No se pudo iniciar sesión.';

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            message;
      }
    } catch (_) {
      if (res.body.trim().isNotEmpty) {
        message = res.body;
      }
    }

    throw Exception(message);
  }

  Future<void> saveSession(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, user.token);
    await prefs.setString(_usernameKey, user.username);
    await prefs.setString(_roleKey, user.role);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
  }
}