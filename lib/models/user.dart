class MattermostUser {
  final String id;
  final int createAt;
  final int updateAt;
  final int deleteAt;
  final String username;
  final String authService;
  final String email;
  final String nickname;
  final String firstName;
  final String lastName;
  final String position;
  final String roles;
  final String locale;
  final Map<String, dynamic>? timezone;
  final int? lastPictureUpdate;

  MattermostUser({
    required this.id,
    this.createAt = 0,
    this.updateAt = 0,
    this.deleteAt = 0,
    required this.username,
    this.authService = '',
    required this.email,
    this.nickname = '',
    this.firstName = '',
    this.lastName = '',
    this.position = '',
    this.roles = '',
    this.locale = 'en',
    this.timezone,
    this.lastPictureUpdate,
  });

  factory MattermostUser.fromJson(Map<String, dynamic> json) {
    return MattermostUser(
      id: json['id'] as String? ?? '',
      createAt: json['create_at'] as int? ?? 0,
      updateAt: json['update_at'] as int? ?? 0,
      deleteAt: json['delete_at'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      authService: json['auth_service'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      position: json['position'] as String? ?? '',
      roles: json['roles'] as String? ?? '',
      locale: json['locale'] as String? ?? 'en',
      timezone: json['timezone'] is Map<String, dynamic>
          ? json['timezone'] as Map<String, dynamic>
          : null,
      lastPictureUpdate: json['last_picture_update'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'create_at': createAt,
      'update_at': updateAt,
      'delete_at': deleteAt,
      'username': username,
      'auth_service': authService,
      'email': email,
      'nickname': nickname,
      'first_name': firstName,
      'last_name': lastName,
      'position': position,
      'roles': roles,
      'locale': locale,
      if (timezone != null) 'timezone': timezone,
      if (lastPictureUpdate != null) 'last_picture_update': lastPictureUpdate,
    };
  }

  MattermostUser copyWith({
    String? id,
    int? createAt,
    int? updateAt,
    int? deleteAt,
    String? username,
    String? authService,
    String? email,
    String? nickname,
    String? firstName,
    String? lastName,
    String? position,
    String? roles,
    String? locale,
    Map<String, dynamic>? timezone,
    int? lastPictureUpdate,
  }) {
    return MattermostUser(
      id: id ?? this.id,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      deleteAt: deleteAt ?? this.deleteAt,
      username: username ?? this.username,
      authService: authService ?? this.authService,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      position: position ?? this.position,
      roles: roles ?? this.roles,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      lastPictureUpdate: lastPictureUpdate ?? this.lastPictureUpdate,
    );
  }

  String get displayName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    if (firstName.isNotEmpty) {
      return firstName;
    }
    if (nickname.isNotEmpty) {
      return nickname;
    }
    if (username.isNotEmpty) {
      return username;
    }
    return email;
  }
}

class UserStatus {
  final String userId;
  final String status; // 'online', 'offline', 'away', 'dnd'
  final bool manual;
  final int lastActivityAt;

  UserStatus({
    required this.userId,
    required this.status,
    this.manual = false,
    this.lastActivityAt = 0,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      userId: json['user_id'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      manual: json['manual'] as bool? ?? false,
      lastActivityAt: json['last_activity_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'manual': manual,
      'last_activity_at': lastActivityAt,
    };
  }
}
