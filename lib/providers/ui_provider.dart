import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../utils/themes.dart';

enum FolderTab { all, channels, direct, unread }

class UiProvider with ChangeNotifier {
  StorageService? _storage;

  FolderTab _activeTab = FolderTab.all;
  String _searchQuery = '';

  String _themeId = 'classic-dark';
  bool _isDarkMode = true;
  String _animationId = 'smooth';
  String _timeFormat = '24h';
  String? _timezone;

  bool _showRightSidebar = false;
  bool _showHashtagDrawer = false;
  String? _activeHashtag;

  MattermostPost? _replyingTo;
  MattermostPost? _editingPost;
  MattermostFileInfo? _previewFile;

  // Avatar Lightbox Preview Modal
  String? _avatarPreviewUrl;
  String? _avatarPreviewName;
  String? _avatarPreviewUserId;

  // User Mention Modal
  bool _isMentionModalOpen = false;
  MattermostUser? _mentionUser;

  // Modals
  bool _showNewChatModal = false;
  bool _showSettingsModal = false;
  bool _showAccountSettingsModal = false;
  bool _showEditChannelModal = false;
  MattermostChannel? _editChannelData;

  // Notification Toast
  String? _toastMessage;
  String? _toastTitle;
  bool _isToastError = false;

  FolderTab get activeTab => _activeTab;
  String get searchQuery => _searchQuery;

  String get themeId => _themeId;
  bool get isDarkMode => _isDarkMode;
  ThemePreset get currentTheme => getThemeById(_themeId);
  String get animationId => _animationId;
  AnimationPreset get currentAnimation => getAnimationById(_animationId);
  String get timeFormat => _timeFormat;
  bool get is24HourFormat => _timeFormat == '24h';
  String? get timezone => _timezone;

  bool get showRightSidebar => _showRightSidebar;
  bool get showHashtagDrawer => _showHashtagDrawer;
  String? get activeHashtag => _activeHashtag;

  MattermostPost? get replyingTo => _replyingTo;
  MattermostPost? get editingPost => _editingPost;
  MattermostFileInfo? get previewFile => _previewFile;

  bool get isAvatarPreviewOpen => _avatarPreviewUrl != null;
  String? get avatarPreviewUrl => _avatarPreviewUrl;
  String? get avatarPreviewName => _avatarPreviewName;
  String? get avatarPreviewUserId => _avatarPreviewUserId;

  bool get isMentionModalOpen => _isMentionModalOpen;
  MattermostUser? get mentionUser => _mentionUser;

  bool get showNewChatModal => _showNewChatModal;
  bool get showSettingsModal => _showSettingsModal;
  bool get showAccountSettingsModal => _showAccountSettingsModal;
  bool get showEditChannelModal => _showEditChannelModal;
  MattermostChannel? get editChannelData => _editChannelData;

  String? get toastMessage => _toastMessage;
  String? get toastTitle => _toastTitle;
  bool get isToastError => _isToastError;

  void init(StorageService storage) {
    _storage = storage;
    _themeId = storage.getThemeId();
    _isDarkMode = storage.getIsDarkMode() ?? getThemeById(_themeId).isDark;
    _animationId = storage.getAnimationId();
    _timeFormat = storage.getTimeFormat();
    _timezone = storage.getTimezone();
  }

  set activeTab(FolderTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  set searchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTheme(String id) {
    _themeId = id;
    final preset = getThemeById(id);
    _isDarkMode = preset.isDark;
    _storage?.setThemeId(id);
    _storage?.setIsDarkMode(_isDarkMode);
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    // Auto-switch between classic-dark and classic-light if applicable
    if (_isDarkMode && _themeId == 'classic-light') {
      _themeId = 'classic-dark';
    } else if (!_isDarkMode && _themeId == 'classic-dark') {
      _themeId = 'classic-light';
    }
    _storage?.setIsDarkMode(_isDarkMode);
    _storage?.setThemeId(_themeId);
    notifyListeners();
  }

  void setAnimation(String id) {
    _animationId = id;
    _storage?.setAnimationId(id);
    notifyListeners();
  }

  void setTimeFormat(String format) {
    _timeFormat = format;
    _storage?.setTimeFormat(format);
    notifyListeners();
  }

  void setTimezone(String? tz) {
    _timezone = tz;
    _storage?.setTimezone(tz);
    notifyListeners();
  }

  set showRightSidebar(bool val) {
    _showRightSidebar = val;
    notifyListeners();
  }

  void toggleRightSidebar() {
    _showRightSidebar = !_showRightSidebar;
    notifyListeners();
  }

  void openHashtag(String tag) {
    _activeHashtag = tag;
    _showHashtagDrawer = true;
    _showRightSidebar = false;
    notifyListeners();
  }

  void closeHashtagDrawer() {
    _showHashtagDrawer = false;
    _activeHashtag = null;
    notifyListeners();
  }

  set replyingTo(MattermostPost? post) {
    _replyingTo = post;
    if (post != null) _editingPost = null;
    notifyListeners();
  }

  set editingPost(MattermostPost? post) {
    _editingPost = post;
    if (post != null) _replyingTo = null;
    notifyListeners();
  }

  void cancelReplyOrEdit() {
    _replyingTo = null;
    _editingPost = null;
    notifyListeners();
  }

  void openFilePreview(MattermostFileInfo file) {
    _previewFile = file;
    notifyListeners();
  }

  void closeFilePreview() {
    _previewFile = null;
    notifyListeners();
  }

  void openAvatarPreview(String url, String name, [String? userId]) {
    _avatarPreviewUrl = url;
    _avatarPreviewName = name;
    _avatarPreviewUserId = userId;
    notifyListeners();
  }

  void closeAvatarPreview() {
    _avatarPreviewUrl = null;
    _avatarPreviewName = null;
    _avatarPreviewUserId = null;
    notifyListeners();
  }

  void openMentionModal(MattermostUser user) {
    _mentionUser = user;
    _isMentionModalOpen = true;
    notifyListeners();
  }

  void closeMentionModal() {
    _isMentionModalOpen = false;
    _mentionUser = null;
    notifyListeners();
  }

  set showNewChatModal(bool val) {
    _showNewChatModal = val;
    notifyListeners();
  }

  set showSettingsModal(bool val) {
    _showSettingsModal = val;
    notifyListeners();
  }

  set showAccountSettingsModal(bool val) {
    _showAccountSettingsModal = val;
    notifyListeners();
  }

  void openEditChannel(MattermostChannel channel) {
    _editChannelData = channel;
    _showEditChannelModal = true;
    notifyListeners();
  }

  void closeEditChannel() {
    _showEditChannelModal = false;
    _editChannelData = null;
    notifyListeners();
  }

  void showToast(String message, {String? title, bool isError = false}) {
    _toastMessage = message;
    _toastTitle = title;
    _isToastError = isError;
    notifyListeners();

    Future.delayed(const Duration(seconds: 4), () {
      if (_toastMessage == message) {
        _toastMessage = null;
        _toastTitle = null;
        notifyListeners();
      }
    });
  }

  void dismissToast() {
    _toastMessage = null;
    _toastTitle = null;
    notifyListeners();
  }
}
