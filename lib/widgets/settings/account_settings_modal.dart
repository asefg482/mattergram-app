import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ui_provider.dart';
import '../common/telegram_avatar.dart';

class AccountSettingsModal extends StatefulWidget {
  final VoidCallback onClose;

  const AccountSettingsModal({super.key, required this.onClose});

  @override
  State<AccountSettingsModal> createState() => _AccountSettingsModalState();
}

class _AccountSettingsModalState extends State<AccountSettingsModal> {
  late TextEditingController _firstCtrl;
  late TextEditingController _lastCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _nicknameCtrl;
  late TextEditingController _positionCtrl;

  // Password section
  bool _showPasswordSection = false;
  final TextEditingController _currentPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _error;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _firstCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastCtrl = TextEditingController(text: user?.lastName ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _nicknameCtrl = TextEditingController(text: user?.nickname ?? '');
    _positionCtrl = TextEditingController(text: user?.position ?? '');
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _nicknameCtrl.dispose();
    _positionCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUploadPhoto() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final file = files.first;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      await context.read<AuthProvider>().updateProfileImage(bytes, file.name);
      if (mounted) {
        context.read<UiProvider>().showToast('Profile photo updated successfully');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _handleRemovePhoto() async {
    setState(() => _isUploadingPhoto = true);
    try {
      await context.read<AuthProvider>().deleteProfileImage();
      if (mounted) {
        context.read<UiProvider>().showToast('Profile photo removed');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _handleSaveProfile() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.updateCurrentUser({
        'first_name': _firstCtrl.text.trim(),
        'last_name': _lastCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'nickname': _nicknameCtrl.text.trim(),
        'position': _positionCtrl.text.trim(),
      });

      // Handle password update if fields are filled
      if (_showPasswordSection && _currentPassCtrl.text.isNotEmpty && _newPassCtrl.text.isNotEmpty) {
        if (_newPassCtrl.text != _confirmPassCtrl.text) {
          setState(() {
            _passwordError = 'New passwords do not match';
            _isSaving = false;
          });
          return;
        }
        await auth.updatePassword(_currentPassCtrl.text, _newPassCtrl.text);
      }

      if (mounted) {
        context.read<UiProvider>().showToast('Account settings saved');
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
    final ui = context.watch<UiProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = ui.currentTheme;
    final user = auth.currentUser;

    return Dialog(
      backgroundColor: theme.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Photo action
                  Center(
                    child: Stack(
                      children: [
                        TelegramAvatar(
                          userId: user?.id,
                          name: user?.displayName ?? 'User',
                          size: 80,
                        ),
                        if (_isUploadingPhoto)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                              child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text('Change Photo'),
                        onPressed: _isUploadingPhoto ? null : _handleUploadPhoto,
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFE53935)),
                        label: const Text('Remove', style: TextStyle(color: Color(0xFFE53935))),
                        onPressed: _isUploadingPhoto ? null : _handleRemovePhoto,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstCtrl,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lastCtrl,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _usernameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _nicknameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nickname',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _positionCtrl,
                    decoration: InputDecoration(
                      labelText: 'Position / Role',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Password Toggle
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    trailing: Icon(_showPasswordSection ? Icons.expand_less : Icons.expand_more),
                    onTap: () => setState(() => _showPasswordSection = !_showPasswordSection),
                  ),

                  if (_showPasswordSection) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _currentPassCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newPassCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirmPassCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 8),
                      Text(_passwordError!, style: const TextStyle(color: Color(0xFFE53935), fontSize: 12)),
                    ],
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Color(0xFFE53935), fontSize: 13)),
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
                      onPressed: _isSaving ? null : _handleSaveProfile,
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
