import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _appVersion = 'Version 1.0.0 (Build 1)';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})';
      });
    } catch (e) {
      // Keep default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Account & Notifications
                    _buildSectionTitle('Preferences'),
                    _buildSettingsCard([
                      _buildSettingsTile(
                        icon: Icons.person_outline,
                        iconBgColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Edit Profile',
                        subtitle: user?.displayName ?? 'Manage your display name',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.notifications_none_outlined,
                        iconBgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                        iconColor: const Color(0xFF10B981),
                        title: 'Push Notifications',
                        subtitle: 'Get alerts for rescues & activities',
                        value: _notificationsEnabled,
                        onChanged: (val) {
                          setState(() {
                            _notificationsEnabled = val;
                          });
                          _showSnackBar(
                            _notificationsEnabled
                                ? 'Notifications enabled successfully'
                                : 'Notifications muted',
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Section 2: Actions & Support
                    _buildSectionTitle('App Actions'),
                    _buildSettingsCard([
                      _buildSettingsTile(
                        icon: Icons.share_outlined,
                        iconBgColor: Colors.orange.withValues(alpha: 0.1),
                        iconColor: Colors.orange,
                        title: 'Share App',
                        subtitle: 'Spread the word with friends',
                        onTap: _shareApp,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.support_agent_outlined,
                        iconBgColor: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                        iconColor: const Color(0xFF0EA5E9),
                        title: 'Contact Support',
                        subtitle: 'Get in touch for questions or feedback',
                        onTap: _contactSupport,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        iconBgColor: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                        iconColor: const Color(0xFFF43F5E),
                        title: 'Privacy Policy',
                        subtitle: 'View data security policies',
                        onTap: _launchPrivacyPolicy,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.info_outline_rounded,
                        iconBgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Version',
                        subtitle: _appVersion,
                        onTap: () {},
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Section 3: Danger Zone
                    _buildSectionTitle('Danger Zone', color: const Color(0xFFEF4444)),
                    _buildSettingsCard([
                      _buildSettingsTile(
                        icon: Icons.delete_forever_outlined,
                        iconBgColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        iconColor: const Color(0xFFEF4444),
                        title: 'Delete Account',
                        titleColor: const Color(0xFFEF4444),
                        subtitle: 'Permanently delete your profile and data',
                        onTap: () => _confirmDeleteAccount(context, user),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          // Branding at the absolute bottom
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0, top: 12.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Jeev Sathi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2026 Jeev Sathi. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF64748B).withValues(alpha: 0.8),
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

  Widget _buildSectionTitle(String title, {Color color = const Color(0xFF64748B)}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 16,
      color: Color(0xFFF1F5F9),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: titleColor ?? const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: titleColor ?? const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.2),
            inactiveThumbColor: const Color(0xFF94A3B8),
            inactiveTrackColor: const Color(0xFFE2E8F0),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Download Jeev Sathi App to support animal rescue & welfare: https://play.google.com/store/apps/details?id=com.jeevsathi.sinux.app',
        title: 'Jeev Sathi App',
      ),
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://jeevsathi.org/privacy-policy');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open Privacy Policy link');
      }
    } catch (e) {
      _showSnackBar('Error opening link');
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'jeevsathiapp@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Jeev Sathi Support Request',
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch email application');
      }
    } catch (e) {
      _showSnackBar('Error launching email client');
    }
  }

  void _confirmDeleteAccount(BuildContext context, User? user) {
    if (user == null) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              SizedBox(height: 10),
              Text(
                'This action is irreversible. All your profile information, registration details, and records will be deleted forever.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAccount(context, user);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context, User user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
        ),
      ),
    );

    try {
      final uid = user.uid;

      // 1. Delete user record from Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // 2. Sign out of Google if the user is signed in with Google
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (googleError) {
        debugPrint('Google sign out error: $googleError');
      }

      // 3. Delete user account from Firebase Auth
      await user.delete();

      if (context.mounted) {
        Navigator.pop(context); // Close loader
        _showSnackBar('Account deleted successfully.');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loader
      
      if (e.code == 'requires-recent-login') {
        _showSnackBar('Safety check: Please sign out, sign in again, and then delete your account.');
      } else {
        _showSnackBar('Authentication error: ${e.message}');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loader
      _showSnackBar('Error: ${e.toString()}');
    }
  }
}
