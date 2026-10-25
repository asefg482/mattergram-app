import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../providers/users_provider.dart';
import '../../services/api_service.dart';
import '../../services/ws_service.dart';
import '../../utils/reactions.dart';
import '../common/telegram_avatar.dart';
import 'reaction_picker.dart';

class MessageInput extends StatefulWidget {
  final String channelId;
  final String rootId;

  const MessageInput({
    super.key,
    required this.channelId,
    this.rootId = '',
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isUploading = false;
  final List<String> _attachedFileIds = [];
  Timer? _typingThrottle;

  // Mention autocomplete
  bool _showMentions = false;
  List<MattermostUser> _mentionCandidates = [];

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingThrottle?.cancel();
    _textCtrl.removeListener(_onTextChanged);
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textCtrl.text;

    // Send typing event throttled
    if (_typingThrottle == null || !_typingThrottle!.isActive) {
      WsService().sendTyping(widget.channelId, widget.rootId);
      _typingThrottle = Timer(const Duration(seconds: 4), () {});
    }

    // Check mention trigger '@'
    final cursorPos = _textCtrl.selection.baseOffset;
    if (cursorPos > 0 && cursorPos <= text.length) {
      final textBeforeCursor = text.substring(0, cursorPos);
      final match = RegExp(r'@([a-zA-Z0-9._-]*)$').firstMatch(textBeforeCursor);
      if (match != null) {
        final query = match.group(1)?.toLowerCase() ?? '';
        _filterMentions(query);
        return;
      }
    }

    if (_showMentions) {
      setState(() => _showMentions = false);
    }
  }

  void _filterMentions(String query) {
    final chat = context.read<ChatProvider>();
    final users = context.read<UsersProvider>();
    final members = chat.channelMembers[widget.channelId] ?? [];
    final myId = context.read<AuthProvider>().currentUser?.id ?? '';

    final candidates = members
        .where((m) => m.userId != myId)
        .map((m) => users.getUser(m.userId))
        .whereType<MattermostUser>()
        .where((u) {
      return u.username.toLowerCase().contains(query) ||
          u.displayName.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _mentionCandidates = candidates;
      _showMentions = candidates.isNotEmpty;
    });
  }

  void _insertMention(MattermostUser user) {
    final text = _textCtrl.text;
    final cursorPos = _textCtrl.selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPos);
    final textAfterCursor = text.substring(cursorPos);

    final atIndex = textBeforeCursor.lastIndexOf('@');
    if (atIndex != -1) {
      final newText = '${textBeforeCursor.substring(0, atIndex)}@${user.username} $textAfterCursor';
      _textCtrl.text = newText;
      _textCtrl.selection = TextSelection.collapsed(offset: atIndex + user.username.length + 2);
    }

    setState(() => _showMentions = false);
    _focusNode.requestFocus();
  }

  Future<void> _pickAndUploadFiles() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final uploaded = await ApiService().uploadFile(
          widget.channelId,
          bytes,
          file.name,
        );
        _attachedFileIds.add(uploaded.id);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _handleSend() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _attachedFileIds.isEmpty) return;

    final chat = context.read<ChatProvider>();
    final ui = context.read<UiProvider>();

    if (ui.editingPost != null) {
      final postToEdit = ui.editingPost!;
      ui.cancelReplyOrEdit();
      _textCtrl.clear();
      await chat.editMessage(postToEdit.id, text);
      return;
    }

    final Map<String, dynamic> props = {};
    if (ui.replyingTo != null) {
      props['reply_to_id'] = ui.replyingTo!.id;
      props['reply_to_text'] = ui.replyingTo!.message;
      props['reply_to_user'] = context.read<UsersProvider>().getUserDisplayName(ui.replyingTo!.userId);
    }

    final fileIds = List<String>.from(_attachedFileIds);
    _attachedFileIds.clear();
    _textCtrl.clear();
    ui.cancelReplyOrEdit();

    await chat.sendMessage(
      widget.channelId,
      text,
      rootId: widget.rootId,
      fileIds: fileIds,
      props: props,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final theme = ui.currentTheme;

    // Synchronize edit text if editingPost changed
    if (ui.editingPost != null && _textCtrl.text.isEmpty) {
      _textCtrl.text = ui.editingPost!.message;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mention Candidate Autocomplete Popup
        if (_showMentions)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            color: theme.sidebar,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _mentionCandidates.length,
              itemBuilder: (context, index) {
                final u = _mentionCandidates[index];
                return ListTile(
                  dense: true,
                  leading: TelegramAvatar(userId: u.id, name: u.displayName, size: 28),
                  title: Text(u.displayName, style: TextStyle(color: theme.text, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('@${u.username}', style: TextStyle(color: theme.muted, fontSize: 11)),
                  onTap: () => _insertMention(u),
                );
              },
            ),
          ),

        // Reply / Edit Banner
        if (ui.replyingTo != null || ui.editingPost != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.sidebar,
              border: Border(top: BorderSide(color: theme.border, width: 1)),
            ),
            child: Row(
              children: [
                Icon(
                  ui.editingPost != null ? Icons.edit : Icons.reply,
                  color: theme.accent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ui.editingPost != null ? 'Edit Message' : 'Reply to Message',
                        style: TextStyle(
                          color: theme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ui.editingPost != null ? ui.editingPost!.message : ui.replyingTo!.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.muted, size: 18),
                  onPressed: () {
                    if (ui.editingPost != null) _textCtrl.clear();
                    ui.cancelReplyOrEdit();
                  },
                ),
              ],
            ),
          ),

        // Bottom Input Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: theme.sidebar,
            border: Border(top: BorderSide(color: theme.border, width: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              IconButton(
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.attach_file, color: theme.muted),
                onPressed: _isUploading ? null : _pickAndUploadFiles,
                tooltip: 'Attach Media or Document',
              ),

              // Text Field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    focusNode: _focusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(color: theme.text, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      hintStyle: TextStyle(color: theme.muted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),

              // Emoji Picker button
              IconButton(
                icon: Icon(Icons.sentiment_satisfied_alt, color: theme.muted),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => Center(
                      child: ReactionPicker(
                        onSelectEmoji: (name) {
                          Navigator.of(ctx).pop();
                          final char = toEmojiChar(name);
                          _textCtrl.text += char;
                        },
                      ),
                    ),
                  );
                },
                tooltip: 'Emojis',
              ),

              // Send button
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: theme.accent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _handleSend,
                  tooltip: 'Send',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
