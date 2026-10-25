class MattermostWebSocketEvent {
  final String event;
  final dynamic data;
  final Map<String, dynamic> broadcast;
  final int seq;

  MattermostWebSocketEvent({
    required this.event,
    required this.data,
    this.broadcast = const {},
    this.seq = 0,
  });

  factory MattermostWebSocketEvent.fromJson(Map<String, dynamic> json) {
    return MattermostWebSocketEvent(
      event: json['event'] as String? ?? '',
      data: json['data'],
      broadcast: json['broadcast'] is Map<String, dynamic>
          ? json['broadcast'] as Map<String, dynamic>
          : {},
      seq: json['seq'] as int? ?? 0,
    );
  }
}
