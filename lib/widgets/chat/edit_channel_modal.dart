import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/channel.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../services/api_service.dart';

class EditChannelModal extends StatefulWidget {
  final MattermostChannel channel;
  final VoidCallback onClose;

  const EditChannelModal({
    super.key,
    required this.channel,
    required this.onClose,
  });

  @override
  State<EditChannelModal> createState() => _EditChannelModalState();
}

class _EditChannelModalState extends State<EditChannelModal> {
  late TextEditingController _nameCtrl;
  late TextEditingController _purposeCtrl;
  late TextEditingController _headerCtrl;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.channel.displayName);
    _purposeCtrl = TextEditingController(text: widget.channel.purpose);
    _headerCtrl = TextEditingController(text: widget.channel.header);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _purposeCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Channel name is required.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final patch = {
        'display_name': name,
        'purpose': _purposeCtrl.text.trim(),
        'header': _headerCtrl.text.trim(),
      };
      final updated = await ApiService().patchChannel(widget.channel.id, patch);

      if (mounted) {
        context.read<ChatProvider>().updateChannelInList(updated);
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSaving = false;
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Edit Channel',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Channel Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _purposeCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Purpose',
                  hintText: 'What is this channel about?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _headerCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Header',
                  hintText: 'Channel header links or guidelines',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFE53935), fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
