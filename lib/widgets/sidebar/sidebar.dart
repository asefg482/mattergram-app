import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/channel.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import 'folder_tabs.dart';
import 'chat_list_item.dart';
import 'chat_context_menu.dart';
import 'drawer_menu.dart';
import 'new_chat_modal.dart';

class Sidebar extends StatefulWidget {
  final void Function(MattermostChannel channel)? onChannelSelected;

  const Sidebar({super.key, this.onChannelSelected});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final chat = context.watch<ChatProvider>();
    final theme = ui.currentTheme;

    // Filter channels based on activeTab and searchQuery
    final query = ui.searchQuery.trim().toLowerCase();
    List<MattermostChannel> displayedChannels = chat.channels;

    if (query.isNotEmpty) {
      final cleanQ = query.replaceAll(RegExp(r'^@'), '');
      displayedChannels = displayedChannels.where((c) {
        final matchName = c.name.toLowerCase().contains(cleanQ);
        final matchDisplay = c.displayName.toLowerCase().contains(cleanQ);
        final matchPurpose = c.purpose.toLowerCase().contains(cleanQ);
        final matchUser = c.dmUser != null &&
            (c.dmUser!.username.toLowerCase().contains(cleanQ) ||
                c.dmUser!.displayName.toLowerCase().contains(cleanQ));
        return matchName || matchDisplay || matchPurpose || matchUser;
      }).toList();
    } else {
      switch (ui.activeTab) {
        case FolderTab.channels:
          displayedChannels = displayedChannels.where((c) => c.type != 'D').toList();
          break;
        case FolderTab.direct:
          displayedChannels = displayedChannels.where((c) => c.type == 'D').toList();
          break;
        case FolderTab.unread:
          displayedChannels = displayedChannels.where((c) => (chat.unreadCounts[c.id] ?? 0) > 0).toList();
          break;
        case FolderTab.all:
          break;
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const DrawerMenu(),
      backgroundColor: theme.sidebar,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Hamburger + Search + New Chat button
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: theme.muted),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    tooltip: 'Menu',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => ui.searchQuery = val,
                        style: TextStyle(color: theme.text, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: theme.muted, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: theme.muted, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close, color: theme.muted, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    ui.searchQuery = '';
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(top: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: theme.muted),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => NewChatModal(
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      );
                    },
                    tooltip: 'New Chat',
                  ),
                ],
              ),
            ),

            // Telegram Folder Tabs (All, Channels, Direct, Unread)
            if (query.isEmpty) const FolderTabs(),

            // Chat List
            Expanded(
              child: chat.loadingChannels && chat.channels.isEmpty
                  ? Center(child: CircularProgressIndicator(color: theme.accent))
                  : (displayedChannels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: theme.muted.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                query.isNotEmpty ? 'No chats found' : 'No chats yet',
                                style: TextStyle(color: theme.muted, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: displayedChannels.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 74,
                            color: theme.border.withValues(alpha: 0.5),
                          ),
                          itemBuilder: (context, index) {
                            final ch = displayedChannels[index];
                            final isPinned = ch.isPinned;
                            final isMuted = ch.isMuted;
                            final isUnread = (chat.unreadCounts[ch.id] ?? 0) > 0;

                            return ChatListItem(
                              channel: ch,
                              onTap: () {
                                chat.selectChannel(ch.id);
                                widget.onChannelSelected?.call(ch);
                              },
                              onContextMenu: (pos) {
                                showChatContextMenu(
                                  context: context,
                                  position: pos,
                                  channel: ch,
                                  isPinned: isPinned,
                                  isMuted: isMuted,
                                  isUnread: isUnread,
                                  onTogglePin: () => chat.togglePinChannel(ch.id),
                                  onToggleMute: () => chat.toggleMuteChannel(ch.id),
                                  onToggleRead: () => chat.toggleMarkAsUnread(ch.id),
                                  onDelete: () => chat.leaveChannel(ch.id),
                                );
                              },
                            );
                          },
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
