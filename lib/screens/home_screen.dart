import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gau_sevak_registration_screen.dart';
import 'doctor_registration_screen.dart';
import 'donation_screen.dart';
import 'emergency_contacts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🤝', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'जीव साथी',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'हर जीव की रक्षा हमारा कर्तव्य',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.notifications_outlined, color: Color(0xFF334155)),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Donation Campaign Card
              _buildDonationCard(context),
              const SizedBox(height: 24),

              // 2. Registration Actions
              const Text(
                'पंजीकरण / सेवा से जुड़ें',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'गौ सेवक बनें',
                      subtitle: 'Gau Sevak Registration',
                      emoji: '🤝',
                      gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GauSevakRegistrationScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'डॉक्टर रजिस्टर करें',
                      subtitle: 'Doctor Registration',
                      emoji: '🩺',
                      gradient: const [Color(0xFFEC4899), Color(0xFFBE185D)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DoctorRegistrationScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Women Safety Banner (Optional highlight / CTA)
              _buildWomenSafetyBanner(context),
              const SizedBox(height: 24),

              // 3. Reels Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ट्रेंडिंग फीड्स (Trending Feeds)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('सभी देखें', style: TextStyle(color: Color(0xFF10B981))),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Reels Preview Horizontal Scroll
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildReelCard(
                      imageUrl: 'https://images.unsplash.com/photo-1570042225831-d98fa7577f1e?w=500&auto=format&fit=crop',
                      tag: 'Rescue',
                      likes: '4,823',
                      creator: 'राम सेवक जी',
                    ),
                    _buildReelCard(
                      imageUrl: 'https://images.unsplash.com/photo-1596733430284-f7437764b1a9?w=500&auto=format&fit=crop',
                      tag: 'Treatment',
                      likes: '7,241',
                      creator: 'प्रिया गौ माता',
                    ),
                    _buildReelCard(
                      imageUrl: 'https://images.unsplash.com/photo-1546182990-dffeafbe841d?w=500&auto=format&fit=crop',
                      tag: 'Feeding',
                      likes: '3,156',
                      creator: 'गौशाला पथमेड़ा',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange.shade800, Colors.orange.shade600],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🐄', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Gau Mata Seva Fund',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'घायल गायों के इलाज के लिए सहयोग करें',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DonationScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange.shade800,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'अभी दान करें 🙏',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReelCard({
    required String imageUrl,
    required String tag,
    required String likes,
    required String creator,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Play Button icon overlay
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 36),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          likes,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      creator,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildWomenSafetyBanner(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFEF2F2),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFEE2E2)),
      ),
      child: InkWell(
        onTap: () => _triggerWomenSafetySOS(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'महिला सुरक्षा (Women Safety SOS)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'एक टैप में आपातकालीन संपर्कों को अलर्ट करें',
                      style: TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFEF4444)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _triggerWomenSafetySOS(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('उपयोगकर्ता लॉग इन नहीं है।')),
      );
      return;
    }

    bool fetchLoaderOpen = false;
    try {
      // 1. Show loading state dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
          ),
        ),
      );
      fetchLoaderOpen = true;

      // 2. Fetch User Emergency Settings
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      // Dismiss loader dialog
      if (context.mounted && fetchLoaderOpen) {
        Navigator.pop(context);
        fetchLoaderOpen = false;
      }

      if (!userDoc.exists) {
        throw Exception("उपयोगकर्ता डेटा नहीं मिला।");
      }

      final data = userDoc.data();
      final pName = data?['emergencyContactName1'] ?? '';
      final pPhone = data?['emergencyContactPhone1'] ?? '';
      
      final gName = data?['emergencyContactName2'] ?? '';
      final gPhone = data?['emergencyContactPhone2'] ?? '';
      
      final fName = data?['emergencyContactName3'] ?? '';
      final fPhone = data?['emergencyContactPhone3'] ?? '';

      final msg = data?['emergencyMessage'] ?? '🚨 EMERGENCY! I am in danger, please help me immediately.';

      // Check if at least one contact is set
      if (pPhone.isEmpty && gPhone.isEmpty && fPhone.isEmpty) {
        // Show setup alert
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('आपातकालीन विवरण आवश्यक', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: const Text(
                'SOS अलर्ट भेजने के लिए कृपया पहले अपनी प्रोफ़ाइल में जाकर आपातकालीन संपर्क (Emergency Contacts) सेट करें।',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('रद्द करें', style: TextStyle(color: Color(0xFF64748B))),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
                    );
                  },
                  child: const Text(
                    'अभी सेट करें',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 3. Confirm triggering SOS Alert
      bool confirmSOS = false;
      if (context.mounted) {
        final bool? res = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.report_problem, color: Color(0xFFEF4444)),
                SizedBox(width: 8),
                Text('SOS अलर्ट की पुष्टि', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: const Text(
              'क्या आप वाकई आपातकालीन अलर्ट भेजना चाहते हैं?\nयह संदेश आपके दर्ज किए गए आपातकालीन संपर्कों को भेजा जाएगा।',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('रद्द करें', style: TextStyle(color: Color(0xFF64748B))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'अलर्ट भेजें',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        confirmSOS = res == true;
      }

      if (!confirmSOS) return;

      final bool includeLocationSetting = data?['includeLocation'] ?? true;
      String finalMsg = msg;
      const String gpsCoords = '26.9124° N, 75.7873° E (GPS Live Coordinates)';

      if (includeLocationSetting) {
        bool locationOnConfirmed = false;
        if (context.mounted) {
          final bool? gpsRes = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text('GPS स्थान चालू करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: const Text(
                'सटीक संकट अलर्ट संदेश के लिए कृपया सुनिश्चित करें कि आपके फोन का GPS (Location) चालू है।\n\nक्या स्थान चालू है?',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('रद्द करें', style: TextStyle(color: Color(0xFF64748B))),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'हाँ, स्थान चालू करें',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
          locationOnConfirmed = gpsRes == true;
        }

        if (!locationOnConfirmed) return;

        // Show loading state dialog while fetching GPS coords
        bool gpsLoaderOpen = false;
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '📍 सटीक GPS स्थान प्राप्त किया जा रहा है...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          gpsLoaderOpen = true;
        }

        // Simulate high-accuracy GPS fetching delay
        await Future.delayed(const Duration(milliseconds: 1500));

        if (context.mounted && gpsLoaderOpen) {
          Navigator.pop(context);
          gpsLoaderOpen = false;
        }

        finalMsg = "$msg\n\n📍 लाइव स्थान: $gpsCoords\n🔗 Google Maps Link: https://maps.google.com/?q=26.9124,75.7873";
      }

      // Show trigger loader
      bool sendLoaderOpen = false;
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
            ),
          ),
        );
        sendLoaderOpen = true;
      }

      // Log alert document to Firestore
      final List<String> alertedContacts = [];
      if (pPhone.isNotEmpty) alertedContacts.add('$pName ($pPhone)');
      if (gPhone.isNotEmpty) alertedContacts.add('$gName ($gPhone)');
      if (fPhone.isNotEmpty) alertedContacts.add('$fName ($fPhone)');

      final newAlert = {
        'senderUid': user.uid,
        'senderName': user.displayName ?? 'Jeev Sathi User',
        'emergencyContactName1': pName.isNotEmpty ? pName : null,
        'emergencyContactPhone1': pPhone.isNotEmpty ? pPhone : null,
        'emergencyContactName2': gName.isNotEmpty ? gName : null,
        'emergencyContactPhone2': gPhone.isNotEmpty ? gPhone : null,
        'emergencyContactName3': fName.isNotEmpty ? fName : null,
        'emergencyContactPhone3': fPhone.isNotEmpty ? fPhone : null,
        'message': finalMsg,
        'location': gpsCoords,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('emergency_sos_alerts').add(newAlert);

      // Dismiss loader
      if (context.mounted && sendLoaderOpen) {
        Navigator.pop(context);
        sendLoaderOpen = false;
      }

      // Show Trigger Success Alert
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('SOS अलर्ट भेजा गया!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'आपका आपातकालीन संकट संदेश और वर्तमान स्थान निम्नलिखित संपर्कों को भेज दिया गया है:',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                ...alertedContacts.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ठीक है', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      // Dismiss loader if open
      if (context.mounted) {
        if (fetchLoaderOpen) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('अलर्ट भेजने में विफल: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
