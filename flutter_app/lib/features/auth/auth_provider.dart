import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import 'auth_repository.dart';
import 'user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  final ApiClient _api;
  AuthProvider(this._repo, this._api);

  User? user;
  String? token;
  bool initializing = true;
  bool busy = false;
  String? error;

  bool get isLoggedIn => token != null;

  Future<void> init() async {
    final s = await _repo.restore();
    if (s != null) _apply(s);
    initializing = false;
    notifyListeners();
  }

  Future<void> login(String u, String p) => _run(() => _repo.login(u, p));
  Future<void> register(String u, String p) => _run(() => _repo.register(u, p));
  Future<void> updateDisplayName(String name) =>
      _run(() => _repo.updateDisplayName(name));
  Future<void> updateAvatar(List<int> bytes, String filename) =>
      _run(() => _repo.updateAvatar(bytes, filename));
  Future<void> updateBio(String bio) => _run(() => _repo.updateBio(bio));

  Future<void> _run(Future<AuthSession> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      _apply(await action());
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not reach the server';
    }
    busy = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.clear();
    user = null;
    token = null;
    _api.token = null;
    notifyListeners();
  }

  void _apply(AuthSession s) {
    user = s.user;
    token = s.token;
    _api.token = s.token;
  }
}
