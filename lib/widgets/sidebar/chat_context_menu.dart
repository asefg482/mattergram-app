import 'package:flutter/material.dart';
import '../../models/channel.dart';

void showChatContextMenu({
  required BuildContext context,
  required Offset position,
  required MattermostChannel channel,
  required bool isPinned,
  required bool isMuted,
  required bool isUnread,
  required VoidCallback onTogglePin,
  required VoidCallback onToggleMute,
  required VoidCallback onToggleRead,
  required VoidCallback onDelete,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

  showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(40, 40),
      Offset.zero & overlay.size,
    ),
    color: isDark ? const Color(0xFF17212B) : Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    items: [
      PopupMenuItem(
        value: 'pin',
        child: Row(
          children: [
            Icon(Icons.push_pin_outlined, size: 20, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 12),
            Text(isPinned ? 'Unpin from top' : 'Pin to top'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'mute',
        child: Row(
          children: [
            Icon(isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                size: 20, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 12),
            Text(isMuted ? 'Unmute notifications' : 'Mute notifications'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'read',
        child: Row(
          children: [
            Icon(isUnread ? Icons.done_all : Icons.mark_chat_unread_outlined,
                size: 20, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 12),
            Text(isUnread ? 'Mark as read' : 'Mark as unread'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            const Icon(Icons.delete_outline, size: 20, color: Color(0xFFE53935)),
            const SizedBox(width: 12),
            Text(
              channel.isDirect ? 'Delete chat' : 'Leave channel',
              style: const TextStyle(color: Color(0xFFE53935)),
            ),
          ],
        ),
      ),
    ],
  ).then((value) {
    if (value == 'pin') onTogglePin();
    if (value == 'mute') onToggleMute();
    if (value == 'read') onToggleRead();
    if (value == 'delete') onDelete();
  });
}
