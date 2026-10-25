import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../services/api_service.dart';
import '../common/telegram_avatar.dart';

class AddChannelMembersModal extends StatefulWidget {
  final String channelId;
  final VoidCallback onClose;

  const AddChannelMembersModal({
    super.key,
    required this.channelId,
    required this.onClose,
  });

  @override
  State<AddChannelMembersModal> createState() => _AddChannelMembersModalState();
}

class _AddChannelMembersModalState extends State<AddChannelMembersModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<MattermostUser> _users = [];
  bool _loading = false;
  final Set<String> _addedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers([String query = '']) async {
    final teamId = context.read<AuthProvider>().currentTeam?.id;
    setState(() => _loading = true);
    try {
      final list = await ApiService().getUsersNotInChannel(widget.channelId, teamId: teamId);
      final clean = query.trim().toLowerCase();
      final filtered = clean.isEmpty
          ? list
          : list.where((u) => u.displayName.toLowerCase().contains(clean) || u.username.toLowerCase().contains(clean)).toList();

      if (mounted) {
        setState(() {
          _users = filtered;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addUser(MattermostUser user) async {
    try {
      await ApiService().addChannelMember(widget.channelId, user.id);
      if (mounted) {
        setState(() {
          _addedUserIds.add(user.id);
        });
        context.read<ChatProvider>().fetchChannelMembers(widget.channelId);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<UiProvider>().currentTheme;

    return Dialog(
      backgroundColor: theme.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Add Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _loadUsers,
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: theme.accent))
                  : (_users.isEmpty
                      ? Center(child: Text('No users available to add', style: TextStyle(color: theme.muted)))
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final u = _users[index];
                            final isAdded = _addedUserIds.contains(u.id);

                            return ListTile(
                              leading: TelegramAvatar(userId: u.id, name: u.displayName, size: 40),
                              title: Text(u.displayName, style: TextStyle(color: theme.text, fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('@${u.username}', style: TextStyle(color: theme.muted, fontSize: 12)),
                              trailing: isAdded
                                  ? const Icon(Icons.check, color: Color(0xFF4FAE60))
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.accent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _addUser(u),
                                      child: const Text('Add'),
                                    ),
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
