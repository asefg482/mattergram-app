import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../common/telegram_avatar.dart';

class MentionUserModal extends StatelessWidget {
  final MattermostUser user;
  final VoidCallback onClose;

  const MentionUserModal({
    super.key,
    required this.user,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final theme = ui.currentTheme;

    return Dialog(
      backgroundColor: theme.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TelegramAvatar(
                userId: user.id,
                name: user.displayName,
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
                textAlign: TextAlign.center,
              ),
              if (user.username.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: TextStyle(fontSize: 14, color: theme.muted),
                ),
              ],
              if (user.position.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  user.position,
                  style: TextStyle(fontSize: 13, color: theme.accent, fontWeight: FontWeight.w500),
                ),
              ],
              if (user.email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12, color: theme.muted),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send Message', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final chat = context.read<ChatProvider>();
                    onClose();
                    chat.openDirectMessage(user.id);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
