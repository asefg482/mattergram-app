import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../models/post.dart';
import '../models/ws_event.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';
import '../services/sound_service.dart';
import 'auth_provider.dart';
import 'users_provider.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final WsService _ws = WsService();
  final SoundService _sound = SoundService();

  AuthProvider? _auth;
  UsersProvider? _users;

  List<MattermostChannel> _channels = [];
  String? _activeChannelId;
  final Map<String, List<MattermostPost>> _posts = {};
  final Map<String, List<MattermostChannelMember>> _channelMembers = {};
  final Map<String, int> _unreadCounts = {};
  final Map<String, String?> _firstUnreadPostIds = {};
  final Map<String, int> _channelLastViewedAt = {};
  final Map<String, bool> _hasMoreOlderPosts = {};

  bool _loadingChannels = false;
  bool _loadingPosts = false;
  bool _loadingOlderPosts = false;

  // Active Thread / CRT View State
  MattermostPost? _activeThreadRootPost;
  List<MattermostPost> _threadPosts = [];
  bool _loadingThread = false;

  // Typing users: channelId -> (userId -> username)
  final Map<String, Map<String, String>> _typingUsers = {};
  final Map<String, Timer> _typingTimers = {};

  List<MattermostChannel> get channels => _channels;
  String? get activeChannelId => _activeChannelId;
  MattermostChannel? get activeChannel {
    if (_activeChannelId == null) return null;
    try {
      return _channels.firstWhere((c) => c.id == _activeChannelId);
    } catch (_) {
      return null;
    }
  }

  List<MattermostPost> get currentPosts {
    if (_activeChannelId == null) return [];
    return _posts[_activeChannelId] ?? [];
  }

  Map<String, int> get unreadCounts => _unreadCounts;
  Map<String, String?> get firstUnreadPostIds => _firstUnreadPostIds;
  Map<String, List<MattermostChannelMember>> get channelMembers => _channelMembers;

  bool get loadingChannels => _loadingChannels;
  bool get loadingPosts => _loadingPosts;
  bool get loadingOlderPosts => _loadingOlderPosts;

  MattermostPost? get activeThreadRootPost => _activeThreadRootPost;
  List<MattermostPost> get threadPosts => _threadPosts;
  bool get loadingThread => _loadingThread;

  int get unreadChatsCount => _channels.where((c) => (_unreadCounts[c.id] ?? 0) > 0).length;

  List<String> getTypingUsernames(String channelId) {
    return _typingUsers[channelId]?.values.toList() ?? [];
  }

  void updateDependencies(AuthProvider auth, UsersProvider users) {
    _auth = auth;
    _users = users;
  }

  void initWsListeners() {
    _ws.on('posted', _handleWsPosted);
    _ws.on('typing', _handleWsTyping);
    _ws.on('reaction_added', _handleWsReactionAdded);
    _ws.on('reaction_removed', _handleWsReactionRemoved);
    _ws.on('post_edited', _handleWsPostEdited);
    _ws.on('post_deleted', _handleWsPostDeleted);
    _ws.on('channel_viewed', _handleWsChannelViewed);
  }

  // --- Channels Loading ---
  Future<void> loadChannels() async {
    final team = _auth?.currentTeam;
    final myId = _auth?.currentUser?.id ?? '';
    if (team == null || team.id.isEmpty) return;

    _loadingChannels = true;
    notifyListeners();

    try {
      final rawChannels = await _api.getMyChannels(team.id);
      List<MattermostChannelMember> members = [];
      try {
        members = await _api.getMyChannelMembers(team.id);
      } catch (_) {}

      // Identify direct message users to fetch
      final dmUserIdsToFetch = <String>[];
      for (final ch in rawChannels) {
        if (ch.type == 'D') {
          final parts = ch.name.split('__');
          final otherId = parts[0] == myId ? (parts.length > 1 ? parts[1] : parts[0]) : parts[0];
          if (otherId.isNotEmpty) {
            dmUserIdsToFetch.add(otherId);
          }
        }
      }

      if (dmUserIdsToFetch.isNotEmpty) {
        await _users?.fetchUsers(dmUserIdsToFetch);
      }

      // Populate unread counts & last viewed timestamps
      for (final m in members) {
        _channelLastViewedAt[m.channelId] = m.lastViewedAt;
        final rawCh = rawChannels.firstWhere((c) => c.id == m.channelId, orElse: () => MattermostChannel(id: '', displayName: '', name: ''));
        if (rawCh.id.isNotEmpty) {
          final unread = rawCh.totalMsgCount - m.msgCount;
          if (unread > 0) {
            _unreadCounts[m.channelId] = unread;
          }
        }
      }

      // Enrich channels with DM users and format names
      final enriched = rawChannels.map((ch) {
        if (ch.type == 'D') {
          final parts = ch.name.split('__');
          final isSaved = parts[0] == myId && (parts.length > 1 ? parts[1] == myId : true);
          if (isSaved) {
            return ch.copyWith(
              displayName: 'Saved Messages',
              purpose: 'Your cloud storage',
            );
          }
          final otherId = parts[0] == myId ? (parts.length > 1 ? parts[1] : parts[0]) : parts[0];
          final otherUser = _users?.getUser(otherId);
          return ch.copyWith(
            dmUser: otherUser,
            displayName: otherUser != null ? _users!.getUserDisplayName(otherUser) : ch.displayName,
          );
        }
        return ch;
      }).toList();

      // Sort by pinned then latest post
      _sortChannelsList(enriched);
      _channels = enriched;

      // Concurrently fetch the latest post for top channels to display snippet & time
      _fetchLatestPostsForChannels();
    } catch (_) {
    } finally {
      _loadingChannels = false;
      notifyListeners();
    }
  }

  void updateChannelInList(MattermostChannel updated) {
    final idx = _channels.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _channels[idx] = updated;
      _sortChannelsList(_channels);
      notifyListeners();
    }
  }

  void _sortChannelsList(List<MattermostChannel> list) {
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      final timeA = a.lastPostAt > 0 ? a.lastPostAt : a.createAt;
      final timeB = b.lastPostAt > 0 ? b.lastPostAt : b.createAt;
      return timeB.compareTo(timeA);
    });
  }

  Future<void> _fetchLatestPostsForChannels() async {
    for (final ch in _channels.take(30)) {
      try {
        final pRes = await _api.getPosts(ch.id, page: 0, perPage: 1);
        if (pRes.order.isNotEmpty) {
          final lastId = pRes.order[0];
          final post = pRes.posts[lastId];
          if (post != null && post.deleteAt == 0) {
            ch.lastPost = post;
          }
        }
      } catch (_) {}
    }
    _sortChannelsList(_channels);
    notifyListeners();
  }

  // --- Channel Selection & Post Loading ---
  Future<void> selectChannel(String channelId) async {
    if (_activeChannelId == channelId) {
      return;
    }

    final prevChannelId = _activeChannelId ?? '';
    _activeChannelId = channelId;
    closeThread();

    // Mark as read locally and in Mattermost
    _unreadCounts[channelId] = 0;
    _firstUnreadPostIds[channelId] = null;
    notifyListeners();

    _api.viewChannel(channelId, prevChannelId: prevChannelId);
    fetchChannelMembers(channelId);

    if (!_posts.containsKey(channelId) || _posts[channelId]!.isEmpty) {
      _loadingPosts = true;
      notifyListeners();
      try {
        final res = await _api.getPosts(channelId, page: 0, perPage: 60);
        final list = res.order.map((id) => res.posts[id]).whereType<MattermostPost>().toList();
        // Reverse so index 0 is oldest and end is newest (Telegram chat flow)
        _posts[channelId] = list.reversed.toList();
        _hasMoreOlderPosts[channelId] = res.order.length >= 60;

        // Fetch authors info
        final authorIds = list.map((p) => p.userId).toSet().toList();
        _users?.fetchUsers(authorIds);
      } catch (_) {
      } finally {
        _loadingPosts = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadOlderPosts(String channelId) async {
    if (_loadingOlderPosts || (_hasMoreOlderPosts[channelId] == false)) return;
    final currentList = _posts[channelId] ?? [];
    if (currentList.isEmpty) return;

    _loadingOlderPosts = true;
    notifyListeners();

    try {
      final oldestPostId = currentList.first.id;
      final res = await _api.getPosts(channelId, perPage: 60, before: oldestPostId);
      final newPosts = res.order.map((id) => res.posts[id]).whereType<MattermostPost>().toList();

      if (newPosts.isEmpty) {
        _hasMoreOlderPosts[channelId] = false;
      } else {
        // Prepend older posts to the list
        _posts[channelId] = [...newPosts.reversed, ...currentList];
        _hasMoreOlderPosts[channelId] = newPosts.length >= 60;

        final authorIds = newPosts.map((p) => p.userId).toSet().toList();
        _users?.fetchUsers(authorIds);
      }
    } catch (_) {
    } finally {
      _loadingOlderPosts = false;
      notifyListeners();
    }
  }

  Future<void> fetchChannelMembers(String channelId) async {
    try {
      final members = await _api.getChannelMembers(channelId);
      _channelMembers[channelId] = members;
      final userIds = members.map((m) => m.userId).toList();
      _users?.fetchUsers(userIds);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> openDirectMessage(String userId) async {
    final myId = _auth?.currentUser?.id ?? '';
    if (myId.isEmpty) return;

    // Check if direct channel already exists in channels list
    for (final ch in _channels) {
      if (ch.type == 'D') {
        final parts = ch.name.split('__');
        if ((parts[0] == myId && parts.length > 1 && parts[1] == userId) ||
            (parts[0] == userId && parts.length > 1 && parts[1] == myId)) {
          await selectChannel(ch.id);
          return;
        }
      }
    }

    // Otherwise create direct channel
    try {
      final ch = await _api.createDirectChannel(myId, userId);
      final otherUser = _users?.getUser(userId);
      final enriched = ch.copyWith(
        dmUser: otherUser,
        displayName: otherUser != null ? _users!.getUserDisplayName(otherUser) : ch.displayName,
      );
      _channels.insert(0, enriched);
      await selectChannel(ch.id);
    } catch (_) {}
  }

  // --- Message Sending & Editing ---
  Future<void> sendMessage(
    String channelId,
    String message, {
    String rootId = '',
    List<String> fileIds = const [],
    Map<String, dynamic> props = const {},
  }) async {
    if (message.trim().isEmpty && fileIds.isEmpty) return;

    final myId = _auth?.currentUser?.id ?? '';
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempPost = MattermostPost(
      id: tempId,
      createAt: DateTime.now().millisecondsSinceEpoch,
      userId: myId,
      channelId: channelId,
      rootId: rootId,
      message: message,
      fileIds: fileIds,
      props: props,
    );

    // Optimistic insert
    if (rootId.isEmpty) {
      _posts[channelId] = [...(_posts[channelId] ?? []), tempPost];
    } else {
      _threadPosts = [..._threadPosts, tempPost];
    }
    notifyListeners();
    _sound.playSent();

    try {
      final created = await _api.createPost(
        channelId,
        message,
        rootId: rootId,
        fileIds: fileIds,
        props: props,
      );

      // Replace temp post with server created post
      if (rootId.isEmpty) {
        final list = _posts[channelId] ?? [];
        final idx = list.indexWhere((p) => p.id == tempId);
        if (idx != -1) {
          list[idx] = created;
        }
      } else {
        final idx = _threadPosts.indexWhere((p) => p.id == tempId);
        if (idx != -1) {
          _threadPosts[idx] = created;
        }
      }

      // Update channel last post
      final ch = activeChannel;
      if (ch != null && rootId.isEmpty) {
        ch.lastPost = created;
        _sortChannelsList(_channels);
      }

      notifyListeners();
    } catch (_) {
      // Remove temp post on failure
      if (rootId.isEmpty) {
        _posts[channelId]?.removeWhere((p) => p.id == tempId);
      } else {
        _threadPosts.removeWhere((p) => p.id == tempId);
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> editMessage(String postId, String newMessage) async {
    try {
      final updated = await _api.editPost(postId, newMessage);
      _updatePostInLists(updated);
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteMessage(String postId) async {
    try {
      await _api.deletePost(postId);
      _removePostFromLists(postId);
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  // --- Reactions ---
  Future<void> addReaction(String postId, String emojiName) async {
    final myId = _auth?.currentUser?.id ?? '';
    if (myId.isEmpty) return;
    try {
      await _api.addReaction(myId, postId, emojiName);
      final reaction = MattermostReaction(
        userId: myId,
        postId: postId,
        emojiName: emojiName,
        createAt: DateTime.now().millisecondsSinceEpoch,
      );
      _addReactionToPost(postId, reaction);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> removeReaction(String postId, String emojiName) async {
    final myId = _auth?.currentUser?.id ?? '';
    if (myId.isEmpty) return;
    try {
      await _api.removeReaction(myId, postId, emojiName);
      _removeReactionFromPost(postId, myId, emojiName);
      notifyListeners();
    } catch (_) {}
  }

  void _addReactionToPost(String postId, MattermostReaction reaction) {
    void update(List<MattermostPost> list) {
      final idx = list.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final post = list[idx];
        if (!post.reactions.any((r) => r.userId == reaction.userId && r.emojiName == reaction.emojiName)) {
          list[idx] = post.copyWith(reactions: [...post.reactions, reaction]);
        }
      }
    }

    for (final l in _posts.values) {
      update(l);
    }
    update(_threadPosts);
    if (_activeThreadRootPost?.id == postId) {
      _activeThreadRootPost = _activeThreadRootPost!.copyWith(
        reactions: [..._activeThreadRootPost!.reactions, reaction],
      );
    }
  }

  void _removeReactionFromPost(String postId, String userId, String emojiName) {
    void update(List<MattermostPost> list) {
      final idx = list.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final post = list[idx];
        list[idx] = post.copyWith(
          reactions: post.reactions.where((r) => !(r.userId == userId && r.emojiName == emojiName)).toList(),
        );
      }
    }

    for (final l in _posts.values) {
      update(l);
    }
    update(_threadPosts);
    if (_activeThreadRootPost?.id == postId) {
      _activeThreadRootPost = _activeThreadRootPost!.copyWith(
        reactions: _activeThreadRootPost!.reactions.where((r) => !(r.userId == userId && r.emojiName == emojiName)).toList(),
      );
    }
  }

  // --- Pins & Mute ---
  Future<void> togglePinPost(MattermostPost post) async {
    try {
      if (post.isPinned) {
        await _api.unpinPost(post.id);
        post.isPinned = false;
      } else {
        await _api.pinPost(post.id);
        post.isPinned = true;
      }
      notifyListeners();
    } catch (_) {}
  }

  void togglePinChannel(String channelId) {
    final idx = _channels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      _channels[idx].isPinned = !_channels[idx].isPinned;
      _sortChannelsList(_channels);
      notifyListeners();
    }
  }

  void toggleMuteChannel(String channelId) {
    final idx = _channels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      _channels[idx].isMuted = !_channels[idx].isMuted;
      notifyListeners();
    }
  }

  void toggleMarkAsUnread(String channelId) {
    if ((_unreadCounts[channelId] ?? 0) > 0) {
      _unreadCounts[channelId] = 0;
    } else {
      _unreadCounts[channelId] = 1;
    }
    notifyListeners();
  }

  // --- Threads (CRT) ---
  Future<void> openThread(MattermostPost rootPost) async {
    _activeThreadRootPost = rootPost;
    _loadingThread = true;
    _threadPosts = [];
    notifyListeners();

    try {
      final res = await _api.getPostThread(rootPost.id);
      final list = res.order
          .map((id) => res.posts[id])
          .whereType<MattermostPost>()
          .where((p) => p.id != rootPost.id)
          .toList();
      _threadPosts = list.reversed.toList();

      final authorIds = list.map((p) => p.userId).toSet().toList();
      _users?.fetchUsers(authorIds);
    } catch (_) {
    } finally {
      _loadingThread = false;
      notifyListeners();
    }
  }

  void closeThread() {
    _activeThreadRootPost = null;
    _threadPosts = [];
    notifyListeners();
  }

  // --- Channel Management ---
  Future<void> leaveChannel(String channelId) async {
    final myId = _auth?.currentUser?.id ?? '';
    await _api.removeChannelMember(channelId, myId);
    _channels.removeWhere((c) => c.id == channelId);
    if (_activeChannelId == channelId) {
      _activeChannelId = null;
    }
    notifyListeners();
  }

  bool canCurrentUserManageChannel(String channelId) {
    final user = _auth?.currentUser;
    if (user == null) return false;
    if (user.roles.contains('system_admin')) return true;

    final members = _channelMembers[channelId] ?? [];
    final myMember = members.firstWhere((m) => m.userId == user.id, orElse: () => MattermostChannelMember(channelId: '', userId: ''));
    if (myMember.schemeAdmin || myMember.roles.contains('channel_admin')) return true;

    final ch = _channels.firstWhere((c) => c.id == channelId, orElse: () => MattermostChannel(id: '', displayName: '', name: ''));
    return ch.creatorId == user.id;
  }

  bool canCurrentUserAddMembers(String channelId) {
    final ch = _channels.firstWhere((c) => c.id == channelId, orElse: () => MattermostChannel(id: '', displayName: '', name: ''));
    if (ch.type == 'D') return false;
    return true;
  }

  // --- WebSocket Event Handlers ---
  void _handleWsPosted(MattermostWebSocketEvent event) {
    try {
      final rawPost = event.data is Map ? event.data['post'] : null;
      if (rawPost == null) return;

      Map<String, dynamic> postJson;
      if (rawPost is String) {
        postJson = jsonDecode(rawPost);
      } else if (rawPost is Map<String, dynamic>) {
        postJson = rawPost;
      } else {
        return;
      }

      final post = MattermostPost.fromJson(postJson);
      final myId = _auth?.currentUser?.id ?? '';
      final isFromMe = post.userId == myId;

      // Handle sound & unread
      if (isFromMe) {
        _sound.playSent();
      } else {
        _sound.playReceived();
        if (post.channelId != _activeChannelId) {
          _unreadCounts[post.channelId] = (_unreadCounts[post.channelId] ?? 0) + 1;
        }
      }

      // Add to posts list if channel is loaded
      if (_posts.containsKey(post.channelId)) {
        final list = _posts[post.channelId]!;
        if (!list.any((p) => p.id == post.id)) {
          // If temp post exists, replace it
          final tempIdx = list.indexWhere((p) => p.id.startsWith('temp_') && p.message == post.message);
          if (tempIdx != -1) {
            list[tempIdx] = post;
          } else {
            list.add(post);
          }
        }
      }

      // If active thread matches, add to thread
      if (_activeThreadRootPost != null && post.rootId == _activeThreadRootPost!.id) {
        if (!_threadPosts.any((p) => p.id == post.id)) {
          _threadPosts.add(post);
        }
      }

      // Update channel last post
      final chIdx = _channels.indexWhere((c) => c.id == post.channelId);
      if (chIdx != -1) {
        _channels[chIdx].lastPost = post;
        _sortChannelsList(_channels);
      }

      _users?.fetchUsers([post.userId]);
      notifyListeners();
    } catch (_) {}
  }

  void _handleWsTyping(MattermostWebSocketEvent event) {
    try {
      final data = event.data as Map<String, dynamic>?;
      if (data == null) return;
      final userId = data['user_id'] as String? ?? event.broadcast['user_id'] as String? ?? '';
      final channelId = data['channel_id'] as String? ?? event.broadcast['channel_id'] as String? ?? '';
      final myId = _auth?.currentUser?.id ?? '';

      if (userId.isEmpty || channelId.isEmpty || userId == myId) return;

      final username = _users?.getUserDisplayName(userId) ?? 'User';
      _typingUsers.putIfAbsent(channelId, () => {})[userId] = username;
      notifyListeners();

      final timerKey = '$channelId:$userId';
      _typingTimers[timerKey]?.cancel();
      _typingTimers[timerKey] = Timer(const Duration(seconds: 4), () {
        _typingUsers[channelId]?.remove(userId);
        notifyListeners();
      });
    } catch (_) {}
  }

  void _handleWsReactionAdded(MattermostWebSocketEvent event) {
    try {
      final raw = event.data is Map ? event.data['reaction'] : null;
      if (raw == null) return;
      final reactionJson = raw is String ? jsonDecode(raw) : raw;
      final reaction = MattermostReaction.fromJson(reactionJson);
      _addReactionToPost(reaction.postId, reaction);
      notifyListeners();
    } catch (_) {}
  }

  void _handleWsReactionRemoved(MattermostWebSocketEvent event) {
    try {
      final raw = event.data is Map ? event.data['reaction'] : null;
      if (raw == null) return;
      final reactionJson = raw is String ? jsonDecode(raw) : raw;
      final reaction = MattermostReaction.fromJson(reactionJson);
      _removeReactionFromPost(reaction.postId, reaction.userId, reaction.emojiName);
      notifyListeners();
    } catch (_) {}
  }

  void _handleWsPostEdited(MattermostWebSocketEvent event) {
    try {
      final raw = event.data is Map ? event.data['post'] : null;
      if (raw == null) return;
      final postJson = raw is String ? jsonDecode(raw) : raw;
      final post = MattermostPost.fromJson(postJson);
      _updatePostInLists(post);
      notifyListeners();
    } catch (_) {}
  }

  void _handleWsPostDeleted(MattermostWebSocketEvent event) {
    try {
      final raw = event.data is Map ? event.data['post'] : null;
      if (raw == null) return;
      final postJson = raw is String ? jsonDecode(raw) : raw;
      final postId = postJson['id'] as String?;
      if (postId != null) {
        _removePostFromLists(postId);
        notifyListeners();
      }
    } catch (_) {}
  }

  void _handleWsChannelViewed(MattermostWebSocketEvent event) {
    try {
      final channelId = event.data?['channel_id'] as String?;
      if (channelId != null) {
        _unreadCounts[channelId] = 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  void _updatePostInLists(MattermostPost post) {
    void update(List<MattermostPost> list) {
      final idx = list.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        list[idx] = post;
      }
    }

    for (final l in _posts.values) {
      update(l);
    }
    update(_threadPosts);
    if (_activeThreadRootPost?.id == post.id) {
      _activeThreadRootPost = post;
    }
  }

  void _removePostFromLists(String postId) {
    for (final l in _posts.values) {
      l.removeWhere((p) => p.id == postId);
    }
    _threadPosts.removeWhere((p) => p.id == postId);
    if (_activeThreadRootPost?.id == postId) {
      closeThread();
    }
  }
}
