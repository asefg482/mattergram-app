import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String name;
  final bool isDark;
  final Color bg;
  final Color sidebar;
  final Color card;
  final Color bubbleIn;
  final Color bubbleOut;
  final Color accent;
  final Color text;
  final Color muted;
  final Color border;
  final String description;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.isDark,
    required this.bg,
    required this.sidebar,
    required this.card,
    required this.bubbleIn,
    required this.bubbleOut,
    required this.accent,
    required this.text,
    required this.muted,
    required this.border,
    required this.description,
  });
}

class AnimationPreset {
  final String id;
  final String name;
  final String description;
  final Duration duration;
  final Curve curve;

  const AnimationPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.curve,
  });
}

const List<ThemePreset> themePresets = [
  ThemePreset(
    id: 'classic-dark',
    name: 'Telegram Dark',
    isDark: true,
    bg: Color(0xFF0E1621),
    sidebar: Color(0xFF17212B),
    card: Color(0xFF242F3D),
    bubbleIn: Color(0xFF182533),
    bubbleOut: Color(0xFF2B5278),
    accent: Color(0xFF3390EC),
    text: Color(0xFFF5F5F5),
    muted: Color(0xFF7F91A4),
    border: Color(0xFF101921),
    description: 'Classic Telegram dark theme with blue accents',
  ),
  ThemePreset(
    id: 'classic-light',
    name: 'Telegram Day',
    isDark: false,
    bg: Color(0xFF8EA6B4),
    sidebar: Color(0xFFFFFFFF),
    card: Color(0xFFF4F4F5),
    bubbleIn: Color(0xFFFFFFFF),
    bubbleOut: Color(0xFFEEFFDE),
    accent: Color(0xFF3390EC),
    text: Color(0xFF111827),
    muted: Color(0xFF707579),
    border: Color(0xFFDFE1E5),
    description: 'Crisp light theme with pastel green bubbles',
  ),
  ThemePreset(
    id: 'midnight-amoled',
    name: 'Midnight AMOLED',
    isDark: true,
    bg: Color(0xFF000000),
    sidebar: Color(0xFF09090B),
    card: Color(0xFF141416),
    bubbleIn: Color(0xFF121214),
    bubbleOut: Color(0xFF0284C7),
    accent: Color(0xFF38BDF8),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFF71717A),
    border: Color(0xFF27272A),
    description: 'Pure black contrast optimized for OLED displays',
  ),
  ThemePreset(
    id: 'matrix-emerald',
    name: 'Emerald Forest',
    isDark: true,
    bg: Color(0xFF06130D),
    sidebar: Color(0xFF0A1C14),
    card: Color(0xFF112A1F),
    bubbleIn: Color(0xFF0D2219),
    bubbleOut: Color(0xFF144E36),
    accent: Color(0xFF10B981),
    text: Color(0xFFF0FDF4),
    muted: Color(0xFF6EE7B7),
    border: Color(0xFF064E3B),
    description: 'Deep emerald palette inspired by nature',
  ),
  ThemePreset(
    id: 'cyberpunk-neon',
    name: 'Cyberpunk Violet',
    isDark: true,
    bg: Color(0xFF0D081A),
    sidebar: Color(0xFF150D29),
    card: Color(0xFF22143F),
    bubbleIn: Color(0xFF1C1134),
    bubbleOut: Color(0xFF581C87),
    accent: Color(0xFFC084FC),
    text: Color(0xFFFAF5FF),
    muted: Color(0xFFD8B4FE),
    border: Color(0xFF3B0764),
    description: 'Futuristic cosmic neon purple aesthetic',
  ),
  ThemePreset(
    id: 'sunset-amber',
    name: 'Warm Sunset',
    isDark: true,
    bg: Color(0xFF140F0C),
    sidebar: Color(0xFF1D1612),
    card: Color(0xFF2A201B),
    bubbleIn: Color(0xFF231A15),
    bubbleOut: Color(0xFF6C3B1C),
    accent: Color(0xFFF59E0B),
    text: Color(0xFFFFFBEB),
    muted: Color(0xFFFCD34D),
    border: Color(0xFF451A03),
    description: 'Cozy espresso and warm amber golden hour tones',
  ),
  ThemePreset(
    id: 'arctic-nord',
    name: 'Arctic Frost',
    isDark: true,
    bg: Color(0xFF0F172A),
    sidebar: Color(0xFF172338),
    card: Color(0xFF1E2F47),
    bubbleIn: Color(0xFF1A293E),
    bubbleOut: Color(0xFF2563EB),
    accent: Color(0xFF60A5FA),
    text: Color(0xFFF8FAFC),
    muted: Color(0xFF93C5FD),
    border: Color(0xFF1E3A8A),
    description: 'Cool Scandinavian blue inspired by Nordic glaciers',
  ),
];

const List<AnimationPreset> animationPresets = [
  AnimationPreset(
    id: 'smooth',
    name: 'Telegram Smooth',
    description: 'Standard fluid Telegram motion balanced for performance and beauty',
    duration: Duration(milliseconds: 250),
    curve: Curves.easeOutCubic,
  ),
  AnimationPreset(
    id: 'spring',
    name: 'Bouncy Spring',
    description: 'Playful elastic spring physics for messages and menus',
    duration: Duration(milliseconds: 350),
    curve: Curves.elasticOut,
  ),
  AnimationPreset(
    id: 'fast',
    name: 'Turbo Snappy',
    description: 'Ultra-fast 75ms animations for maximum responsiveness',
    duration: Duration(milliseconds: 75),
    curve: Curves.easeOutQuad,
  ),
  AnimationPreset(
    id: 'pulse',
    name: 'Ambient Glow',
    description: 'Soft neon glows and subtle pulse effects on active elements',
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  ),
  AnimationPreset(
    id: 'none',
    name: 'Reduced Motion',
    description: 'Disables all animations for accessibility and minimum resource usage',
    duration: Duration.zero,
    curve: Curves.linear,
  ),
];

ThemePreset getThemeById(String id) {
  return themePresets.firstWhere(
    (t) => t.id == id,
    orElse: () => themePresets[0],
  );
}

AnimationPreset getAnimationById(String id) {
  return animationPresets.firstWhere(
    (a) => a.id == id,
    orElse: () => animationPresets[0],
  );
}
