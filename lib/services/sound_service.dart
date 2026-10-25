import 'package:flutter/services.dart';
import 'storage_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _enabled = true;

  bool get isEnabled => _enabled;

  Future<void> init(StorageService storage) async {
    _enabled = storage.getSoundEnabled();
  }

  void setEnabled(bool value, StorageService storage) {
    _enabled = value;
    storage.setSoundEnabled(value);
  }

  // Telegram sent message sound / haptic feedback
  void playSent() {
    if (!_enabled) return;
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  // Telegram received message notification sound / haptic feedback
  void playReceived() {
    if (!_enabled) return;
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
