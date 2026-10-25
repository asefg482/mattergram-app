class MattermostTeam {
  final String id;
  final int createAt;
  final int updateAt;
  final int deleteAt;
  final String displayName;
  final String name;
  final String description;
  final String email;
  final String type;
  final String companyName;
  final String allowedDomains;
  final String inviteId;
  final bool allowOpenInvite;

  MattermostTeam({
    required this.id,
    this.createAt = 0,
    this.updateAt = 0,
    this.deleteAt = 0,
    required this.displayName,
    required this.name,
    this.description = '',
    this.email = '',
    this.type = 'O',
    this.companyName = '',
    this.allowedDomains = '',
    this.inviteId = '',
    this.allowOpenInvite = true,
  });

  factory MattermostTeam.fromJson(Map<String, dynamic> json) {
    return MattermostTeam(
      id: json['id'] as String? ?? '',
      createAt: json['create_at'] as int? ?? 0,
      updateAt: json['update_at'] as int? ?? 0,
      deleteAt: json['delete_at'] as int? ?? 0,
      displayName: json['display_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      email: json['email'] as String? ?? '',
      type: json['type'] as String? ?? 'O',
      companyName: json['company_name'] as String? ?? '',
      allowedDomains: json['allowed_domains'] as String? ?? '',
      inviteId: json['invite_id'] as String? ?? '',
      allowOpenInvite: json['allow_open_invite'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'create_at': createAt,
      'update_at': updateAt,
      'delete_at': deleteAt,
      'display_name': displayName,
      'name': name,
      'description': description,
      'email': email,
      'type': type,
      'company_name': companyName,
      'allowed_domains': allowedDomains,
      'invite_id': inviteId,
      'allow_open_invite': allowOpenInvite,
    };
  }
}
