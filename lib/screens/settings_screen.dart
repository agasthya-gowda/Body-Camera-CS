import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';
import '../widgets/responsive_content.dart';

const _kBgDark = Color(0xFF0A1628);
const _kSurfaceDark = Color(0xFF0F172A);
const _kBorderDark = Color(0xFF1E293B);

const _kBgLight = Color(0xFFF1F5F9);
const _kSurfaceLight = Colors.white;
const _kBorderLight = Color(0xFFE2E8F0);

const _kBlue600 = Color(0xFF2563EB);
const _kBlue400 = Color(0xFF60A5FA);
const _kRose600 = Color(0xFFE11D48);
const _kRose300 = Color(0xFFFDA4AF);


class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const SettingsScreen({super.key, this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  String _username = '';
  String _appVersion = '';

  bool get _isDark => AppTheme.isDark(context);

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Officer';
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _logout() async {
    final isDark = _isDark;
    final surface = isDark ? _kSurfaceDark : _kSurfaceLight;
    final border = isDark ? _kBorderDark : _kBorderLight;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A1628);
    final textSecondary = isDark ? Colors.white70 : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        title: Text('Sign Out', style: TextStyle(color: textPrimary)),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRose600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final bg = isDark ? _kBgDark : _kBgLight;
    final surface = isDark ? _kSurfaceDark : _kSurfaceLight;
    final border = isDark ? _kBorderDark : _kBorderLight;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A1628);
    final textFaint = isDark ? Colors.white38 : Colors.grey[500];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  if (widget.onBack != null) ...[
                    IconButton(
                      onPressed: widget.onBack,
                      icon: Icon(Icons.arrow_back, color: textPrimary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Settings',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Application & Telemetry Preferences',
                          style: TextStyle(color: textFaint, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ResponsiveContent(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    const SizedBox(height: 16),
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Appearance'),
                    _buildThemeToggle(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('About'),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface.withOpacity(isDark ? 0.6 : 1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: border.withOpacity(isDark ? 0.8 : 1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 16,
                                color: _kBlue400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'BWC Mobile Law Enforcement Portal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _appVersion.isEmpty
                                ? 'Build ...'
                                : 'Build v$_appVersion',
                            style: TextStyle(
                              fontSize: 11,
                              color: textFaint,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ChipScape Police Dept • Real-time Body Worn Camera Fleet Management',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: textFaint),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _kRose600.withOpacity(0.15),
                            foregroundColor: _kRose300,
                            side: BorderSide(color: _kRose600.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.logout, color: _kRose300),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _kRose300,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final isDark = _isDark;
    final surface = isDark ? _kSurfaceDark : _kSurfaceLight;
    final border = isDark ? _kBorderDark : _kBorderLight;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A1628);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kBlue600.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBlue600.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : 'O',
                style: const TextStyle(
                  color: _kBlue400,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _username,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Field Officer',
                style: TextStyle(color: _kBlue400, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    final isDark = _isDark;
    final surface = isDark ? _kSurfaceDark : _kSurfaceLight;
    final border = isDark ? _kBorderDark : _kBorderLight;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A1628);
    final textFaint = isDark ? Colors.white38 : Colors.grey[500];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kBlue600.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: _kBlue400,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isDark ? 'On' : 'Off',
                  style: TextStyle(color: textFaint, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            activeColor: _kBlue400,
            onChanged: (_) => AppTheme.toggle(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _isDark ? Colors.white38 : Colors.grey[500],
          letterSpacing: 0.6,
        ),
      ),
    );
  }

}
