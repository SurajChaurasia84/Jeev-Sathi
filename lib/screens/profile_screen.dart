import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gau_sevak_registration_screen.dart';
import 'gaushala_registration_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                final bool isGaushalaOwner = userData['isGaushalaOwner'] ?? false;

                String badgeStr = 'स्वयंसेवक (Volunteer)';
                if (isGauSevak && isGaushalaOwner) {
                  badgeStr = 'गौ सेवक एवं गौशाला संचालक';
                } else if (isGauSevak) {
                  badgeStr = 'प्रमाणित गौ सेवक (Verified Gau Sevak)';
                } else if (isGaushalaOwner) {
                  badgeStr = 'गौशाला संचालक (Gaushala Owner)';
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
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                                    child: user.photoURL == null
                                        ? const Text('🤠', style: TextStyle(fontSize: 48))
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
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
                              icon: Icons.house,
                              title: 'My Gaushala Details',
                              subtitle: isGaushalaOwner ? 'पंजीकृत / विवरण देखें' : 'अपनी गौशाला जोड़ें (Register)',
                              trailingColor: isGaushalaOwner ? const Color(0xFF3B82F6) : Colors.grey,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const GaushalaRegistrationScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildProfileOption(
                              icon: Icons.volunteer_activism,
                              title: 'Donation History',
                              subtitle: 'मेरे योगदान का विवरण (Real-time)',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('💰 अभी कोई दान का इतिहास उपलब्ध नहीं है।')),
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
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: 20),
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
}
