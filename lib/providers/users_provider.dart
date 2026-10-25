import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';

class UsersProvider with ChangeNotifier {
  final Map<String, MattermostUser> _users = {};
  final Map<String, UserStatus> _statuses = {};
  final Set<String> _pendingIds = {};

  void initWs() {
    WsService().on('status_change', (event) {
      final data = event.data;
      if (data != null) {
        final userId = data['user_id'] as String?;
        final status = data['status'] as String?;
        if (userId != null && status != null) {
          _statuses[userId] = UserStatus(userId: userId, status: status);
          notifyListeners();
        }
      }
    });
  }

  Map<String, MattermostUser> get users => _users;
  Map<String, UserStatus> get statuses => _statuses;

  MattermostUser? getUser(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    return _users[userId];
  }

  UserStatus? getUserStatus(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    return _statuses[userId];
  }

  bool isUserOnline(String? userId) {
    final s = getUserStatus(userId);
    return s?.status == 'online';
  }

  void setUser(MattermostUser user) {
    _users[user.id] = user;
    notifyListeners();
  }

  void setStatus(UserStatus status) {
    _statuses[status.userId] = status;
    notifyListeners();
  }

  String getUserDisplayName(dynamic userOrId) {
    if (userOrId == null) return 'Unknown';
    if (userOrId is MattermostUser) {
      return userOrId.displayName;
    }
    if (userOrId is String) {
      final u = _users[userOrId];
      if (u != null) return u.displayName;
      return userOrId;
    }
    return 'Unknown';
  }

  Future<void> fetchUsers(List<String> userIds) async {
    final toFetch = userIds
        .where((id) => id.isNotEmpty && !_users.containsKey(id) && !_pendingIds.contains(id))
        .toSet()
        .toList();

    if (toFetch.isEmpty) return;

    _pendingIds.addAll(toFetch);

    try {
      final fetched = await ApiService().getUsersByIds(toFetch);
      for (final u in fetched) {
        _users[u.id] = u;
      }

      // Fetch statuses concurrently
      try {
        final fetchedStatuses = await ApiService().getUsersStatuses(toFetch);
        for (final s in fetchedStatuses) {
          _statuses[s.userId] = s;
        }
      } catch (_) {}

      notifyListeners();
    } catch (_) {
    } finally {
      _pendingIds.removeAll(toFetch);
    }
  }

  Future<List<MattermostUser>> searchUsers(String term, [String? teamId]) async {
    try {
      final results = await ApiService().searchUsers(term, teamId: teamId);
      for (final u in results) {
        _users[u.id] = u;
      }
      notifyListeners();
      return results;
    } catch (_) {
      return [];
    }
  }
}
