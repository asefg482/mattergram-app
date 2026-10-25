import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_provider.dart';
import '../../providers/chat_provider.dart';

class FolderTabs extends StatelessWidget {
  const FolderTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final chat = context.watch<ChatProvider>();
    final theme = ui.currentTheme;

    final unreadChannels = chat.channels.where((c) => c.type != 'D' && (chat.unreadCounts[c.id] ?? 0) > 0).length;
    final unreadDirect = chat.channels.where((c) => c.type == 'D' && (chat.unreadCounts[c.id] ?? 0) > 0).length;
    final totalUnread = chat.unreadChatsCount;

    final tabs = [
      (tab: FolderTab.all, label: 'All Chats', count: totalUnread),
      (tab: FolderTab.channels, label: 'Channels', count: unreadChannels),
      (tab: FolderTab.direct, label: 'Direct Messages', count: unreadDirect),
      (tab: FolderTab.unread, label: 'Unread', count: totalUnread),
    ];

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: theme.sidebar,
        border: Border(bottom: BorderSide(color: theme.border, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final item = tabs[index];
          final isSelected = ui.activeTab == item.tab;

          return InkWell(
            onTap: () => ui.activeTab = item.tab,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? theme.accent : theme.muted,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (item.count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.accent : theme.card,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.count > 99 ? '99+' : '${item.count}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : theme.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isSelected)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: theme.accent,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
