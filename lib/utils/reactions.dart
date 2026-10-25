const Map<String, String> emojiNameToChar = {
  '+1': '👍',
  '-1': '👎',
  'thumbsup': '👍',
  'thumbsdown': '👎',
  'heart': '❤️',
  'fire': '🔥',
  'joy': '😂',
  'sob': '😭',
  'clap': '👏',
  'tada': '🎉',
  'thinking': '🤔',
  'eyes': '👀',
  '100': '💯',
  'rocket': '🚀',
  'pray': '🙏',
  'smile': '😄',
  'grinning': '😀',
  'sweat_smile': '😅',
  'laughing': '😆',
  'wink': '😉',
  'blush': '😊',
  'heart_eyes': '😍',
  'kissing_heart': '😘',
  'relaxed': '☺️',
  'neutral_face': '😐',
  'expressionless': '😑',
  'unamused': '😒',
  'sweat': '😓',
  'pensive': '😔',
  'confused': '😕',
  'sunglasses': '😎',
  'smirk': '😏',
  'star': '⭐',
  'sparkles': '✨',
  'check': '✅',
  'heavy_check_mark': '✔️',
  'x': '❌',
  'warning': '⚠️',
  'question': '❓',
  'exclamation': '❗',
  'partying_face': '🥳',
  'pleading_face': '🥺',
  'rofl': '🤣',
  'hugs': '🤗',
  'wave': '👋',
  'muscle': '💪',
  'bulb': '💡',
  'pin': '📌',
  'coffee': '☕',
};

final Map<String, String> charToEmojiName = {
  for (var entry in emojiNameToChar.entries) entry.value: entry.key,
};

const List<String> defaultFrequentEmojis = [
  '👍',
  '❤️',
  '🔥',
  '😂',
  '👏',
  '🎉',
  '🤔',
  '👀',
  '💯',
  '🚀',
  '🙏',
  '😍',
  '🥳',
  '😭',
  '✨',
  '⭐',
];

String toEmojiChar(String rawName) {
  final clean = rawName.replaceAll(RegExp(r'^:+|:+$'), '').trim();
  return emojiNameToChar[clean] ?? clean;
}

String toEmojiName(String char) {
  return charToEmojiName[char] ?? char;
}
