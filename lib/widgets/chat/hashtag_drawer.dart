import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../providers/users_provider.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';

class HashtagDrawer extends StatefulWidget {
  final VoidCallback onClose;

  const HashtagDrawer({super.key, required this.onClose});

  @override
  State<HashtagDrawer> createState() => _HashtagDrawerState();
}

class _HashtagDrawerState extends State<HashtagDrawer> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _scope = 'chat'; // 'chat' or 'team'
  bool _loading = false;
  List<MattermostPost> _results = [];

  @override
  void initState() {
    super.initState();
    final tag = context.read<UiProvider>().activeHashtag ?? '';
    _searchCtrl.text = tag;
    if (tag.isNotEmpty) {
      _executeSearch(tag);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _executeSearch(String term) async {
    final query = term.trim();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);
    final chat = context.read<ChatProvider>();
    final auth = context.read<AuthProvider>();

    try {
      if (_scope == 'chat' && chat.activeChannelId != null) {
        // Search in active channel posts
        final allPosts = chat.currentPosts;
        final cleanQ = query.replaceAll(RegExp(r'^#'), '').toLowerCase();
        final matched = allPosts.where((p) {
          return p.message.toLowerCase().contains(cleanQ) ||
              p.hashtags.toLowerCase().contains(cleanQ);
        }).toList();

        setState(() {
          _results = matched;
          _loading = false;
        });
      } else {
        // Team wide search
        final teamId = auth.currentTeam?.id;
        if (teamId != null) {
          final res = await ApiService().searchTeamPosts(teamId, query);
          final list = res.order.map((id) => res.posts[id]).whereType<MattermostPost>().toList();
          setState(() {
            _results = list;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final users = context.watch<UsersProvider>();
    final theme = ui.currentTheme;

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
                const Icon(Icons.tag, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Search Messages',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: _executeSearch,
              decoration: InputDecoration(
                hintText: 'Search tag or keyword...',
                prefixIcon: const Icon(Icons.search),
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

          // Scope selector pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('This Chat'),
                  selected: _scope == 'chat',
                  selectedColor: theme.accent.withValues(alpha: 0.2),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _scope = 'chat');
                      _executeSearch(_searchCtrl.text);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All Chats'),
                  selected: _scope == 'team',
                  selectedColor: theme.accent.withValues(alpha: 0.2),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _scope = 'team');
                      _executeSearch(_searchCtrl.text);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // Results
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: theme.accent))
                : (_results.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty ? 'Type to search' : 'No results found',
                          style: TextStyle(color: theme.muted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: theme.border),
                        itemBuilder: (context, index) {
                          final post = _results[index];
                          final senderName = users.getUserDisplayName(post.userId);

                          return ListTile(
                            title: Row(
                              children: [
                                Text(
                                  senderName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.text,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  formatMessageTime(post.createAt, use24Hour: ui.is24HourFormat),
                                  style: TextStyle(color: theme.muted, fontSize: 11),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                post.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: theme.muted, fontSize: 13),
                              ),
                            ),
                            onTap: () {
                              final chat = context.read<ChatProvider>();
                              chat.selectChannel(post.channelId);
                              widget.onClose();
                            },
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }
}
