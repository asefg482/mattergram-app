import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/ui_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/chat/chat_area.dart';
import '../widgets/chat/edit_channel_modal.dart';
import '../widgets/chat/hashtag_drawer.dart';
import '../widgets/chat/mention_user_modal.dart';
import '../widgets/chat/thread_view.dart';
import '../widgets/common/avatar_preview_modal.dart';
import '../widgets/common/notification_toast.dart';
import '../widgets/info/chat_info_drawer.dart';
import '../widgets/settings/account_settings_modal.dart';
import '../widgets/settings/settings_modal.dart';
import '../widgets/sidebar/new_chat_modal.dart';
import '../widgets/sidebar/sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String? _lastTeamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAppData();
    });
  }

  void _initAppData() {
    final chat = context.read<ChatProvider>();
    final users = context.read<UsersProvider>();
    final auth = context.read<AuthProvider>();

    chat.initWsListeners();
    users.initWs();

    if (auth.currentTeam != null) {
      _lastTeamId = auth.currentTeam!.id;
      chat.loadChannels();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final ui = context.watch<UiProvider>();
    final theme = ui.currentTheme;

    // Check if team changed
    if (auth.currentTeam != null && auth.currentTeam!.id != _lastTeamId) {
      _lastTeamId = auth.currentTeam!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chat.loadChannels();
      });
    }

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          // Main Chat Layout (Split screen for desktop/tablet, navigation for mobile)
          if (!isMobile)
            _buildDesktopLayout(theme, chat, ui)
          else
            _buildMobileLayout(theme, chat, ui),

          // Modals & Overlays Stack
          // 1. New Chat Modal
          if (ui.showNewChatModal)
            _buildModalBackdrop(
              onDismiss: () => ui.showNewChatModal = false,
              child: NewChatModal(onClose: () => ui.showNewChatModal = false),
            ),

          // 2. Settings Modal
          if (ui.showSettingsModal)
            _buildModalBackdrop(
              onDismiss: () => ui.showSettingsModal = false,
              child: SettingsModal(onClose: () => ui.showSettingsModal = false),
            ),

          // 3. Account Settings Modal
          if (ui.showAccountSettingsModal)
            _buildModalBackdrop(
              onDismiss: () => ui.showAccountSettingsModal = false,
              child: AccountSettingsModal(onClose: () => ui.showAccountSettingsModal = false),
            ),

          // 4. Edit Channel Modal
          if (ui.showEditChannelModal && ui.editChannelData != null)
            _buildModalBackdrop(
              onDismiss: () => ui.closeEditChannelModal(),
              child: EditChannelModal(
                channel: ui.editChannelData!,
                onClose: () => ui.closeEditChannelModal(),
              ),
            ),

          // 5. Mention User Modal
          if (ui.isMentionModalOpen && ui.mentionUser != null)
            _buildModalBackdrop(
              onDismiss: () => ui.closeMentionModal(),
              child: MentionUserModal(
                user: ui.mentionUser!,
                onClose: () => ui.closeMentionModal(),
              ),
            ),

          // 6. Fullscreen Avatar Preview Lightbox
          if (ui.isAvatarPreviewOpen)
            Positioned.fill(
              child: AvatarPreviewModal(
                url: ui.avatarPreviewUrl ?? '',
                name: ui.avatarPreviewName ?? '',
                onClose: () => ui.closeAvatarPreview(),
              ),
            ),

          // 7. Notification Toast Banner
          if (ui.toastMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Center(
                child: NotificationToast(
                  message: ui.toastMessage!,
                  title: ui.toastTitle,
                  isError: ui.isToastError,
                  onDismiss: () => ui.clearToast(),
                ),
              ),
            ),

          // 8. Global Logout Overlay
          if (auth.isLoggingOut)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    decoration: BoxDecoration(
                      color: theme.sidebar,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: theme.accent),
                        const SizedBox(height: 16),
                        Text(
                          'Logging out...',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(dynamic theme, ChatProvider chat, UiProvider ui) {
    return Row(
      children: [
        // Left Sidebar: Channels, DMs, Folder Tabs, Drawer Menu
        const SizedBox(
          width: 340,
          child: Sidebar(),
        ),

        // Vertical divider border
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: theme.border,
        ),

        // Center: Active Chat Conversation or Empty Placeholder
        const Expanded(
          child: ChatArea(onBack: null),
        ),

        // Right Collapsible Panels (ThreadView, ChatInfoDrawer, HashtagDrawer)
        if (chat.activeThreadRootPost != null) ...[
          VerticalDivider(width: 1, thickness: 1, color: theme.border),
          ThreadView(
            rootPost: chat.activeThreadRootPost!,
            onClose: () => chat.closeThread(),
          ),
        ] else if (ui.showRightSidebar && chat.activeChannel != null) ...[
          VerticalDivider(width: 1, thickness: 1, color: theme.border),
          ChatInfoDrawer(
            onClose: () => ui.toggleRightSidebar(false),
          ),
        ] else if (ui.showHashtagDrawer) ...[
          VerticalDivider(width: 1, thickness: 1, color: theme.border),
          HashtagDrawer(
            onClose: () => ui.closeHashtagDrawer(),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(dynamic theme, ChatProvider chat, UiProvider ui) {
    if (chat.activeChannel == null) {
      return const Sidebar();
    }

    return Stack(
      children: [
        // Active Chat Area with Back Button
        ChatArea(
          onBack: () => chat.selectChannel(null),
        ),

        // Right Drawers sliding over mobile view
        if (chat.activeThreadRootPost != null)
          Positioned.fill(
            child: ThreadView(
              rootPost: chat.activeThreadRootPost!,
              onClose: () => chat.closeThread(),
            ),
          )
        else if (ui.showRightSidebar)
          Positioned.fill(
            child: ChatInfoDrawer(
              onClose: () => ui.toggleRightSidebar(false),
            ),
          )
        else if (ui.showHashtagDrawer)
          Positioned.fill(
            child: HashtagDrawer(
              onClose: () => ui.closeHashtagDrawer(),
            ),
          ),
      ],
    );
  }

  Widget _buildModalBackdrop({required Widget child, required VoidCallback onDismiss}) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: () {}, // prevent tap from dismissing when tapping modal body
            child: child,
          ),
        ),
      ),
    );
  }
}
