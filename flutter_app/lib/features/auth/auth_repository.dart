import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import 'user.dart';

class AuthSession {
  final User user;
  final String token;
  final String refreshToken;
  AuthSession(this.user, this.token, this.refreshToken);
}

class ActiveSession {
  final String id;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final DateTime expiresAt;
  final String? userAgent;
  final bool current;

  ActiveSession.fromJson(Map<String, dynamic> json)
      : id = json['id'].toString(),
        createdAt = DateTime.parse(json['createdAt'].toString()).toLocal(),
        lastUsedAt = DateTime.parse(json['lastUsedAt'].toString()).toLocal(),
        expiresAt = DateTime.parse(json['expiresAt'].toString()).toLocal(),
        userAgent = json['userAgent']?.toString(),
        current = json['current'] == true;
}

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  AuthSession _fromData(Map<String, dynamic> data, {AuthSession? previous}) {
    return AuthSession(
      User.fromJson(data['user']),
      data['accessToken']?.toString() ?? data['token']?.toString() ?? previous!.token,
      data['refreshToken']?.toString() ?? previous!.refreshToken,
    );
  }

  Future<AuthSession> login(String username, String password) =>
      _auth('/auth/login', username, password);

  Future<AuthSession> register(String username, String password) =>
      _auth('/auth/register', username, password);

  Future<AuthSession> updateDisplayName(String displayName) async {
    final data = await api.patch('/auth/me', {'displayName': displayName});
    final session = _fromData(data, previous: await restore());
    await _save(session);
    return session;
  }

  Future<AuthSession> updateAvatar(List<int> bytes, String filename) async {
    final data = await api.upload('/auth/me/avatar', 'avatar', bytes, filename);
    final session = _fromData(data, previous: await restore());
    await _save(session);
    return session;
  }

  Future<AuthSession> updateBio(String bio) async {
    final data = await api.patch('/auth/me/bio', {'bio': bio});
    final session = _fromData(data, previous: await restore());
    await _save(session);
    return session;
  }

  Future<AuthSession> changePassword(
      String currentPassword, String newPassword) async {
    final data = await api.patch('/auth/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    final session = _fromData(data, previous: await restore());
    await _save(session);
    return session;
  }

  Future<void> logout() => api.post('/auth/logout', {});

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final session = await restore();
    if (session != null) {
      await _save(AuthSession(session.user, accessToken, refreshToken));
    }
  }

  Future<List<ActiveSession>> sessions() async =>
      (await api.get('/auth/sessions') as List)
          .map((item) => ActiveSession.fromJson(item))
          .toList();

  Future<void> revokeSession(String id) async =>
      api.delete('/auth/sessions/$id');

  Future<void> logoutAll() async => api.post('/auth/logout-all', {});

  Future<AuthSession> _auth(
      String path, String username, String password) async {
    final data =
        await api.post(path, {'username': username, 'password': password});
    final session = _fromData(data);
    await _save(session);
    return session;
  }

  Future<void> _save(AuthSession s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'session', jsonEncode({
          'user': s.user.toJson(),
          'token': s.token,
          'refreshToken': s.refreshToken,
        }));
  }

  Future<AuthSession?> restore() async {
    final raw = (await SharedPreferences.getInstance()).getString('session');
    if (raw == null) return null;
    final j = jsonDecode(raw);
    final refresh = j['refreshToken']?.toString();
    if (refresh == null || refresh.isEmpty) return null;
    return AuthSession(User.fromJson(j['user']), j['token'], refresh);
  }

  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove('session');
}
