import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../providers/users_provider.dart';
import '../common/telegram_avatar.dart';
import '../common/custom_alert_dialog.dart';

class ChatHeader extends StatelessWidget {
  final VoidCallback? onBack;

  const ChatHeader({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final chat = context.watch<ChatProvider>();
    final users = context.watch<UsersProvider>();
    final theme = ui.currentTheme;

    final channel = chat.activeChannel;
    if (channel == null) return const SizedBox.shrink();

    final otherUserId = channel.isDirect && channel.dmUser != null ? channel.dmUser!.id : null;
    final isOnline = otherUserId != null ? users.isUserOnline(otherUserId) : false;

    final typingNames = chat.getTypingUsernames(channel.id);
    final isTyping = typingNames.isNotEmpty;

    String subtitle = '';
    if (isTyping) {
      final name = typingNames.first;
      subtitle = typingNames.length > 1 ? '$name and others are typing...' : '$name is typing...';
    } else if (channel.isSavedMessages) {
      subtitle = 'Your cloud storage';
    } else if (channel.isDirect) {
      subtitle = isOnline ? 'online' : 'offline';
    } else {
      final membersCount = chat.channelMembers[channel.id]?.length ?? 0;
      subtitle = membersCount > 0 ? '$membersCount members' : (channel.purpose.isNotEmpty ? channel.purpose : 'Channel');
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.sidebar,
        border: Border(bottom: BorderSide(color: theme.border, width: 1)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: Icon(Icons.arrow_back, color: theme.muted),
              onPressed: onBack,
              tooltip: 'Back',
            ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => ui.toggleRightSidebar(),
            borderRadius: BorderRadius.circular(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TelegramAvatar(
                  userId: otherUserId,
                  name: channel.displayName.isNotEmpty ? channel.displayName : channel.name,
                  size: 40,
                  isOnline: isOnline,
                  showOnlineBadge: channel.isDirect && !channel.isSavedMessages,
                  isSavedMessages: channel.isSavedMessages,
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.displayName.isNotEmpty ? channel.displayName : channel.name,
                      style: TextStyle(
                        color: theme.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isTyping ? theme.accent : (isOnline ? const Color(0xFF4FAE60) : theme.muted),
                        fontSize: 12,
                        fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search, color: theme.muted),
            onPressed: () => ui.openHashtag(''),
            tooltip: 'Search Messages',
          ),
          IconButton(
            icon: Icon(
              ui.showRightSidebar ? Icons.view_sidebar : Icons.view_sidebar_outlined,
              color: ui.showRightSidebar ? theme.accent : theme.muted,
            ),
            onPressed: () => ui.toggleRightSidebar(),
            tooltip: 'Chat Info',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.muted),
            color: theme.isDark ? const Color(0xFF17212B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) {
              final canManage = chat.canCurrentUserManageChannel(channel.id);
              return [
                PopupMenuItem(
                  value: 'mute',
                  child: Row(
                    children: [
                      Icon(channel.isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                          size: 20, color: theme.muted),
                      const SizedBox(width: 12),
                      Text(channel.isMuted ? 'Unmute' : 'Mute Notifications'),
                    ],
                  ),
                ),
                if (canManage)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: theme.muted),
                        const SizedBox(width: 12),
                        const Text('Edit Channel'),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      const Icon(Icons.exit_to_app, size: 20, color: Color(0xFFE53935)),
                      const SizedBox(width: 12),
                      Text(
                        channel.isDirect ? 'Delete Chat' : 'Leave Channel',
                        style: const TextStyle(color: Color(0xFFE53935)),
                      ),
                    ],
                  ),
                ),
              ];
            },
            onSelected: (value) async {
              if (value == 'mute') {
                chat.toggleMuteChannel(channel.id);
              } else if (value == 'edit') {
                ui.openEditChannel(channel);
              } else if (value == 'leave') {
                final confirmed = await showCustomConfirmDialog(
                  context,
                  title: channel.isDirect ? 'Delete Chat' : 'Leave Channel',
                  message: 'Are you sure you want to ${channel.isDirect ? 'delete this conversation' : 'leave ${channel.displayName}'}?',
                  confirmText: channel.isDirect ? 'Delete' : 'Leave',
                  isDestructive: true,
                );
                if (confirmed) {
                  await chat.leaveChannel(channel.id);
                  onBack?.call();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
