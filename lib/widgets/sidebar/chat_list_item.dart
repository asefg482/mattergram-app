import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/channel.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../providers/users_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import '../common/telegram_avatar.dart';

class ChatListItem extends StatelessWidget {
  final MattermostChannel channel;
  final VoidCallback onTap;
  final void Function(Offset globalPosition)? onContextMenu;

  const ChatListItem({
    super.key,
    required this.channel,
    required this.onTap,
    this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final chat = context.watch<ChatProvider>();
    final users = context.watch<UsersProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = ui.currentTheme;

    final isSelected = chat.activeChannelId == channel.id;
    final unreadCount = chat.unreadCounts[channel.id] ?? 0;
    final typingNames = chat.getTypingUsernames(channel.id);
    final isTyping = typingNames.isNotEmpty;

    final otherUserId = channel.isDirect && channel.dmUser != null ? channel.dmUser!.id : null;
    final isOnline = otherUserId != null ? users.isUserOnline(otherUserId) : false;

    final lastPost = channel.lastPost;
    final myId = auth.currentUser?.id ?? '';
    final isLastPostMine = lastPost?.userId == myId;

    final timeStr = lastPost != null
        ? formatChatListTime(lastPost.createAt, use24Hour: ui.is24HourFormat)
        : (channel.lastPostAt > 0
            ? formatChatListTime(channel.lastPostAt, use24Hour: ui.is24HourFormat)
            : '');

    return GestureDetector(
      onSecondaryTapUp: (details) {
        onContextMenu?.call(details.globalPosition);
      },
      onLongPressStart: (details) {
        onContextMenu?.call(details.globalPosition);
      },
      child: Material(
        color: isSelected
            ? (theme.isDark ? const Color(0xFF2B5278) : const Color(0xFF3390EC))
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: theme.card.withValues(alpha: 0.5),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                TelegramAvatar(
                  userId: otherUserId,
                  name: channel.displayName.isNotEmpty ? channel.displayName : channel.name,
                  size: 50,
                  isOnline: isOnline,
                  showOnlineBadge: channel.isDirect && !channel.isSavedMessages,
                  isSavedMessages: channel.isSavedMessages,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Title + Time
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              channel.displayName.isNotEmpty ? channel.displayName : channel.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : theme.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (channel.isMuted) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.volume_off,
                              size: 14,
                              color: isSelected ? Colors.white70 : theme.muted,
                            ),
                          ],
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : theme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Bottom Row: Snippet + (Pinned / Unread Badge)
                      Row(
                        children: [
                          Expanded(
                            child: _buildSnippet(
                              isTyping: isTyping,
                              typingNames: typingNames,
                              lastPost: lastPost,
                              isLastPostMine: isLastPostMine,
                              isSelected: isSelected,
                              theme: theme,
                              users: users,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (channel.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.push_pin,
                                size: 16,
                                color: isSelected ? Colors.white70 : theme.muted,
                              ),
                            ),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: channel.isMuted
                                    ? (isSelected ? Colors.white38 : theme.muted)
                                    : (isSelected ? Colors.white : const Color(0xFF3390EC)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: TextStyle(
                                  color: channel.isMuted
                                      ? Colors.white
                                      : (isSelected ? theme.accent : Colors.white),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSnippet({
    required bool isTyping,
    required List<String> typingNames,
    required dynamic lastPost,
    required bool isLastPostMine,
    required bool isSelected,
    required dynamic theme,
    required UsersProvider users,
  }) {
    if (isTyping) {
      final name = typingNames.first;
      return Text(
        typingNames.length > 1 ? '$name and others typing...' : '$name is typing...',
        style: TextStyle(
          color: isSelected ? Colors.white : theme.accent,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (lastPost == null) {
      return Text(
        channel.purpose.isNotEmpty ? channel.purpose : 'No messages yet',
        style: TextStyle(
          color: isSelected ? Colors.white70 : theme.muted,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    String text = lastPost.message.replaceAll('\n', ' ').trim();
    if (text.isEmpty && lastPost.fileIds.isNotEmpty) {
      text = '[Attachment]';
    }

    return Row(
      children: [
        if (isLastPostMine) ...[
          Icon(
            Icons.done_all,
            size: 15,
            color: isSelected ? Colors.white : const Color(0xFF4FAE60),
          ),
          const SizedBox(width: 4),
        ],
        if (!channel.isDirect && !isLastPostMine) ...[
          Text(
            '${users.getUserDisplayName(lastPost.userId)}: ',
            style: TextStyle(
              color: isSelected ? Colors.white70 : theme.text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white70 : theme.muted,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
