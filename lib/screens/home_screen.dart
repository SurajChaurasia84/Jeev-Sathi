import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'gau_sevak_registration_screen.dart';
import 'doctor_registration_screen.dart';
import 'donation_screen.dart';
import 'emergency_contacts_screen.dart';
import 'all_sos_reports_screen.dart';
import 'sos_screen.dart';
import 'notifications_screen.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:another_telephony/telephony.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<QueryDocumentSnapshot> _reports = [];
  bool _isLoading = true;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadReportsWithCacheFirst();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFCM();
    });
  }

  Future<void> _setupFCM() async {
    try {
      // Add a small delay to let the UI render fully before prompting the user
      await Future.delayed(const Duration(seconds: 1));
      
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // Request notifications permission (specifically needed for iOS and Android 13+)
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Enable foreground notifications (shows banners even when app is open)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Subscribe to public rescue alerts topic
      await messaging.subscribeToTopic('sos_alerts');
    } catch (e) {
      debugPrint('FCM setup error: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadReportsWithCacheFirst() async {
    // 1. Try Cache First
    try {
      final cacheSnapshot = await FirebaseFirestore.instance
          .collection('sos_reports')
          .orderBy('createdAt', descending: true)
          .limit(6)
          .get(const GetOptions(source: Source.cache));
      
      if (cacheSnapshot.docs.isNotEmpty) {
        setState(() {
          _reports = cacheSnapshot.docs;
          _isLoading = false;
        });
      }
    } catch (_) {
    }

    // 2. Try Server
    try {
      final serverSnapshot = await FirebaseFirestore.instance
          .collection('sos_reports')
          .orderBy('createdAt', descending: true)
          .limit(6)
          .get(const GetOptions(source: Source.server));

      if (serverSnapshot.docs.isNotEmpty) {
        setState(() {
          _reports = serverSnapshot.docs;
          _isLoading = false;
        });
      } else if (_reports.isEmpty) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
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
              // 1. Donation & Safety Carousel
              _buildCarouselSection(context),
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

              // 2.5 Gau Mata Seva Fund Card
              _buildDonationCard(context),
              const SizedBox(height: 24),

              // 3. Reels Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ट्रेंडिंग रिपोर्ट्स (Trending Reports)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllSOSReportsScreen()),
                      );
                    },
                    child: const Text('सभी देखें', style: TextStyle(color: Color(0xFF10B981))),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Reels Preview Horizontal Scroll (Firestore Cache First - Limit 6)
              SizedBox(
                height: 220,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      )
                    : _reports.isEmpty
                        ? Center(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('🐾', style: TextStyle(fontSize: 32)),
                                  SizedBox(height: 8),
                                  Text(
                                    'कोई सक्रिय रिपोर्ट नहीं है।',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _reports.length,
                            itemBuilder: (context, index) {
                              final doc = _reports[index];
                              final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
                              data['docId'] = doc.id;
                              
                              final String animal = data['animal'] ?? 'Cow';
                              final String creator = data['reporterName'] ?? 'Anonymous';
                              final String? imageUrl = data['imageUrl'];
                              final String status = data['status'] ?? 'Active';
                              final String? description = data['description'];

                              return Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                child: SOSReportCard(
                                  imageUrl: imageUrl,
                                  animal: animal,
                                  description: description,
                                  status: status,
                                  creator: creator,
                                  rawData: data,
                                ),
                              );
                            },
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
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange.shade800, Colors.orange.shade600],
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DonationScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🐄', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gau Mata Seva Fund',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'घायल गायों के इलाज के लिए सहयोग करें',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'दान करें',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(width: 4),
                      Text('🙏', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
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

  // Reusable SOSReportCard widget is imported from all_sos_reports_screen.dart

  Widget _buildCarouselSection(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView(
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildAnimalRescueCard(context),
              _buildWomenSafetyCard(context),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAnimalRescueCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE11D48), Color(0xFF9F1239)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🚨', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    'Animal Rescue SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'जानवर की मदद के लिए SOS भेजें',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SOSScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFE11D48),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Report भेजें 🐾',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWomenSafetyCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🚨', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Women Safety SOS',
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
                'महिला सुरक्षा: एक टैप में आपातकालीन संपर्कों को अलर्ट करें',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _triggerWomenSafetySOS(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'तुरंत अलर्ट भेजें 🚨',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showLocationPromptDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.location_off, color: Color(0xFFEF4444)),
          SizedBox(width: 8),
          Text('स्थान सेवा बंद है', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: const Text(
        'बेहतर सुरक्षा और सटीक ट्रैकिंग के लिए कृपया अपने फ़ोन का GPS/स्थान सेवा चालू करें।\n\nक्या आप स्थान सेवा चालू करना चाहते हैं या बिना स्थान के संदेश भेजना चाहते हैं?',
        style: TextStyle(fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // Send without location
          child: const Text('बिना स्थान के भेजें', style: TextStyle(color: Color(0xFF64748B))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true), // Open settings
          child: const Text(
            'सक्षम करें (Enable)',
            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
          ),
        ),
      ],
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

      // Show countdown of 5 seconds
      bool confirmSOS = false;
      if (context.mounted) {
        final bool? res = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const SOSCountdownDialog(),
        );
        confirmSOS = res == true;
      }

      if (!confirmSOS) return;

      final bool includeLocationSetting = data?['includeLocation'] ?? true;
      final senderName = data?['displayName'] ?? data?['name'] ?? user.displayName ?? 'Jeev Sathi User';

      Position? currentPosition;
      if (includeLocationSetting) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (context.mounted) {
            final bool? enableLocation = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => _showLocationPromptDialog(context),
            );
            if (enableLocation == true) {
              await Geolocator.openLocationSettings();
              // Give the user time to turn it on and return
              await Future.delayed(const Duration(seconds: 2));
              serviceEnabled = await Geolocator.isLocationServiceEnabled();
            }
          }
        }

        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
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

            try {
              currentPosition = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 8),
                ),
              );
            } catch (e) {
              try {
                currentPosition = await Geolocator.getLastKnownPosition();
              } catch (_) {}
            }

            if (context.mounted && gpsLoaderOpen) {
              Navigator.pop(context);
              gpsLoaderOpen = false;
            }
          }
        }
      }

      String finalMsg = "🚨 आपातकालीन अलर्ट!\nप्रेषक: $senderName\n\n$msg";
      if (currentPosition != null) {
        finalMsg += "\n\n📍 लाइव स्थान: ${currentPosition.latitude}, ${currentPosition.longitude}\n🔗 Google Maps Link: https://maps.google.com/?q=${currentPosition.latitude},${currentPosition.longitude}";
      }

      // Show trigger/send loader
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

      final List<String> phones = [];
      if (pPhone.isNotEmpty) phones.add(pPhone);
      if (gPhone.isNotEmpty) phones.add(gPhone);
      if (fPhone.isNotEmpty) phones.add(fPhone);

      final List<String> sanitizedPhones = phones
          .map((p) => p.replaceAll(RegExp(r'\s+|-|\(|\)'), ''))
          .where((p) => p.isNotEmpty)
          .toList();

      bool smsSentSuccess = false;
      if (Platform.isAndroid && sanitizedPhones.isNotEmpty) {
        try {
          final Telephony telephony = Telephony.instance;
          final bool? permission = await telephony.requestSmsPermissions;
          if (permission == true) {
            for (final phone in sanitizedPhones) {
              await telephony.sendSms(
                to: phone,
                message: finalMsg,
                isMultipart: true,
              );
            }
            smsSentSuccess = true;
          }
        } catch (e) {
          debugPrint('Telephony SMS failed, falling back: $e');
        }
      }

      if (!smsSentSuccess && sanitizedPhones.isNotEmpty) {
        final separator = Platform.isAndroid ? ',' : ';';
        final phonePath = sanitizedPhones.join(separator);
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: phonePath,
          queryParameters: <String, String>{
            'body': finalMsg,
          },
        );
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          smsSentSuccess = true;
        }
      }

      // Dismiss send loader
      if (context.mounted && sendLoaderOpen) {
        Navigator.pop(context);
        sendLoaderOpen = false;
      }

      // Show Trigger Success Alert
      if (context.mounted && smsSentSuccess) {
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
      } else if (context.mounted && !smsSentSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('अलर्ट भेजने में विफल: SMS भेजने के लिए आवश्यक अनुमतियां नहीं मिलीं।'),
            backgroundColor: Colors.red,
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

class SOSCountdownDialog extends StatefulWidget {
  const SOSCountdownDialog({super.key});

  @override
  State<SOSCountdownDialog> createState() => _SOSCountdownDialogState();
}

class _SOSCountdownDialogState extends State<SOSCountdownDialog> {
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        if (mounted) {
          Navigator.pop(context, true); // true means countdown finished
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing by back button
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 48),
            SizedBox(height: 8),
            Text(
              'महिला सुरक्षा SOS अलर्ट',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF991B1B)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'आपातकालीन संदेश 5 सेकंड में भेजा जाएगा...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _secondsLeft / 5.0,
                    strokeWidth: 6,
                    backgroundColor: Colors.red.shade50,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                  ),
                ),
                Text(
                  '$_secondsLeft',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64748B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context, false); // false means cancelled
            },
            icon: const Icon(Icons.cancel, color: Colors.white, size: 16),
            label: const Text('रद्द करें (Cancel)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
