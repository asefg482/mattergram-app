import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/team.dart';
import '../models/channel.dart';
import '../models/post.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? errorId;
  final String? detailedError;

  ApiException(this.message, {this.statusCode = 0, this.errorId, this.detailedError});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = '';
  String? _token;
  StorageService? _storage;

  String get baseUrl => _baseUrl;
  String? get token => _token;

  Future<void> init(StorageService storage) async {
    _storage = storage;
    _token = storage.getToken();
    _baseUrl = storage.getBaseUrl() ?? '';
  }

  void setBaseUrl(String url) {
    _baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    _storage?.setBaseUrl(_baseUrl);
  }

  void setToken(String? token) {
    _token = token;
    _storage?.setToken(token);
  }

  Map<String, String> _getHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Mattermost-Server': _baseUrl,
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  String _resolveUrl(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    if (_baseUrl.isEmpty) {
      throw ApiException('Mattermost server URL is not configured.');
    }
    return '$_baseUrl$cleanEndpoint';
  }

  Future<dynamic> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(_resolveUrl(endpoint));
    final reqHeaders = _getHeaders(headers);

    http.Response res;
    switch (method.toUpperCase()) {
      case 'POST':
        res = await http.post(uri, headers: reqHeaders, body: body != null ? jsonEncode(body) : null);
        break;
      case 'PUT':
        res = await http.put(uri, headers: reqHeaders, body: body != null ? jsonEncode(body) : null);
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: reqHeaders, body: body != null ? jsonEncode(body) : null);
        break;
      case 'GET':
      default:
        res = await http.get(uri, headers: reqHeaders);
        break;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.statusCode == 204 || res.body.isEmpty) {
        return {};
      }
      return jsonDecode(utf8.decode(res.bodyBytes));
    }

    String errorMsg = 'API Error ${res.statusCode}: ${res.reasonPhrase}';
    String? errId;
    String? detailed;
    try {
      final errJson = jsonDecode(utf8.decode(res.bodyBytes));
      if (errJson is Map) {
        errorMsg = errJson['message'] ?? errJson['detailed_error'] ?? errorMsg;
        errId = errJson['id'];
        detailed = errJson['detailed_error'];
      }
    } catch (_) {}

    throw ApiException(errorMsg, statusCode: res.statusCode, errorId: errId, detailedError: detailed);
  }

  // --- Auth ---
  Future<({MattermostUser user, String token})> login(String loginId, String password) async {
    final uri = Uri.parse(_resolveUrl('/api/v4/users/login'));
    final headers = {'Content-Type': 'application/json', 'X-Mattermost-Server': _baseUrl};
    final body = jsonEncode({'login_id': loginId, 'password': password});

    final res = await http.post(uri, headers: headers, body: body);
    if (res.statusCode != 200) {
      String errText = 'Login failed (${res.statusCode})';
      try {
        final errJson = jsonDecode(utf8.decode(res.bodyBytes));
        errText = errJson['message'] ?? errJson['detailed_error'] ?? errText;
      } catch (_) {}
      throw ApiException(errText, statusCode: res.statusCode);
    }

    final token = res.headers['token'] ?? res.headers['Token'];
    if (token == null || token.isEmpty) {
      throw ApiException('Authentication token not received in response headers');
    }

    final userJson = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final user = MattermostUser.fromJson(userJson);
    setToken(token);
    return (user: user, token: token);
  }

  Future<MattermostUser> register(Map<String, dynamic> payload) async {
    final data = await request('/api/v4/users', method: 'POST', body: payload);
    return MattermostUser.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await request('/api/v4/users/logout', method: 'POST');
    } catch (_) {}
    setToken(null);
  }

  Future<MattermostUser> getMe() async {
    final data = await request('/api/v4/users/me');
    return MattermostUser.fromJson(data);
  }

  // --- Teams ---
  Future<List<MattermostTeam>> getMyTeams() async {
    final data = await request('/api/v4/users/me/teams');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((t) => MattermostTeam.fromJson(t)).toList();
    }
    return [];
  }

  Future<List<MattermostTeam>> getOpenTeams() async {
    final data = await request('/api/v4/teams');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((t) => MattermostTeam.fromJson(t)).toList();
    }
    return [];
  }

  Future<void> addUserToTeam(String teamId, String userId) async {
    await request('/api/v4/teams/$teamId/members', method: 'POST', body: {
      'team_id': teamId,
      'user_id': userId,
    });
  }

  // --- Channels ---
  Future<List<MattermostChannel>> getMyChannels(String teamId) async {
    final data = await request('/api/v4/users/me/teams/$teamId/channels');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((c) => MattermostChannel.fromJson(c)).toList();
    }
    return [];
  }

  Future<MattermostChannel> getChannel(String channelId) async {
    final data = await request('/api/v4/channels/$channelId');
    return MattermostChannel.fromJson(data);
  }

  Future<MattermostChannel> createChannel(
    String teamId,
    String name,
    String displayName, {
    String type = 'O',
    String purpose = '',
  }) async {
    final cleanName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '-');
    final data = await request('/api/v4/channels', method: 'POST', body: {
      'team_id': teamId,
      'name': cleanName,
      'display_name': displayName,
      'purpose': purpose,
      'type': type,
    });
    return MattermostChannel.fromJson(data);
  }

  Future<MattermostChannel> createDirectChannel(String userId1, String userId2) async {
    final uri = Uri.parse(_resolveUrl('/api/v4/channels/direct'));
    final headers = _getHeaders();
    final res = await http.post(uri, headers: headers, body: jsonEncode([userId1, userId2]));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return MattermostChannel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    throw ApiException('Failed to create direct channel: ${res.statusCode}');
  }

  Future<void> deleteChannel(String channelId) async {
    await request('/api/v4/channels/$channelId', method: 'DELETE');
  }

  Future<MattermostChannel> patchChannel(String channelId, Map<String, dynamic> patch) async {
    final data = await request('/api/v4/channels/$channelId/patch', method: 'PUT', body: patch);
    return MattermostChannel.fromJson(data);
  }

  Future<List<MattermostChannel>> searchChannels(String teamId, String term) async {
    final data = await request('/api/v4/teams/$teamId/channels/search', method: 'POST', body: {'term': term});
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((c) => MattermostChannel.fromJson(c)).toList();
    }
    return [];
  }

  Future<void> addChannelMember(String channelId, String userId) async {
    await request('/api/v4/channels/$channelId/members', method: 'POST', body: {'user_id': userId});
  }

  Future<void> removeChannelMember(String channelId, String userId) async {
    await request('/api/v4/channels/$channelId/members/$userId', method: 'DELETE');
  }

  Future<List<MattermostChannelMember>> getChannelMembers(String channelId, {int page = 0, int perPage = 100}) async {
    final data = await request('/api/v4/channels/$channelId/members?page=$page&per_page=$perPage');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((m) => MattermostChannelMember.fromJson(m)).toList();
    }
    return [];
  }

  Future<List<MattermostChannelMember>> getMyChannelMembers(String teamId) async {
    final data = await request('/api/v4/users/me/teams/$teamId/channels/members');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((m) => MattermostChannelMember.fromJson(m)).toList();
    }
    return [];
  }

  Future<void> viewChannel(String channelId, {String prevChannelId = ''}) async {
    try {
      await request('/api/v4/channels/members/me/view', method: 'POST', body: {
        'channel_id': channelId,
        'prev_channel_id': prevChannelId,
      });
    } catch (_) {}
  }

  Future<List<MattermostUser>> getTeamUsers(String teamId, {int page = 0, int perPage = 60}) async {
    final data = await request('/api/v4/users?in_team=$teamId&page=$page&per_page=$perPage');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((u) => MattermostUser.fromJson(u)).toList();
    }
    return [];
  }

  Future<List<MattermostUser>> getUsersNotInChannel(String channelId, {String? teamId, int page = 0, int perPage = 60}) async {
    var endpoint = '/api/v4/users?not_in_channel=$channelId&page=$page&per_page=$perPage';
    if (teamId != null && teamId.isNotEmpty) {
      endpoint += '&in_team=$teamId';
    }
    final data = await request(endpoint);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((u) => MattermostUser.fromJson(u)).toList();
    }
    return [];
  }

  Future<void> setChannelMemberAdmin(String channelId, String userId, bool isAdmin) async {
    try {
      await request('/api/v4/channels/$channelId/members/$userId/schemeRoles', method: 'PUT', body: {
        'scheme_user': true,
        'scheme_admin': isAdmin,
      });
    } catch (_) {
      final roles = isAdmin ? 'channel_user channel_admin' : 'channel_user';
      await request('/api/v4/channels/$channelId/members/$userId/roles', method: 'PUT', body: {
        'roles': roles,
      });
    }
  }

  // --- Posts ---
  Future<ChannelPostsResponse> getPosts(String channelId, {int page = 0, int perPage = 60, String before = ''}) async {
    var endpoint = '/api/v4/channels/$channelId/posts?per_page=$perPage';
    if (before.isNotEmpty) {
      endpoint += '&before=$before';
    } else {
      endpoint += '&page=$page';
    }
    final data = await request(endpoint);
    return ChannelPostsResponse.fromJson(data);
  }

  Future<MattermostPost> getPost(String postId) async {
    final data = await request('/api/v4/posts/$postId');
    return MattermostPost.fromJson(data);
  }

  Future<ChannelPostsResponse> getPostsAround(String channelId, String postId, {int perPage = 60}) async {
    final data = await request('/api/v4/channels/$channelId/posts?around=$postId&per_page=$perPage');
    return ChannelPostsResponse.fromJson(data);
  }

  Future<ChannelPostsResponse> getPostThread(String postId) async {
    final data = await request('/api/v4/posts/$postId/thread');
    return ChannelPostsResponse.fromJson(data);
  }

  Future<MattermostPost> createPost(
    String channelId,
    String message, {
    String rootId = '',
    List<String> fileIds = const [],
    Map<String, dynamic> props = const {},
  }) async {
    final payload = <String, dynamic>{
      'channel_id': channelId,
      'message': message,
      'root_id': rootId,
      'file_ids': fileIds,
    };
    if (props.isNotEmpty) {
      payload['props'] = props;
    }
    final data = await request('/api/v4/posts', method: 'POST', body: payload);
    return MattermostPost.fromJson(data);
  }

  Future<MattermostPost> editPost(String postId, String message) async {
    final data = await request('/api/v4/posts/$postId/patch', method: 'PUT', body: {'message': message});
    return MattermostPost.fromJson(data);
  }

  Future<void> deletePost(String postId) async {
    await request('/api/v4/posts/$postId', method: 'DELETE');
  }

  Future<void> pinPost(String postId) async {
    await request('/api/v4/posts/$postId/pin', method: 'POST');
  }

  Future<void> unpinPost(String postId) async {
    await request('/api/v4/posts/$postId/unpin', method: 'POST');
  }

  Future<ChannelPostsResponse> searchTeamPosts(String teamId, String terms, {bool isOrSearch = false}) async {
    final data = await request('/api/v4/teams/$teamId/posts/search', method: 'POST', body: {
      'terms': terms,
      'is_or_search': isOrSearch,
    });
    return ChannelPostsResponse.fromJson(data);
  }

  Future<ChannelPostsResponse> getFlaggedPosts(String userId, {int page = 0, int perPage = 60}) async {
    final data = await request('/api/v4/users/$userId/posts/flagged?page=$page&per_page=$perPage');
    return ChannelPostsResponse.fromJson(data);
  }

  // --- Reactions ---
  Future<void> addReaction(String userId, String postId, String emojiName) async {
    await request('/api/v4/reactions', method: 'POST', body: {
      'user_id': userId,
      'post_id': postId,
      'emoji_name': emojiName,
    });
  }

  Future<void> removeReaction(String userId, String postId, String emojiName) async {
    final cleanEmoji = Uri.encodeComponent(emojiName);
    await request('/api/v4/users/$userId/posts/$postId/reactions/$cleanEmoji', method: 'DELETE');
  }

  Future<List<MattermostReaction>> getPostReactions(String postId) async {
    final data = await request('/api/v4/posts/$postId/reactions');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((r) => MattermostReaction.fromJson(r)).toList();
    }
    return [];
  }

  // --- Users & Statuses ---
  Future<MattermostUser> getUser(String userId) async {
    final data = await request('/api/v4/users/$userId');
    return MattermostUser.fromJson(data);
  }

  Future<MattermostUser> getUserByUsername(String username) async {
    final data = await request('/api/v4/users/username/${Uri.encodeComponent(username)}');
    return MattermostUser.fromJson(data);
  }

  Future<List<MattermostUser>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final uri = Uri.parse(_resolveUrl('/api/v4/users/ids'));
    final headers = _getHeaders();
    final res = await http.post(uri, headers: headers, body: jsonEncode(userIds));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(utf8.decode(res.bodyBytes));
      if (list is List) {
        return list.whereType<Map<String, dynamic>>().map((u) => MattermostUser.fromJson(u)).toList();
      }
    }
    return [];
  }

  Future<List<MattermostUser>> searchUsers(String term, {String? teamId, String? notInChannelId}) async {
    final payload = <String, dynamic>{'term': term};
    if (teamId != null && teamId.isNotEmpty) payload['team_id'] = teamId;
    if (notInChannelId != null && notInChannelId.isNotEmpty) payload['not_in_channel_id'] = notInChannelId;

    final data = await request('/api/v4/users/search', method: 'POST', body: payload);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((u) => MattermostUser.fromJson(u)).toList();
    }
    return [];
  }

  Future<List<UserStatus>> getUsersStatuses(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final uri = Uri.parse(_resolveUrl('/api/v4/users/status/ids'));
    final headers = _getHeaders();
    final res = await http.post(uri, headers: headers, body: jsonEncode(userIds));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(utf8.decode(res.bodyBytes));
      if (list is List) {
        return list.whereType<Map<String, dynamic>>().map((s) => UserStatus.fromJson(s)).toList();
      }
    }
    return [];
  }

  Future<UserStatus> getUserStatus(String userId) async {
    final data = await request('/api/v4/users/$userId/status');
    return UserStatus.fromJson(data);
  }

  Future<UserStatus> updateUserCustomStatus(String userId, String status) async {
    final data = await request('/api/v4/users/$userId/status', method: 'PUT', body: {
      'user_id': userId,
      'status': status,
    });
    return UserStatus.fromJson(data);
  }

  Future<MattermostUser> patchUser(String userId, Map<String, dynamic> patch) async {
    final data = await request('/api/v4/users/$userId/patch', method: 'PUT', body: patch);
    return MattermostUser.fromJson(data);
  }

  Future<void> updateUserPassword(String userId, String currentPassword, String newPassword) async {
    await request('/api/v4/users/$userId/password', method: 'PUT', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<void> deleteProfileImage(String userId) async {
    await request('/api/v4/users/$userId/image', method: 'DELETE');
  }

  Future<void> uploadProfileImage(String userId, List<int> bytes, String filename) async {
    final uri = Uri.parse(_resolveUrl('/api/v4/users/$userId/image'));
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_getHeaders());
    req.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('Failed to upload profile image: ${res.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getMyPreferences() async {
    final data = await request('/api/v4/users/me/preferences');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  // --- Files ---
  Future<MattermostFileInfo> uploadFile(String channelId, List<int> bytes, String filename) async {
    final uri = Uri.parse(_resolveUrl('/api/v4/files'));
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_getHeaders());
    req.fields['channel_id'] = channelId;
    req.files.add(http.MultipartFile.fromBytes('files', bytes, filename: filename));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('Failed to upload file: ${res.statusCode}');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final fileInfos = data['file_infos'] as List;
    return MattermostFileInfo.fromJson(fileInfos[0] as Map<String, dynamic>);
  }

  Future<MattermostFileInfo> getFileInfo(String fileId) async {
    final data = await request('/api/v4/files/$fileId/info');
    return MattermostFileInfo.fromJson(data);
  }

  String getFileDownloadUrl(String fileId) => '$_baseUrl/api/v4/files/$fileId';
  String getFilePreviewUrl(String fileId) => '$_baseUrl/api/v4/files/$fileId/preview';
  String getFileThumbnailUrl(String fileId) => '$_baseUrl/api/v4/files/$fileId/thumbnail';

  String getUserAvatarUrl(String userId, [int? lastPictureUpdate]) {
    final qs = lastPictureUpdate != null ? '?_=$lastPictureUpdate' : '';
    return '$_baseUrl/api/v4/users/$userId/image$qs';
  }

  // --- Server Diagnostics ---
  Future<bool> pingServer([String? testUrl]) async {
    final target = (testUrl ?? _baseUrl).trim().replaceAll(RegExp(r'/+$'), '');
    if (target.isEmpty) return false;
    try {
      final res = await http.get(Uri.parse('$target/api/v4/system/ping')).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getClientConfig([String? targetUrl]) async {
    final target = (targetUrl ?? _baseUrl).trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$target/api/v4/config/client?format=old');
    final res = await http.get(uri).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    return {};
  }
}
