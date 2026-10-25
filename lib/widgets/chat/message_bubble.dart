import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../providers/users_provider.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../utils/reactions.dart';
import '../common/telegram_avatar.dart';
import 'reaction_picker.dart';

class MessageBubble extends StatelessWidget {
  final MattermostPost post;
  final bool showAvatar;
  final bool showSenderName;
  final bool isThreadView;

  const MessageBubble({
    super.key,
    required this.post,
    this.showAvatar = true,
    this.showSenderName = true,
    this.isThreadView = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final users = context.watch<UsersProvider>();
    final ui = context.watch<UiProvider>();
    final theme = ui.currentTheme;

    final myId = auth.currentUser?.id ?? '';
    final isOutgoing = post.userId == myId;
    final sender = users.getUser(post.userId);
    final senderName = users.getUserDisplayName(post.userId);
    final isPending = post.id.startsWith('temp_');

    // Group reactions by emoji name
    final Map<String, List<MattermostReaction>> groupedReactions = {};
    for (final r in post.reactions) {
      groupedReactions.putIfAbsent(r.emojiName, () => []).add(r);
    }

    final bubbleBg = isOutgoing ? theme.bubbleOut : theme.bubbleIn;
    final textColor = isOutgoing && !theme.isDark ? const Color(0xFF111827) : theme.text;
    final timeColor = isOutgoing && !theme.isDark ? const Color(0xFF4FAE60) : theme.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOutgoing && showAvatar) ...[
            TelegramAvatar(
              userId: post.userId,
              name: senderName,
              size: 34,
              onTap: () {
                if (sender != null) ui.openMentionModal(sender);
              },
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onSecondaryTapUp: (details) => _showContextMenu(context, details.globalPosition),
              onLongPressStart: (details) => _showContextMenu(context, details.globalPosition),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
                    bottomRight: Radius.circular(isOutgoing ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender Name (in groups/channels for incoming messages)
                    if (!isOutgoing && showSenderName)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: GestureDetector(
                          onTap: () {
                            if (sender != null) ui.openMentionModal(sender);
                          },
                          child: Text(
                            senderName,
                            style: TextStyle(
                              color: getAvatarSingleColor(post.userId),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                    // Reply Quote preview
                    if (_hasReply(post)) _buildReplyQuote(context, post, theme),

                    // File Attachments (Images & Documents)
                    if (post.fileIds.isNotEmpty) ...[
                      _buildAttachments(context, post, isOutgoing),
                      const SizedBox(height: 6),
                    ],

                    // Message Text with Markdown
                    if (post.message.isNotEmpty)
                      MarkdownBody(
                        data: post.message,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: textColor, fontSize: 14.5, height: 1.35),
                          code: TextStyle(
                            backgroundColor: Colors.black.withValues(alpha: 0.1),
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onTapLink: (text, href, title) {
                          if (href != null) launchUrl(Uri.parse(href));
                        },
                      ),

                    const SizedBox(height: 4),

                    // Time, Read Status, Pin indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),
                        if (post.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin, size: 12, color: timeColor),
                          ),
                        Text(
                          formatMessageTime(post.createAt, use24Hour: ui.is24HourFormat),
                          style: TextStyle(color: timeColor, fontSize: 11),
                        ),
                        if (isOutgoing) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isPending ? Icons.access_time : Icons.done_all,
                            size: 14,
                            color: isPending ? timeColor : const Color(0xFF4FAE60),
                          ),
                        ],
                      ],
                    ),

                    // Emoji Reactions pills
                    if (groupedReactions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: groupedReactions.entries.map((entry) {
                          final emojiName = entry.key;
                          final list = entry.value;
                          final hasReacted = list.any((r) => r.userId == myId);

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (hasReacted) {
                                chat.removeReaction(post.id, emojiName);
                              } else {
                                chat.addReaction(post.id, emojiName);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: hasReacted
                                    ? theme.accent.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasReacted ? theme.accent : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    toEmojiChar(emojiName),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${list.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: hasReacted ? theme.accent : theme.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasReply(MattermostPost post) {
    return post.props['reply_to_text'] != null || post.rootId.isNotEmpty;
  }

  Widget _buildReplyQuote(BuildContext context, MattermostPost post, dynamic theme) {
    final replyUser = post.props['reply_to_user']?.toString() ?? 'Message';
    final replyText = post.props['reply_to_text']?.toString() ?? 'Attachment';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyUser,
            style: TextStyle(
              color: theme.accent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            replyText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments(BuildContext context, MattermostPost post, bool isOutgoing) {
    final token = ApiService().token;
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: post.fileIds.map((fileId) {
        final downloadUrl = ApiService().getFileDownloadUrl(fileId);
        final previewUrl = ApiService().getFilePreviewUrl(fileId);

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: const BoxConstraints(maxHeight: 260),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: CachedNetworkImage(
            imageUrl: previewUrl,
            httpHeaders: headers,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 180,
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) {
              // Fallback to document card
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Color(0xFF3390EC), size: 36),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Attachment File', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => launchUrl(Uri.parse(downloadUrl)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final ui = context.read<UiProvider>();
    final myId = auth.currentUser?.id ?? '';
    final isOutgoing = post.userId == myId;
    final canManage = isOutgoing || (auth.currentUser?.roles.contains('system_admin') ?? false);

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      color: isDark ? const Color(0xFF17212B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        // Quick reaction bar
        PopupMenuItem(
          enabled: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: defaultFrequentEmojis.take(6).map((emoji) {
              final emojiName = toEmojiName(emoji);
              return InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  chat.addReaction(post.id, emojiName);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'reply',
          child: Row(
            children: [
              Icon(Icons.reply, size: 20),
              SizedBox(width: 12),
              Text('Reply'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 20),
              SizedBox(width: 12),
              Text('Copy Text'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              const Icon(Icons.push_pin_outlined, size: 20),
              const SizedBox(width: 12),
              Text(post.isPinned ? 'Unpin' : 'Pin'),
            ],
          ),
        ),
        if (isOutgoing)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 20),
                SizedBox(width: 12),
                Text('Edit'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'reactions',
          child: Row(
            children: [
              Icon(Icons.add_reaction_outlined, size: 20),
              SizedBox(width: 12),
              Text('More Reactions'),
            ],
          ),
        ),
        if (canManage) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: Color(0xFFE53935)),
                SizedBox(width: 12),
                Text('Delete', style: TextStyle(color: Color(0xFFE53935))),
              ],
            ),
          ),
        ],
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'reply') {
      ui.replyingTo = post;
    } else if (value == 'copy') {
      Clipboard.setData(ClipboardData(text: post.message));
      ui.showToast('Text copied to clipboard');
    } else if (value == 'pin') {
      chat.togglePinPost(post);
    } else if (value == 'edit') {
      ui.editingPost = post;
    } else if (value == 'reactions') {
      showDialog(
        context: context,
        builder: (ctx) => Center(
          child: ReactionPicker(
            onSelectEmoji: (name) {
              Navigator.of(ctx).pop();
              chat.addReaction(post.id, name);
            },
          ),
        ),
      );
    } else if (value == 'delete') {
      chat.deleteMessage(post.id);
    }
  }
}
