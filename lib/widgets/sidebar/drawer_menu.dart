import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../common/telegram_avatar.dart';
import '../common/custom_alert_dialog.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final ui = context.watch<UiProvider>();
    final theme = ui.currentTheme;
    final user = auth.currentUser;

    return Drawer(
      backgroundColor: theme.sidebar,
      child: Column(
        children: [
          // Header with user profile
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.accent, theme.accent.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TelegramAvatar(
                  userId: user?.id,
                  name: user?.displayName ?? 'User',
                  size: 64,
                  onTap: () {
                    Navigator.of(context).pop();
                    ui.showAccountSettingsModal = true;
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  user?.displayName ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user != null && user.username.isNotEmpty ? '@${user.username}' : user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.bookmark_outline,
                  title: 'Saved Messages',
                  onTap: () {
                    Navigator.of(context).pop();
                    if (user != null) {
                      final saved = chat.channels.firstWhere(
                        (c) => c.displayName == 'Saved Messages',
                        orElse: () => chat.channels.firstWhere(
                          (c) => c.name.contains('${user.id}__${user.id}'),
                          orElse: () => chat.channels.first,
                        ),
                      );
                      if (saved.displayName == 'Saved Messages') {
                        chat.selectChannel(saved.id);
                      } else {
                        chat.openDirectMessage(user.id);
                      }
                    }
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.tag,
                  title: 'New Channel',
                  onTap: () {
                    Navigator.of(context).pop();
                    ui.showNewChatModal = true;
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.group_outlined,
                  title: 'New Group',
                  onTap: () {
                    Navigator.of(context).pop();
                    ui.showNewChatModal = true;
                  },
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.of(context).pop();
                    ui.showSettingsModal = true;
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: ui.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                  title: ui.isDarkMode ? 'Day Mode' : 'Night Mode',
                  trailing: Switch(
                    value: ui.isDarkMode,
                    onChanged: (_) => ui.toggleDarkMode(),
                  ),
                  onTap: () => ui.toggleDarkMode(),
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  title: 'Log Out',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.of(context).pop();
                    final confirmed = await showCustomConfirmDialog(
                      context,
                      title: 'Log Out',
                      message: 'Are you sure you want to log out of Mattergram?',
                      confirmText: 'Log Out',
                      isDestructive: true,
                    );
                    if (confirmed) {
                      await auth.logout();
                    }
                  },
                ),
              ],
            ),
          ),

          // Footer version
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Mattergram Flutter v1.2.0',
              style: TextStyle(
                color: theme.muted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final theme = context.watch<UiProvider>().currentTheme;
    final color = isDestructive ? const Color(0xFFE53935) : theme.text;

    return ListTile(
      leading: Icon(icon, color: isDestructive ? const Color(0xFFE53935) : theme.muted, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
