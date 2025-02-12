import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app/core/config/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<bool> isAuthenticated() async {
    return await TokenStorage.hasToken();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://deepskyblue-loris-536950.hostingersite.com/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        _token = data['token'];
        _user = data['user'];
        await TokenStorage.saveToken(_token!);
        _errorMessage = null;
      } else {
        _errorMessage = data['message'] ?? 'Login failed';
        await TokenStorage.clearToken();
      }
    } catch (e) {
      print(e);
      _errorMessage = 'Network error occurred';
      await TokenStorage.clearToken();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await TokenStorage.clearToken();
    notifyListeners();
  }
}