import 'user.dart';
import 'post.dart';

class MattermostChannel {
  final String id;
  final int createAt;
  final int updateAt;
  final int deleteAt;
  final String teamId;
  final String type; // 'O' Open, 'P' Private, 'D' Direct, 'G' Group
  final String displayName;
  final String name;
  final String header;
  final String purpose;
  final int lastPostAt;
  final int totalMsgCount;
  final String creatorId;
  final Map<String, dynamic>? props;

  // Virtual fields for Telegram UI
  MattermostUser? dmUser;
  int unreadCount;
  bool isPinned;
  bool isMuted;
  MattermostPost? lastPost;

  MattermostChannel({
    required this.id,
    this.createAt = 0,
    this.updateAt = 0,
    this.deleteAt = 0,
    this.teamId = '',
    this.type = 'O',
    required this.displayName,
    required this.name,
    this.header = '',
    this.purpose = '',
    this.lastPostAt = 0,
    this.totalMsgCount = 0,
    this.creatorId = '',
    this.props,
    this.dmUser,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.lastPost,
  });

  factory MattermostChannel.fromJson(Map<String, dynamic> json) {
    return MattermostChannel(
      id: json['id'] as String? ?? '',
      createAt: json['create_at'] as int? ?? 0,
      updateAt: json['update_at'] as int? ?? 0,
      deleteAt: json['delete_at'] as int? ?? 0,
      teamId: json['team_id'] as String? ?? '',
      type: json['type'] as String? ?? 'O',
      displayName: json['display_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      header: json['header'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      lastPostAt: json['last_post_at'] as int? ?? 0,
      totalMsgCount: json['total_msg_count'] as int? ?? 0,
      creatorId: json['creator_id'] as String? ?? '',
      props: json['props'] is Map<String, dynamic>
          ? json['props'] as Map<String, dynamic>
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'create_at': createAt,
      'update_at': updateAt,
      'delete_at': deleteAt,
      'team_id': teamId,
      'type': type,
      'display_name': displayName,
      'name': name,
      'header': header,
      'purpose': purpose,
      'last_post_at': lastPostAt,
      'total_msg_count': totalMsgCount,
      'creator_id': creatorId,
      if (props != null) 'props': props,
    };
  }

  MattermostChannel copyWith({
    String? id,
    int? createAt,
    int? updateAt,
    int? deleteAt,
    String? teamId,
    String? type,
    String? displayName,
    String? name,
    String? header,
    String? purpose,
    int? lastPostAt,
    int? totalMsgCount,
    String? creatorId,
    Map<String, dynamic>? props,
    MattermostUser? dmUser,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    MattermostPost? lastPost,
  }) {
    return MattermostChannel(
      id: id ?? this.id,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      deleteAt: deleteAt ?? this.deleteAt,
      teamId: teamId ?? this.teamId,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      name: name ?? this.name,
      header: header ?? this.header,
      purpose: purpose ?? this.purpose,
      lastPostAt: lastPostAt ?? this.lastPostAt,
      totalMsgCount: totalMsgCount ?? this.totalMsgCount,
      creatorId: creatorId ?? this.creatorId,
      props: props ?? this.props,
      dmUser: dmUser ?? this.dmUser,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      lastPost: lastPost ?? this.lastPost,
    );
  }

  bool get isDirect => type == 'D';
  bool get isPrivate => type == 'P';
  bool get isPublic => type == 'O';
  bool get isSavedMessages => displayName == 'Saved Messages';
}

class MattermostChannelMember {
  final String channelId;
  final String userId;
  final String roles;
  final int lastViewedAt;
  final int msgCount;
  final int mentionCount;
  final Map<String, dynamic>? notifyProps;
  final int lastUpdateAt;
  final bool schemeGuest;
  final bool schemeUser;
  final bool schemeAdmin;
  final String? explicitRoles;

  MattermostChannelMember({
    required this.channelId,
    required this.userId,
    this.roles = '',
    this.lastViewedAt = 0,
    this.msgCount = 0,
    this.mentionCount = 0,
    this.notifyProps,
    this.lastUpdateAt = 0,
    this.schemeGuest = false,
    this.schemeUser = true,
    this.schemeAdmin = false,
    this.explicitRoles,
  });

  factory MattermostChannelMember.fromJson(Map<String, dynamic> json) {
    return MattermostChannelMember(
      channelId: json['channel_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      roles: json['roles'] as String? ?? '',
      lastViewedAt: json['last_viewed_at'] as int? ?? 0,
      msgCount: json['msg_count'] as int? ?? 0,
      mentionCount: json['mention_count'] as int? ?? 0,
      notifyProps: json['notify_props'] is Map<String, dynamic>
          ? json['notify_props'] as Map<String, dynamic>
          : null,
      lastUpdateAt: json['last_update_at'] as int? ?? 0,
      schemeGuest: json['scheme_guest'] as bool? ?? false,
      schemeUser: json['scheme_user'] as bool? ?? true,
      schemeAdmin: json['scheme_admin'] as bool? ?? false,
      explicitRoles: json['explicit_roles'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'user_id': userId,
      'roles': roles,
      'last_viewed_at': lastViewedAt,
      'msg_count': msgCount,
      'mention_count': mentionCount,
      if (notifyProps != null) 'notify_props': notifyProps,
      'last_update_at': lastUpdateAt,
      'scheme_guest': schemeGuest,
      'scheme_user': schemeUser,
      'scheme_admin': schemeAdmin,
      if (explicitRoles != null) 'explicit_roles': explicitRoles,
    };
  }
}
