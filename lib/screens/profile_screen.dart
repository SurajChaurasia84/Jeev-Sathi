import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'gau_sevak_registration_screen.dart';
import 'doctor_registration_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'gau_sevak_dashboard_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'emergency_contacts_screen.dart';
import 'donation_screen.dart';
import '../widgets/safe_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<String?> _getLocalProfileImagePath(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('profile_image_path_$uid');
      if (path != null && path.isNotEmpty) {
        if (await File(path).exists()) {
          return path;
        }
      }
    } catch (_) {}
    return null;
  }

  String? _getNetworkProfileUrl(User user) {
    if (user.photoURL != null && user.photoURL!.startsWith('http')) {
      return user.photoURL;
    }
    for (final profile in user.providerData) {
      if (profile.photoURL != null && profile.photoURL!.startsWith('http')) {
        return profile.photoURL;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('प्रोफाइल', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'उपयोगकर्ता विवरण लोड करने में असमर्थ।',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  );
                }

                Map<String, dynamic> userData = {};
                if (snapshot.hasData && snapshot.data!.exists) {
                  userData = snapshot.data!.data() as Map<String, dynamic>;
                }

                // Dynamic badges based on roles
                final bool isGauSevak = userData['isGauSevak'] ?? false;
                final bool isDoctor = userData['isDoctor'] ?? false;

                String badgeStr = 'स्वयंसेवक (Volunteer)';
                if (isGauSevak && isDoctor) {
                  badgeStr = 'गौ सेवक एवं पशु चिकित्सक';
                } else if (isGauSevak) {
                  badgeStr = 'प्रमाणित गौ सेवक (Verified Gau Sevak)';
                } else if (isDoctor) {
                  badgeStr = 'पशु चिकित्सक (Doctor)';
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // User Profile Header Card
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  FutureBuilder<String?>(
                                    future: _getLocalProfileImagePath(user.uid),
                                    builder: (context, pathSnapshot) {
                                      final localPath = pathSnapshot.data;
                                      final String? googlePhotoUrl = userData['photoUrl'] as String?;
                                      final String? networkUrl = (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty)
                                          ? googlePhotoUrl
                                          : _getNetworkProfileUrl(user);
                                      final String? resolvedUrl = localPath != null
                                          ? null  // will use localFile param
                                          : (networkUrl != null && networkUrl.isNotEmpty && networkUrl.startsWith('http')
                                              ? networkUrl
                                              : null);

                                      return SafeNetworkAvatar(
                                        radius: 50,
                                        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                                        localFile: localPath != null ? File(localPath) : null,
                                        photoUrl: resolvedUrl,
                                        fallbackChild: const Icon(Icons.person, size: 50, color: Color(0xFF10B981)),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const EditProfileScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.displayName ?? 'गौ सेवक (User)',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            if (user.email != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                user.email!,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              badgeStr,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                            ),

                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Profile Options Menu
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRoleLoginCard(
                                    context: context,
                                    icon: Icons.volunteer_activism_outlined,
                                    title: 'Login as Gau Sevak',
                                    subtitle: 'गौ सेवक लॉगिन',
                                    color: const Color(0xFF10B981),
                                    onTap: () {
                                      if (isGauSevak) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const GauSevakDashboardScreen(),
                                          ),
                                        );
                                      } else {
                                        _showGauSevakNotRegisteredModal(context);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildRoleLoginCard(
                                    context: context,
                                    icon: Icons.medical_services_outlined,
                                    title: 'Login as Doctor',
                                    subtitle: 'डॉक्टर लॉगिन',
                                    color: const Color(0xFFEC4899),
                                    onTap: () {
                                      if (isDoctor) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const DoctorDashboardScreen(),
                                          ),
                                        );
                                      } else {
                                        _showDoctorNotRegisteredModal(context);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildProfileOption(
                              icon: Icons.assignment_turned_in,
                              title: 'Gau Sevak Registration Status',
                              subtitle: isGauSevak ? 'सत्यापित / सक्रिय (Active)' : 'पंजीकरण करें / जुड़ें (Join Now)',
                              trailingColor: isGauSevak ? const Color(0xFF10B981) : Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const GauSevakRegistrationScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildProfileOption(
                              icon: Icons.medical_services_outlined,
                              title: 'Doctor Profile Details',
                              subtitle: isDoctor ? 'पंजीकृत / विवरण देखें' : 'अपनी डॉक्टर प्रोफाइल जोड़ें (Register)',
                              trailingColor: isDoctor ? const Color(0xFFEC4899) : Colors.grey,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DoctorRegistrationScreen()),
                                );
                              },
                            ),

                            const SizedBox(height: 12),
                            _buildProfileOption(
                              icon: Icons.emergency_share_outlined,
                              title: 'Emergency SOS Contacts',
                              subtitle: 'आपातकालीन संपर्क सेटअप करें',
                              iconColor: const Color(0xFFEF4444),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildProfileOption(
                              icon: Icons.favorite,
                              title: 'Donate Now',
                              subtitle: 'गौ माता सेवा कोष में सहयोग करें',
                              iconColor: const Color(0xFFF97316),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DonationScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildProfileOption(
                              icon: Icons.settings,
                              title: 'Settings',
                              subtitle: 'एप्लिकेशन सेटिंग्स',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Logout
                            ElevatedButton.icon(
                              onPressed: () async {
                                final bool? confirmLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text(
                                        'लॉगआउट की पुष्टि',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      content: const Text('क्या आप वास्तव में लॉगआउट करना चाहते हैं?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text(
                                            'नहीं (No)',
                                            style: TextStyle(color: Color(0xFF64748B)),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text(
                                            'हां (Yes)',
                                            style: TextStyle(
                                              color: Color(0xFFEF4444),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmLogout == true) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("लॉगआउट हो रहा है..."),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                  try {
                                    await FirebaseAuth.instance.signOut();
                                    final googleSignIn = GoogleSignIn();
                                    if (await googleSignIn.isSignedIn()) {
                                      await googleSignIn.signOut();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("त्रुटि: ${e.toString()}"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFEF4444),
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                                ),
                              ),
                              icon: const Icon(Icons.exit_to_app, size: 18),
                              label: const Text('लॉगआउट (Logout)', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = const Color(0xFF10B981),
    Color? trailingColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingColor != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: trailingColor, shape: BoxShape.circle),
              ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleLoginCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoctorNotRegisteredModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: Color(0xFFEC4899),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'पंजीकरण नहीं मिला',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You are not registered as doctor, register to login.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'रद्द करें (Cancel)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DoctorRegistrationScreen()),
                          );
                        },
                        child: const Text(
                          'पंजीकरण करें (Register)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGauSevakNotRegisteredModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_outlined,
                    color: Color(0xFF10B981),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'पंजीकरण नहीं मिला',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You are not registered as Gau Sevak, register to login.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'रद्द करें (Cancel)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GauSevakRegistrationScreen()),
                          );
                        },
                        child: const Text(
                          'पंजीकरण करें (Register)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}






