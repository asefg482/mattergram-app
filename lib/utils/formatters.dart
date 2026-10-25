import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const List<List<Color>> tgAvatarGradients = [
  [Color(0xFFE17076), Color(0xFFFF885E)], // Coral
  [Color(0xFFFAA774), Color(0xFFFFC66A)], // Orange
  [Color(0xFFA695E7), Color(0xFF7B68EE)], // Violet
  [Color(0xFF7BC862), Color(0xFF4FAE60)], // Green
  [Color(0xFF6EC9CB), Color(0xFF36B1CD)], // Cyan
  [Color(0xFF65AADD), Color(0xFF2481CC)], // Blue
  [Color(0xFFEE7AAE), Color(0xFFD8508F)], // Pink
  [Color(0xFFD077D8), Color(0xFFA851BF)], // Purple
];

LinearGradient getAvatarGradient(String nameOrId) {
  if (nameOrId.isEmpty) {
    return const LinearGradient(
      colors: [Color(0xFF65AADD), Color(0xFF2481CC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  int hash = 0;
  for (int i = 0; i < nameOrId.length; i++) {
    hash = nameOrId.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final index = hash.abs() % tgAvatarGradients.length;
  final colors = tgAvatarGradients[index];

  return LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

Color getAvatarSingleColor(String nameOrId) {
  if (nameOrId.isEmpty) return const Color(0xFF2481CC);
  int hash = 0;
  for (int i = 0; i < nameOrId.length; i++) {
    hash = nameOrId.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final index = hash.abs() % tgAvatarGradients.length;
  return tgAvatarGradients[index][1];
}

String getInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  } else if (trimmed.length >= 2) {
    return trimmed.substring(0, 2).toUpperCase();
  }
  return trimmed.substring(0, 1).toUpperCase();
}

DateTime? toSafeDate(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is DateTime) return timestamp;
  int? num;
  if (timestamp is int) {
    num = timestamp;
  } else if (timestamp is String) {
    num = int.tryParse(timestamp);
  }
  if (num == null || num <= 0) return null;
  if (num < 10000000000) num *= 1000;
  return DateTime.fromMillisecondsSinceEpoch(num);
}

String formatMessageTime(int timestamp, {bool use24Hour = true}) {
  final date = toSafeDate(timestamp);
  if (date == null) return '';
  return use24Hour ? DateFormat('HH:mm').format(date) : DateFormat('h:mm a').format(date);
}

String formatChatListTime(int timestamp, {bool use24Hour = true}) {
  final date = toSafeDate(timestamp);
  if (date == null) return '';
  final now = DateTime.now();

  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return use24Hour ? DateFormat('HH:mm').format(date) : DateFormat('h:mm a').format(date);
  }

  final yesterday = now.subtract(const Duration(days: 1));
  if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
    return 'Yesterday';
  }

  if (now.difference(date).inDays < 7) {
    return DateFormat('EEE').format(date);
  }

  return DateFormat('MMM d').format(date);
}

String formatDateSeparator(int timestamp) {
  final date = toSafeDate(timestamp);
  if (date == null) return '';
  final now = DateTime.now();

  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Today';
  }

  final yesterday = now.subtract(const Duration(days: 1));
  if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
    return 'Yesterday';
  }

  if (date.year == now.year) {
    return DateFormat('MMMM d').format(date);
  }

  return DateFormat('MMMM d, yyyy').format(date);
}

bool isDifferentDay(int currTimestamp, int? prevTimestamp) {
  if (prevTimestamp == null || prevTimestamp == 0) return true;
  final d1 = toSafeDate(currTimestamp);
  final d2 = toSafeDate(prevTimestamp);
  if (d1 == null || d2 == null) return true;
  return d1.year != d2.year || d1.month != d2.month || d1.day != d2.day;
}

String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  int i = 0;
  double size = bytes.toDouble();
  while (size >= 1024 && i < suffixes.length - 1) {
    size /= 1024;
    i++;
  }
  return '${size.toStringAsFixed(1)} ${suffixes[i]}';
}
