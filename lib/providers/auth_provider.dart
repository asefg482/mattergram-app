import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/team.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';
import 'users_provider.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final WsService _ws = WsService();
  UsersProvider? _usersProvider;

  MattermostUser? _currentUser;
  String? _token;
  String _baseUrl = '';
  List<MattermostTeam> _teams = [];
  MattermostTeam? _currentTeam;
  bool _isLoading = false;
  bool _isLoggingOut = false;
  String? _error;

  MattermostUser? get currentUser => _currentUser;
  String? get token => _token;
  String get baseUrl => _baseUrl;
  List<MattermostTeam> get teams => _teams;
  MattermostTeam? get currentTeam => _currentTeam;
  bool get isLoading => _isLoading;
  bool get isLoggingOut => _isLoggingOut;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty && _currentUser != null;

  void updateDependencies(UsersProvider users) {
    _usersProvider = users;
    _token = _api.token;
    _baseUrl = _api.baseUrl;
  }

  void setBaseUrl(String url) {
    _baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    _api.setBaseUrl(_baseUrl);
    notifyListeners();
  }

  Future<void> initAuth() async {
    _token = _api.token;
    _baseUrl = _api.baseUrl;

    if (_token == null || _token!.isEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _api.getMe();
      _currentUser = user;
      _usersProvider?.setUser(user);

      await loadTeams();
      _ws.connect(_token);
    } catch (e) {
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String loginId, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.login(loginId, password);
      _currentUser = res.user;
      _token = res.token;
      _usersProvider?.setUser(res.user);

      await loadTeams();
      _ws.connect(res.token);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MattermostUser> register(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _api.register(payload);
      final loginId = payload['username'] ?? payload['email'];
      final password = payload['password'];
      await login(loginId, password);
      return user;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTeams() async {
    try {
      var myTeams = await _api.getMyTeams();
      if (myTeams.isEmpty && _currentUser != null) {
        try {
          final openTeams = await _api.getOpenTeams();
          if (openTeams.isNotEmpty) {
            await _api.addUserToTeam(openTeams[0].id, _currentUser!.id);
            myTeams = await _api.getMyTeams();
          }
        } catch (_) {}
      }
      _teams = myTeams;
      if (_teams.isNotEmpty && _currentTeam == null) {
        _currentTeam = _teams[0];
      }
      notifyListeners();
    } catch (_) {}
  }

  void selectTeam(MattermostTeam team) {
    _currentTeam = team;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggingOut = true;
    notifyListeners();

    try {
      await _api.logout();
    } catch (_) {}

    _ws.disconnect();
    _currentUser = null;
    _token = null;
    _teams = [];
    _currentTeam = null;
    _isLoggingOut = false;
    notifyListeners();
  }

  Future<MattermostUser?> refreshCurrentUser() async {
    if (_token == null) return null;
    try {
      final user = await _api.getMe();
      _currentUser = user;
      _usersProvider?.setUser(user);
      notifyListeners();
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<MattermostUser?> updateCurrentUser(Map<String, dynamic> patch) async {
    if (_currentUser == null) return null;
    try {
      final updated = await _api.patchUser(_currentUser!.id, patch);
      _currentUser = updated;
      _usersProvider?.setUser(updated);
      notifyListeners();
      return updated;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateProfileImage(List<int> bytes, String filename) async {
    if (_currentUser == null) return;
    await _api.uploadProfileImage(_currentUser!.id, bytes, filename);
    final refreshed = await refreshCurrentUser();
    if (refreshed != null) {
      _currentUser = refreshed.copyWith(lastPictureUpdate: DateTime.now().millisecondsSinceEpoch);
      _usersProvider?.setUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> deleteProfileImage() async {
    if (_currentUser == null) return;
    await _api.deleteProfileImage(_currentUser!.id);
    final refreshed = await refreshCurrentUser();
    if (refreshed != null) {
      _currentUser = refreshed.copyWith(lastPictureUpdate: DateTime.now().millisecondsSinceEpoch);
      _usersProvider?.setUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return;
    await _api.updateUserPassword(_currentUser!.id, currentPassword, newPassword);
  }
}
