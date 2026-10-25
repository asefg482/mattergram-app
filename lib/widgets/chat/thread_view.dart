import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import 'message_bubble.dart';
import 'message_input.dart';

class ThreadView extends StatelessWidget {
  final MattermostPost rootPost;
  final VoidCallback onClose;

  const ThreadView({
    super.key,
    required this.rootPost,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final chat = context.watch<ChatProvider>();
    final theme = ui.currentTheme;

    final replies = chat.threadPosts;

    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(left: BorderSide(color: theme.border, width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.sidebar,
              border: Border(bottom: BorderSide(color: theme.border, width: 1)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.muted),
                  onPressed: onClose,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thread',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: theme.muted),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: chat.loadingThread
                ? Center(child: CircularProgressIndicator(color: theme.accent))
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      // Root Post
                      MessageBubble(
                        post: rootPost,
                        isThreadView: true,
                      ),
                      const SizedBox(height: 8),
                      // Separator bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: theme.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${replies.length} ${replies.length == 1 ? "reply" : "replies"}',
                                style: TextStyle(
                                  color: theme.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: theme.border)),
                          ],
                        ),
                      ),
                      // Thread Replies List
                      ...replies.map((reply) => MessageBubble(
                            post: reply,
                            isThreadView: true,
                          )),
                    ],
                  ),
          ),

          // Thread Message Input
          MessageInput(
            channelId: rootPost.channelId,
            rootId: rootPost.id,
          ),
        ],
      ),
    );
  }
}
