import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import 'user.dart';

class AuthSession {
  final User user;
  final String token;
  AuthSession(this.user, this.token);
}

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  Future<AuthSession> login(String username, String password) =>
      _auth('/auth/login', username, password);

  Future<AuthSession> register(String username, String password) =>
      _auth('/auth/register', username, password);

  Future<AuthSession> _auth(String path, String username, String password) async {
    final data = await api.post(path, {'username': username, 'password': password});
    final session = AuthSession(User.fromJson(data['user']), data['token']);
    await _save(session);
    return session;
  }

  Future<void> _save(AuthSession s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session', jsonEncode({'user': s.user.toJson(), 'token': s.token}));
  }

  Future<AuthSession?> restore() async {
    final raw = (await SharedPreferences.getInstance()).getString('session');
    if (raw == null) return null;
    final j = jsonDecode(raw);
    return AuthSession(User.fromJson(j['user']), j['token']);
  }

  Future<void> clear() async => (await SharedPreferences.getInstance()).remove('session');
}
