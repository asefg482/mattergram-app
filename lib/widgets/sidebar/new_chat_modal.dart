import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../providers/users_provider.dart';
import '../../services/api_service.dart';
import '../common/telegram_avatar.dart';

class NewChatModal extends StatefulWidget {
  final VoidCallback onClose;

  const NewChatModal({super.key, required this.onClose});

  @override
  State<NewChatModal> createState() => _NewChatModalState();
}

class _NewChatModalState extends State<NewChatModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // DM search state
  final TextEditingController _searchCtrl = TextEditingController();
  List<MattermostUser> _users = [];
  bool _loadingUsers = false;

  // New channel state
  final TextEditingController _channelNameCtrl = TextEditingController();
  final TextEditingController _channelPurposeCtrl = TextEditingController();
  String _channelType = 'O'; // 'O' = Public, 'P' = Private
  bool _creatingChannel = false;
  String? _channelError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _channelNameCtrl.dispose();
    _channelPurposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUsers() async {
    final teamId = context.read<AuthProvider>().currentTeam?.id;
    final myId = context.read<AuthProvider>().currentUser?.id;
    if (teamId == null) return;
    setState(() => _loadingUsers = true);
    try {
      final teamUsers = await ApiService().getTeamUsers(teamId);
      if (mounted) {
        setState(() {
          _users = teamUsers.where((u) => u.id != myId).toList();
          _loadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _searchUsers(String term) async {
    final clean = term.trim().replaceAll(RegExp(r'^@'), '');
    if (clean.isEmpty) {
      _loadInitialUsers();
      return;
    }
    final teamId = context.read<AuthProvider>().currentTeam?.id;
    final myId = context.read<AuthProvider>().currentUser?.id;
    final usersProvider = context.read<UsersProvider>();
    setState(() => _loadingUsers = true);
    try {
      final results = await usersProvider.searchUsers(clean, teamId);
      if (mounted) {
        setState(() {
          _users = results.where((u) => u.id != myId).toList();
          _loadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _handleCreateChannel() async {
    final name = _channelNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _channelError = 'Channel name is required.');
      return;
    }

    final teamId = context.read<AuthProvider>().currentTeam?.id;
    if (teamId == null) return;

    setState(() {
      _creatingChannel = true;
      _channelError = null;
    });

    try {
      final created = await ApiService().createChannel(
        teamId,
        name,
        name,
        type: _channelType,
        purpose: _channelPurposeCtrl.text.trim(),
      );

      if (mounted) {
        final chat = context.read<ChatProvider>();
        chat.channels.insert(0, created);
        await chat.selectChannel(created.id);
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _channelError = e.toString();
          _creatingChannel = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<UiProvider>().currentTheme;

    return Dialog(
      backgroundColor: theme.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 580),
        child: Column(
          children: [
            // Header with tabs
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: Row(
                children: [
                  const Text(
                    'New Chat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: theme.accent,
              unselectedLabelColor: theme.muted,
              indicatorColor: theme.accent,
              tabs: const [
                Tab(text: 'Direct Message'),
                Tab(text: 'New Channel'),
              ],
            ),
            const Divider(height: 1),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDirectMessageTab(theme),
                  _buildNewChannelTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectMessageTab(dynamic theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _searchUsers,
            decoration: InputDecoration(
              hintText: 'Search people...',
              hintStyle: TextStyle(color: theme.muted, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: theme.muted),
              filled: true,
              fillColor: theme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: _loadingUsers
              ? Center(child: CircularProgressIndicator(color: theme.accent))
              : (_users.isEmpty
                  ? Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: theme.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isOnline = context.read<UsersProvider>().isUserOnline(user.id);

                        return ListTile(
                          leading: TelegramAvatar(
                            userId: user.id,
                            name: user.displayName,
                            size: 42,
                            isOnline: isOnline,
                            showOnlineBadge: true,
                          ),
                          title: Text(
                            user.displayName,
                            style: TextStyle(
                              color: theme.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            user.username.isNotEmpty ? '@${user.username}' : user.email,
                            style: TextStyle(color: theme.muted, fontSize: 13),
                          ),
                          onTap: () async {
                            final chat = context.read<ChatProvider>();
                            widget.onClose();
                            await chat.openDirectMessage(user.id);
                          },
                        );
                      },
                    )),
        ),
      ],
    );
  }

  Widget _buildNewChannelTab(dynamic theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _channelNameCtrl,
            decoration: InputDecoration(
              labelText: 'Channel Name',
              labelStyle: TextStyle(color: theme.muted),
              hintText: 'e.g. general, announcements',
              prefixIcon: const Icon(Icons.tag),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _channelPurposeCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: TextStyle(color: theme.muted),
              hintText: 'What is this channel about?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Channel Type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _channelType = 'O'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _channelType == 'O' ? theme.accent.withValues(alpha: 0.15) : theme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _channelType == 'O' ? theme.accent : theme.border,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.public, color: _channelType == 'O' ? theme.accent : theme.muted, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Public',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _channelType == 'O' ? theme.accent : theme.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Anyone on the team can join',
                          style: TextStyle(color: theme.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _channelType = 'P'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _channelType == 'P' ? theme.accent.withValues(alpha: 0.15) : theme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _channelType == 'P' ? theme.accent : theme.border,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_outline, color: _channelType == 'P' ? theme.accent : theme.muted, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Private',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _channelType == 'P' ? theme.accent : theme.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Only invited people can join',
                          style: TextStyle(color: theme.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_channelError != null) ...[
            const SizedBox(height: 12),
            Text(
              _channelError!,
              style: const TextStyle(color: Color(0xFFE53935), fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _creatingChannel ? null : _handleCreateChannel,
              child: _creatingChannel
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Channel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
