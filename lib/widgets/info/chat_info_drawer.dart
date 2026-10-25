import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../providers/users_provider.dart';
import '../common/telegram_avatar.dart';
import '../common/custom_alert_dialog.dart';
import '../chat/add_channel_members_modal.dart';
import '../chat/edit_channel_modal.dart';
import '../chat/mention_user_modal.dart';

class ChatInfoDrawer extends StatelessWidget {
  final VoidCallback onClose;

  const ChatInfoDrawer({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final chat = context.watch<ChatProvider>();
    final users = context.watch<UsersProvider>();
    final theme = ui.currentTheme;

    final channel = chat.activeChannel;
    if (channel == null) return const SizedBox.shrink();

    final isDirect = channel.isDirect;
    final otherUserId = isDirect && channel.dmUser != null ? channel.dmUser!.id : null;
    final isOnline = otherUserId != null ? users.isUserOnline(otherUserId) : false;
    final canManage = chat.canCurrentUserManageChannel(channel.id);
    final canAdd = chat.canCurrentUserAddMembers(channel.id);

    final members = chat.channelMembers[channel.id] ?? [];

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: theme.sidebar,
        border: Border(left: BorderSide(color: theme.border, width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.border, width: 1)),
            ),
            child: Row(
              children: [
                const Text(
                  'Chat Info',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (canManage && !isDirect)
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: theme.muted),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => EditChannelModal(
                          channel: channel,
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      );
                    },
                    tooltip: 'Edit Channel',
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                // Large Avatar
                Center(
                  child: TelegramAvatar(
                    userId: otherUserId,
                    name: channel.displayName.isNotEmpty ? channel.displayName : channel.name,
                    size: 96,
                    isOnline: isOnline,
                    showOnlineBadge: isDirect && !channel.isSavedMessages,
                    isSavedMessages: channel.isSavedMessages,
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      channel.displayName.isNotEmpty ? channel.displayName : channel.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                Center(
                  child: Text(
                    isDirect
                        ? (channel.isSavedMessages ? 'Your cloud storage' : (isOnline ? 'online' : 'offline'))
                        : '${members.length} members',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDirect && isOnline ? const Color(0xFF4FAE60) : theme.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),

                // Purpose / Description
                if (channel.purpose.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.info_outline, color: theme.muted),
                    title: Text(channel.purpose, style: TextStyle(color: theme.text, fontSize: 14)),
                    subtitle: Text('Description', style: TextStyle(color: theme.muted, fontSize: 12)),
                  ),

                // Header / Guideline Links
                if (channel.header.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.link, color: theme.muted),
                    title: Text(channel.header, style: TextStyle(color: theme.text, fontSize: 14)),
                    subtitle: Text('Header', style: TextStyle(color: theme.muted, fontSize: 12)),
                  ),

                // Notifications Toggle
                ListTile(
                  leading: Icon(
                    channel.isMuted ? Icons.notifications_off_outlined : Icons.notifications_outlined,
                    color: theme.muted,
                  ),
                  title: const Text('Notifications', style: TextStyle(fontSize: 15)),
                  trailing: Switch(
                    value: !channel.isMuted,
                    onChanged: (_) => chat.toggleMuteChannel(channel.id),
                  ),
                  onTap: () => chat.toggleMuteChannel(channel.id),
                ),

                const Divider(),

                // Members Section (if not direct message)
                if (!isDirect) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.group_outlined, color: theme.muted, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${members.length} Members',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.muted,
                          ),
                        ),
                        const Spacer(),
                        if (canAdd)
                          TextButton.icon(
                            icon: const Icon(Icons.person_add_alt, size: 16),
                            label: const Text('Add'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AddChannelMembersModal(
                                  channelId: channel.id,
                                  onClose: () => Navigator.of(context).pop(),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  ...members.map((m) {
                    final user = users.getUser(m.userId);
                    final name = user != null ? user.displayName : m.userId;
                    final isMemberOnline = users.isUserOnline(m.userId);
                    final isOwner = channel.creatorId == m.userId;
                    final isAdmin = isOwner || m.schemeAdmin || m.roles.contains('channel_admin');

                    return ListTile(
                      leading: TelegramAvatar(
                        userId: m.userId,
                        name: name,
                        size: 38,
                        isOnline: isMemberOnline,
                        showOnlineBadge: true,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: theme.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        isMemberOnline ? 'online' : (user != null && user.username.isNotEmpty ? '@${user.username}' : ''),
                        style: TextStyle(
                          color: isMemberOnline ? const Color(0xFF4FAE60) : theme.muted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOwner ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : theme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isOwner ? 'Owner' : 'Admin',
                                style: TextStyle(
                                  color: isOwner ? const Color(0xFFF59E0B) : theme.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        if (user != null) {
                          showDialog(
                            context: context,
                            builder: (_) => MentionUserModal(
                              user: user,
                              onClose: () => Navigator.of(context).pop(),
                            ),
                          );
                        }
                      },
                    );
                  }),
                  const Divider(),
                ],

                // Leave / Delete Chat button
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
                  title: Text(
                    isDirect ? 'Delete Chat' : 'Leave Channel',
                    style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    final confirmed = await showCustomConfirmDialog(
                      context,
                      title: isDirect ? 'Delete Chat' : 'Leave Channel',
                      message: 'Are you sure you want to ${isDirect ? 'delete this conversation' : 'leave ${channel.displayName}'}?',
                      confirmText: isDirect ? 'Delete' : 'Leave',
                      isDestructive: true,
                    );
                    if (confirmed) {
                      await chat.leaveChannel(channel.id);
                      onClose();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
