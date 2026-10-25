import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ui_provider.dart';
import '../../services/api_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Mode: 'login' or 'register'
  String _authMode = 'login';
  bool _canSignUp = false;
  int _passwordMinLength = 8;
  String _siteName = 'Mattermost';
  String _customDescription = 'Mattermost client with Telegram UI/UX';
  String? _brandImageUrl;

  // Controllers
  final _serverUrlCtrl = TextEditingController();
  final _loginIdCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  final _regEmailCtrl = TextEditingController();
  final _regUsernameCtrl = TextEditingController();
  final _regFullNameCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();

  bool _showPassword = false;
  bool _showRegPassword = false;
  bool _isLoading = false;
  bool _isTestingConnection = false;
  bool? _isServerReachable;
  String? _errorMessage;
  bool _showServerSettings = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _serverUrlCtrl.text = auth.baseUrl;
    _checkServerConfig();
  }

  @override
  void dispose() {
    _serverUrlCtrl.dispose();
    _loginIdCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regEmailCtrl.dispose();
    _regUsernameCtrl.dispose();
    _regFullNameCtrl.dispose();
    _regPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkServerConfig() async {
    final url = _serverUrlCtrl.text.trim();
    if (url.isEmpty) return;

    setState(() => _isTestingConnection = true);
    final api = ApiService();
    try {
      final reachable = await api.pingServer(url);
      if (!mounted) return;
      setState(() => _isServerReachable = reachable);

      if (reachable) {
        final cfg = await api.getClientConfig(url);
        if (!mounted) return;

        final isNoAccounts = cfg['NoAccounts'] == 'true';
        final isOpenServer = cfg['EnableOpenServer'] == 'true';
        final isSignUpWithEmail = cfg['EnableSignUpWithEmail'] == 'true';
        final isUserCreation = cfg['EnableUserCreation'] != 'false';
        final allowed = isNoAccounts || (isOpenServer && isSignUpWithEmail && isUserCreation);

        setState(() {
          if (cfg['SiteName'] != null && (cfg['SiteName'] as String).isNotEmpty) {
            _siteName = cfg['SiteName'];
          }
          if (cfg['CustomDescriptionText'] != null) {
            _customDescription = cfg['CustomDescriptionText'];
          }
          if (cfg['PasswordMinimumLength'] != null) {
            _passwordMinLength = int.tryParse(cfg['PasswordMinimumLength'].toString()) ?? 8;
          }
          _canSignUp = allowed;
          if (!allowed && _authMode == 'register') {
            _authMode = 'login';
          }
          _brandImageUrl = '$url/api/v4/brand/image';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isServerReachable = false);
    } finally {
      if (mounted) setState(() => _isTestingConnection = false);
    }
  }

  Future<void> _handleLogin() async {
    final serverUrl = _serverUrlCtrl.text.trim();
    final loginId = _loginIdCtrl.text.trim();
    final password = _loginPasswordCtrl.text;

    if (serverUrl.isEmpty) {
      setState(() => _errorMessage = 'Please specify the Mattermost Server URL.');
      return;
    }
    if (loginId.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both login ID and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    auth.setBaseUrl(serverUrl);

    try {
      await auth.login(loginId, password);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final serverUrl = _serverUrlCtrl.text.trim();
    final email = _regEmailCtrl.text.trim().toLowerCase();
    final username = _regUsernameCtrl.text.trim().toLowerCase();
    final password = _regPasswordCtrl.text;
    final fullName = _regFullNameCtrl.text.trim();

    if (serverUrl.isEmpty) {
      setState(() => _errorMessage = 'Please specify the Mattermost Server URL.');
      return;
    }
    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields (Email, Username, Password).');
      return;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    final usernameRegex = RegExp(r'^[a-z][a-z0-9.\-_]{2,21}$');
    if (!usernameRegex.hasMatch(username)) {
      setState(() => _errorMessage = 'Username must be 3-22 lowercase alphanumeric characters.');
      return;
    }

    if (password.length < _passwordMinLength) {
      setState(() => _errorMessage = 'Password must be at least $_passwordMinLength characters long.');
      return;
    }

    String firstName = '';
    String lastName = '';
    if (fullName.isNotEmpty) {
      final parts = fullName.split(RegExp(r'\s+'));
      firstName = parts.first;
      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    auth.setBaseUrl(serverUrl);

    try {
      await auth.register({
        'email': email,
        'username': username,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final isDark = ui.isDarkMode;
    final theme = ui.currentTheme;

    final bgColor = isDark ? const Color(0xFF0E1621) : const Color(0xFFE4ECF2);
    final cardColor = isDark ? const Color(0xFF17212B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF202B36) : const Color(0xFFDFE1E5);
    final textMuted = const Color(0xFF7F91A4);
    final inputBg = isDark ? const Color(0xFF0E1621) : const Color(0xFFF4F4F5);

    String hostDisplay = 'Mattermost Server';
    try {
      final u = Uri.parse(_serverUrlCtrl.text);
      if (u.host.isNotEmpty) {
        hostDisplay = u.host;
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Subtle dot background
          Positioned.fill(
            child: CustomPaint(
              painter: _DotBackgroundPainter(
                dotColor: isDark ? const Color(0x15FFFFFF) : const Color(0x152481CC),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo & Header Branding
                      _buildBrandingHeader(isDark, theme),
                      const SizedBox(height: 24),

                      // Auth Card
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Segmented Switcher (if registration allowed)
                            if (_canSignUp) ...[
                              _buildSegmentedSwitcher(isDark, borderColor),
                              const SizedBox(height: 20),
                            ],

                            // Error Banner
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Form: Login or Register
                            if (_authMode == 'login' || !_canSignUp)
                              _buildLoginForm(inputBg, borderColor, textMuted)
                            else
                              _buildRegisterForm(inputBg, borderColor, textMuted),

                            const SizedBox(height: 16),

                            // Server Configuration Dropdown / Status
                            _buildServerConfigRow(isDark, borderColor, textMuted, hostDisplay),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer GitHub Star and Protocol Info
                      _buildFooter(cardColor, borderColor, textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingHeader(bool isDark, dynamic theme) {
    return Column(
      children: [
        if (_brandImageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              _brandImageUrl!,
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildDefaultLogo(),
            ),
          )
        else
          _buildDefaultLogo(),
        const SizedBox(height: 14),
        Text(
          _siteName,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _customDescription,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7F91A4),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C58D9), Color(0xFF0058CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C58D9).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.forum_rounded, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildSegmentedSwitcher(bool isDark, Color borderColor) {
    final activeBg = isDark ? const Color(0xFF242F3D) : Colors.white;
    final inactiveText = const Color(0xFF7F91A4);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1621).withValues(alpha: 0.6) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _authMode = 'login';
                _errorMessage = null;
              }),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _authMode == 'login' ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _authMode == 'login'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login_rounded,
                      size: 16,
                      color: _authMode == 'login' ? const Color(0xFF3390EC) : inactiveText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _authMode == 'login' ? (_canSignUp ? null : Colors.white) : inactiveText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _authMode = 'register';
                _errorMessage = null;
              }),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _authMode == 'register' ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _authMode == 'register'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      size: 16,
                      color: _authMode == 'register' ? const Color(0xFF3390EC) : inactiveText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _authMode == 'register' ? null : inactiveText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(Color inputBg, Color borderColor, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Username / Email
        _buildInputField(
          controller: _loginIdCtrl,
          label: 'Username or Email',
          icon: Icons.email_outlined,
          hint: 'e.g. username or user@domain.com',
          inputBg: inputBg,
          borderColor: borderColor,
          textMuted: textMuted,
        ),
        const SizedBox(height: 14),

        // Password
        _buildInputField(
          controller: _loginPasswordCtrl,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          hint: '••••••••••••',
          inputBg: inputBg,
          borderColor: borderColor,
          textMuted: textMuted,
          obscureText: !_showPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: textMuted,
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 20),

        // Submit Button
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2481CC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            shadowColor: const Color(0xFF2481CC).withValues(alpha: 0.35),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'LOG IN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                ),
        ),

        if (_canSignUp) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account? ", style: TextStyle(color: textMuted, fontSize: 13)),
              GestureDetector(
                onTap: () => setState(() {
                  _authMode = 'register';
                  _errorMessage = null;
                }),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(color: Color(0xFF3390EC), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterForm(Color inputBg, Color borderColor, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _regEmailCtrl,
          label: 'Email Address *',
          icon: Icons.alternate_email_rounded,
          hint: 'user@example.com',
          inputBg: inputBg,
          borderColor: borderColor,
          textMuted: textMuted,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),

        _buildInputField(
          controller: _regUsernameCtrl,
          label: 'Username * (3-22 chars)',
          icon: Icons.person_outline_rounded,
          hint: 'e.g. johndoe',
          inputBg: inputBg,
          borderColor: borderColor,
          textMuted: textMuted,
        ),
        const SizedBox(height: 12),

        _buildInputField(
          controller: _regFullNameCtrl,
          label: 'Full Name (Optional)',
          icon: Icons.badge_outlined,
          hint: 'e.g. John Doe',
          inputBg: inputBg,
          borderColor: borderColor,
          textMuted: textMuted,
        ),
        const SizedBox(height: 12),

        _buildInputField(
          controller: _regPasswordCtrl,
          label: 'Password * (Min $_passwordMinLength chars)',
          icon: Icons.lock_outline_rounded,
          hint: '••••••••••••',
          inputBg: inputBg,
          borderColor: borderColor,
          textMuted: textMuted,
          obscureText: !_showRegPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _showRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: textMuted,
            ),
            onPressed: () => setState(() => _showRegPassword = !_showRegPassword),
          ),
          onSubmitted: (_) => _handleRegister(),
        ),
        const SizedBox(height: 18),

        // Submit Button
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3390EC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            shadowColor: const Color(0xFF3390EC).withValues(alpha: 0.35),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'CREATE ACCOUNT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                ),
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already have an account? ', style: TextStyle(color: textMuted, fontSize: 13)),
            GestureDetector(
              onTap: () => setState(() {
                _authMode = 'login';
                _errorMessage = null;
              }),
              child: const Text(
                'Log In',
                style: TextStyle(color: Color(0xFF3390EC), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required Color inputBg,
    required Color borderColor,
    required Color textMuted,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF2481CC)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.7), fontSize: 14),
            filled: true,
            fillColor: inputBg,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2481CC), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServerConfigRow(bool isDark, Color borderColor, Color textMuted, String hostDisplay) {
    return Column(
      children: [
        Divider(color: borderColor, height: 28),
        InkWell(
          onTap: () => setState(() => _showServerSettings = !_showServerSettings),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              children: [
                // Pulse dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isServerReachable == true
                        ? const Color(0xFF10B981)
                        : _isServerReachable == false
                            ? Colors.redAccent
                            : Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hostDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_canSignUp) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Open Signup',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  _showServerSettings ? Icons.keyboard_arrow_up : Icons.settings_outlined,
                  size: 16,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
        if (_showServerSettings) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _serverUrlCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'https://mattermost.example.com',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _isTestingConnection
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Test Connection',
                onPressed: _isTestingConnection ? null : _checkServerConfig,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(Color cardColor, Color borderColor, Color textMuted) {
    return Column(
      children: [
        InkWell(
          onTap: () => _launchUrl('https://github.com/asefg482/mattergram'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code_rounded, size: 15, color: textMuted),
                const SizedBox(width: 6),
                Text(
                  'Open Source',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
                ),
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: textMuted, shape: BoxShape.circle),
                ),
                const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                const SizedBox(width: 4),
                const Text(
                  'Star on GitHub',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3390EC)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connected to Mattermost v4 REST & WebSocket APIs',
          style: TextStyle(fontSize: 11, color: textMuted.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _DotBackgroundPainter extends CustomPainter {
  final Color dotColor;

  _DotBackgroundPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const radius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotBackgroundPainter oldDelegate) => oldDelegate.dotColor != dotColor;
}
