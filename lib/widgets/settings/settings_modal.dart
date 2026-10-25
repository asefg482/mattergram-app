import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ui_provider.dart';
import '../../services/api_service.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import '../../utils/themes.dart';
import '../common/telegram_avatar.dart';

class SettingsModal extends StatefulWidget {
  final VoidCallback onClose;

  const SettingsModal({super.key, required this.onClose});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  bool _testingServer = false;
  String? _serverPingResult;
  bool _serverPingOk = false;

  Future<void> _testConnection() async {
    setState(() {
      _testingServer = true;
      _serverPingResult = null;
    });
    final ok = await ApiService().pingServer();
    if (mounted) {
      setState(() {
        _testingServer = false;
        _serverPingOk = ok;
        _serverPingResult = ok ? 'Server is operational and reachable' : 'Could not reach server';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ui = context.watch<UiProvider>();
    final theme = ui.currentTheme;
    final user = auth.currentUser;
    final sound = SoundService();

    return Dialog(
      backgroundColor: theme.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          children: [
            // Modal Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Settings Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Profile Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        TelegramAvatar(
                          userId: user?.id,
                          name: user?.displayName ?? 'User',
                          size: 56,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'User',
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user != null && user.username.isNotEmpty ? '@${user.username}' : user?.email ?? '',
                                style: TextStyle(color: theme.muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            widget.onClose();
                            ui.showAccountSettingsModal = true;
                          },
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Server Connection
                  _buildSectionHeader('Server Connection', theme),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mattermost Server URL', style: TextStyle(color: theme.muted, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          auth.baseUrl.isNotEmpty ? auth.baseUrl : 'Not configured',
                          style: TextStyle(color: theme.text, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: _testingServer
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.network_check, size: 18),
                              label: const Text('Test Connection'),
                              style: ElevatedButton.styleFrom(backgroundColor: theme.accent, foregroundColor: Colors.white),
                              onPressed: _testingServer ? null : _testConnection,
                            ),
                          ],
                        ),
                        if (_serverPingResult != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _serverPingOk ? Icons.check_circle : Icons.error,
                                color: _serverPingOk ? const Color(0xFF4FAE60) : const Color(0xFFE53935),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _serverPingResult!,
                                style: TextStyle(
                                  color: _serverPingOk ? const Color(0xFF4FAE60) : const Color(0xFFE53935),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Appearance & Themes
                  _buildSectionHeader('Theme & Appearance', theme),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Night Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Switch between dark and light themes', style: TextStyle(color: theme.muted, fontSize: 12)),
                    value: ui.isDarkMode,
                    onChanged: (_) => ui.toggleDarkMode(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Theme Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: themePresets.map((preset) {
                      final isSelected = ui.themeId == preset.id;
                      return InkWell(
                        onTap: () => ui.setTheme(preset.id),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: preset.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? theme.accent : preset.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(width: 14, height: 14, decoration: BoxDecoration(color: preset.accent, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Container(width: 14, height: 14, decoration: BoxDecoration(color: preset.bubbleOut, shape: BoxShape.circle)),
                                  const Spacer(),
                                  if (isSelected) Icon(Icons.check, size: 16, color: theme.accent),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preset.name,
                                style: TextStyle(color: preset.text, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Time Format (24h vs 12h)
                  Row(
                    children: [
                      const Text('Time Format', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const Spacer(),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: '24h', label: Text('24 Hour')),
                          ButtonSegment(value: '12h', label: Text('12 Hour')),
                        ],
                        selected: {ui.timeFormat},
                        onSelectionChanged: (val) => ui.setTimeFormat(val.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section: Sounds
                  _buildSectionHeader('Notifications & Sounds', theme),
                  const SizedBox(height: 8),
                  FutureBuilder<StorageService>(
                    future: StorageService.getInstance(),
                    builder: (context, snapshot) {
                      final storage = snapshot.data;
                      return Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('Play Telegram sound for messages', style: TextStyle(color: theme.muted, fontSize: 12)),
                            value: sound.isEnabled,
                            onChanged: storage != null
                                ? (val) {
                                    setState(() {
                                      sound.setEnabled(val, storage);
                                    });
                                  }
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.volume_up, size: 18),
                              label: const Text('Play Sample Tone'),
                              onPressed: () {
                                sound.playReceived();
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, dynamic theme) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: theme.accent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }
}
