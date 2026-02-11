import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator
  static final String baseUrl = Platform.isAndroid
      ? 'https://68a8-136-158-120-71.ngrok-free.app/api'
      : 'http://localhost:8000/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['access_token']);
      return data['user'];
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  static Future<dynamic> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['access_token']);
      return data['user'];
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  static Future<void> logout() async {
    final headers = await getHeaders();
    await http.post(Uri.parse('$baseUrl/logout'), headers: headers);
    await removeToken();
  }

  // Generic GET request
  static Future<dynamic> get(String endpoint) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // Generic POST request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to post data: ${response.body}');
    }
  }
}
