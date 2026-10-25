import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../utils/formatters.dart';
import 'chat_header.dart';
import 'message_bubble.dart';
import 'message_input.dart';

class ChatArea extends StatefulWidget {
  final VoidCallback? onBack;

  const ChatArea({super.key, this.onBack});

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _showScrollBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.hasClients) {
      final isUp = _scrollCtrl.offset > 300;
      if (isUp != _showScrollBottom) {
        setState(() => _showScrollBottom = isUp);
      }

      // Check if user reached near top of list (which is maxScrollExtent since list is reversed)
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        final chat = context.read<ChatProvider>();
        if (chat.activeChannelId != null) {
          chat.loadOlderPosts(chat.activeChannelId!);
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final chat = context.watch<ChatProvider>();
    final theme = ui.currentTheme;

    final channel = chat.activeChannel;
    if (channel == null) {
      return Container(
        color: theme.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: theme.muted.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'Select a chat to start messaging',
                style: TextStyle(color: theme.muted, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final posts = chat.currentPosts;
    final reversedPosts = posts.reversed.toList();

    return Container(
      color: theme.bg,
      child: Column(
        children: [
          // Header
          ChatHeader(onBack: widget.onBack),

          // Messages List with Telegram Doodle Wallpaper
          Expanded(
            child: Stack(
              children: [
                // Telegram Background Wallpaper Pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: TelegramWallpaperPainter(
                      color: theme.isDark ? Colors.white : Colors.black,
                      opacity: theme.isDark ? 0.03 : 0.05,
                    ),
                  ),
                ),

                // Messages or Loading indicator
                if (chat.loadingPosts && posts.isEmpty)
                  Center(child: CircularProgressIndicator(color: theme.accent))
                else if (posts.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'No messages here yet...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true, // Telegram chats start at bottom (index 0)
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: reversedPosts.length + (chat.loadingOlderPosts ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (chat.loadingOlderPosts && index == reversedPosts.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.accent,
                              ),
                            ),
                          ),
                        );
                      }

                      final post = reversedPosts[index];
                      // In reversed list, the older post is at index + 1
                      final nextOlderPost = (index + 1 < reversedPosts.length) ? reversedPosts[index + 1] : null;
                      final showDateSeparator = isDifferentDay(post.createAt, nextOlderPost?.createAt);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showDateSeparator)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                formatDateSeparator(post.createAt),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          MessageBubble(
                            post: post,
                            showAvatar: channel.type != 'D',
                            showSenderName: channel.type != 'D',
                          ),
                        ],
                      );
                    },
                  ),

                // Scroll to Bottom FAB
                if (_showScrollBottom)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      backgroundColor: theme.sidebar,
                      foregroundColor: theme.muted,
                      elevation: 4,
                      onPressed: _scrollToBottom,
                      child: const Icon(Icons.arrow_downward, size: 20),
                    ),
                  ),
              ],
            ),
          ),

          // Message Input Bar
          MessageInput(channelId: channel.id),
        ],
      ),
    );
  }
}

class TelegramWallpaperPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const TelegramWallpaperPainter({
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
