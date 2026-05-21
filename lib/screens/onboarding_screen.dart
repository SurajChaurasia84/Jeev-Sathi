import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<Map<String, String>> _slides = [
    {
      'emoji': '🤝',
      'title': 'जीव साथी में आपका स्वागत है',
      'description': 'हर बेजुबान जीव की रक्षा और सेवा के लिए एक साझा प्रयास। आइए मिलकर उनके जीवन को बेहतर बनाएं।',
    },
    {
      'emoji': '🚨',
      'title': 'आपातकालीन चिकित्सा (SOS)',
      'description': 'सड़क पर घायल पशुओं के लिए तुरंत रिपोर्ट करें और डॉक्टर या नजदीकी गौ सेवक को सूचित करें।',
    },
    {
      'emoji': '🏡',
      'title': 'गौशालाओं का सहयोग करें',
      'description': 'नजदीकी गौशालाओं से जुड़ें, सीधे दान करें या स्वयंसेवक (Gau Sevak) बनकर सेवा में हाथ बटाएं।',
    },
  ];

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Trigger the Google Authentication flow.
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        // The user canceled the sign-in.
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2. Obtain the auth details from the request.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Once signed in, return the UserCredential.
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null && mounted) {
        // Show progress indicating database sync
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("सिंक हो रहा है... कृपया प्रतीक्षा करें"),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // 5. Save/update user details in Cloud Firestore.
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          await docRef.set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        } else {
          await docRef.update({
            'photoUrl': user.photoURL ?? '', // Update photo if changed
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("लॉगिन असफल रहा: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                // App Logo Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🤝', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'जीव साथी',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                
                // Swipeable PageView Cards
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _slides.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        child: Card(
                          color: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                            side: const BorderSide(color: Color(0xFFF1F5F9)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Feature Animated Icon
                                CircleAvatar(
                                  radius: 64,
                                  backgroundColor: const Color(0xFF10B981).withOpacity(0.08),
                                  child: Text(
                                    _slides[index]['emoji']!,
                                    style: const TextStyle(fontSize: 64),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                // Feature Title
                                Text(
                                  _slides[index]['title']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Feature Description
                                Text(
                                  _slides[index]['description']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Page Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      height: 8.0,
                      width: _currentPage == index ? 24.0 : 8.0,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF10B981)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Google Sign In Block
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: _signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.15),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/google_logo.png',
                                  height: 20,
                                  width: 20,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.g_mobiledata,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Google के साथ लॉगिन करें',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'आगे बढ़कर आप हमारे नियमों और शर्तों से सहमत होते हैं।',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
