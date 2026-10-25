class MattermostFileInfo {
  final String id;
  final String userId;
  final String postId;
  final String channelId;
  final int createAt;
  final int updateAt;
  final int deleteAt;
  final String name;
  final String extension;
  final int size;
  final String mimeType;
  final String? miniPreview;
  final String? remoteId;
  final int? width;
  final int? height;

  MattermostFileInfo({
    required this.id,
    this.userId = '',
    this.postId = '',
    this.channelId = '',
    this.createAt = 0,
    this.updateAt = 0,
    this.deleteAt = 0,
    required this.name,
    this.extension = '',
    this.size = 0,
    this.mimeType = '',
    this.miniPreview,
    this.remoteId,
    this.width,
    this.height,
  });

  factory MattermostFileInfo.fromJson(Map<String, dynamic> json) {
    return MattermostFileInfo(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      channelId: json['channel_id'] as String? ?? '',
      createAt: json['create_at'] as int? ?? 0,
      updateAt: json['update_at'] as int? ?? 0,
      deleteAt: json['delete_at'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      extension: json['extension'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ?? '',
      miniPreview: json['mini_preview'] as String?,
      remoteId: json['remote_id'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'channel_id': channelId,
      'create_at': createAt,
      'update_at': updateAt,
      'delete_at': deleteAt,
      'name': name,
      'extension': extension,
      'size': size,
      'mime_type': mimeType,
      if (miniPreview != null) 'mini_preview': miniPreview,
      if (remoteId != null) 'remote_id': remoteId,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  bool get isImage =>
      mimeType.startsWith('image/') ||
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'].contains(extension.toLowerCase());

  bool get isVideo =>
      mimeType.startsWith('video/') ||
      ['mp4', 'webm', 'mov', 'mkv', 'avi'].contains(extension.toLowerCase());

  bool get isAudio =>
      mimeType.startsWith('audio/') ||
      ['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac'].contains(extension.toLowerCase());
}

class MattermostReaction {
  final String userId;
  final String postId;
  final String emojiName;
  final int createAt;

  MattermostReaction({
    required this.userId,
    required this.postId,
    required this.emojiName,
    this.createAt = 0,
  });

  factory MattermostReaction.fromJson(Map<String, dynamic> json) {
    return MattermostReaction(
      userId: json['user_id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      emojiName: json['emoji_name'] as String? ?? '',
      createAt: json['create_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'post_id': postId,
      'emoji_name': emojiName,
      'create_at': createAt,
    };
  }
}

class MattermostPost {
  final String id;
  final int createAt;
  final int updateAt;
  final int editAt;
  final int deleteAt;
  bool isPinned;
  final String userId;
  final String channelId;
  final String rootId;
  final String originalId;
  String message;
  final String type;
  final Map<String, dynamic> props;
  final String hashtags;
  final List<String> fileIds;
  final String? pendingPostId;
  final int replyCount;
  final int lastReplyAt;
  final List<dynamic>? participants;
  final List<MattermostFileInfo> files;
  final List<MattermostReaction> reactions;

  MattermostPost({
    required this.id,
    this.createAt = 0,
    this.updateAt = 0,
    this.editAt = 0,
    this.deleteAt = 0,
    this.isPinned = false,
    required this.userId,
    required this.channelId,
    this.rootId = '',
    this.originalId = '',
    required this.message,
    this.type = '',
    this.props = const {},
    this.hashtags = '',
    this.fileIds = const [],
    this.pendingPostId,
    this.replyCount = 0,
    this.lastReplyAt = 0,
    this.participants,
    this.files = const [],
    this.reactions = const [],
  });

  factory MattermostPost.fromJson(Map<String, dynamic> json) {
    List<MattermostFileInfo> parsedFiles = [];
    List<MattermostReaction> parsedReactions = [];

    if (json['metadata'] is Map<String, dynamic>) {
      final meta = json['metadata'] as Map<String, dynamic>;
      if (meta['files'] is List) {
        parsedFiles = (meta['files'] as List)
            .whereType<Map<String, dynamic>>()
            .map((f) => MattermostFileInfo.fromJson(f))
            .toList();
      }
      if (meta['reactions'] is List) {
        parsedReactions = (meta['reactions'] as List)
            .whereType<Map<String, dynamic>>()
            .map((r) => MattermostReaction.fromJson(r))
            .toList();
      }
    }

    return MattermostPost(
      id: json['id'] as String? ?? '',
      createAt: json['create_at'] as int? ?? 0,
      updateAt: json['update_at'] as int? ?? 0,
      editAt: json['edit_at'] as int? ?? 0,
      deleteAt: json['delete_at'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      userId: json['user_id'] as String? ?? '',
      channelId: json['channel_id'] as String? ?? '',
      rootId: json['root_id'] as String? ?? '',
      originalId: json['original_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? '',
      props: json['props'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['props'])
          : {},
      hashtags: json['hashtags'] as String? ?? '',
      fileIds: json['file_ids'] is List
          ? (json['file_ids'] as List).map((e) => e.toString()).toList()
          : [],
      pendingPostId: json['pending_post_id'] as String?,
      replyCount: json['reply_count'] as int? ?? 0,
      lastReplyAt: json['last_reply_at'] as int? ?? 0,
      participants: json['participants'] as List<dynamic>?,
      files: parsedFiles,
      reactions: parsedReactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'create_at': createAt,
      'update_at': updateAt,
      'edit_at': editAt,
      'delete_at': deleteAt,
      'is_pinned': isPinned,
      'user_id': userId,
      'channel_id': channelId,
      'root_id': rootId,
      'original_id': originalId,
      'message': message,
      'type': type,
      'props': props,
      'hashtags': hashtags,
      'file_ids': fileIds,
      if (pendingPostId != null) 'pending_post_id': pendingPostId,
      'reply_count': replyCount,
      'last_reply_at': lastReplyAt,
      'metadata': {
        'files': files.map((f) => f.toJson()).toList(),
        'reactions': reactions.map((r) => r.toJson()).toList(),
      },
    };
  }

  MattermostPost copyWith({
    String? id,
    int? createAt,
    int? updateAt,
    int? editAt,
    int? deleteAt,
    bool? isPinned,
    String? userId,
    String? channelId,
    String? rootId,
    String? originalId,
    String? message,
    String? type,
    Map<String, dynamic>? props,
    String? hashtags,
    List<String>? fileIds,
    String? pendingPostId,
    int? replyCount,
    int? lastReplyAt,
    List<dynamic>? participants,
    List<MattermostFileInfo>? files,
    List<MattermostReaction>? reactions,
  }) {
    return MattermostPost(
      id: id ?? this.id,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      editAt: editAt ?? this.editAt,
      deleteAt: deleteAt ?? this.deleteAt,
      isPinned: isPinned ?? this.isPinned,
      userId: userId ?? this.userId,
      channelId: channelId ?? this.channelId,
      rootId: rootId ?? this.rootId,
      originalId: originalId ?? this.originalId,
      message: message ?? this.message,
      type: type ?? this.type,
      props: props ?? this.props,
      hashtags: hashtags ?? this.hashtags,
      fileIds: fileIds ?? this.fileIds,
      pendingPostId: pendingPostId ?? this.pendingPostId,
      replyCount: replyCount ?? this.replyCount,
      lastReplyAt: lastReplyAt ?? this.lastReplyAt,
      participants: participants ?? this.participants,
      files: files ?? this.files,
      reactions: reactions ?? this.reactions,
    );
  }
}

class ChannelPostsResponse {
  final List<String> order;
  final Map<String, MattermostPost> posts;
  final String? nextPostId;
  final String? prevPostId;

  ChannelPostsResponse({
    required this.order,
    required this.posts,
    this.nextPostId,
    this.prevPostId,
  });

  factory ChannelPostsResponse.fromJson(Map<String, dynamic> json) {
    final order = (json['order'] as List? ?? []).map((e) => e.toString()).toList();
    final rawPosts = json['posts'] as Map<String, dynamic>? ?? {};
    final posts = rawPosts.map((k, v) => MapEntry(k, MattermostPost.fromJson(v)));
    return ChannelPostsResponse(
      order: order,
      posts: posts,
      nextPostId: json['next_post_id'] as String?,
      prevPostId: json['prev_post_id'] as String?,
    );
  }
}
