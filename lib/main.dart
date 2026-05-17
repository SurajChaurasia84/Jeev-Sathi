import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const JeevSathiApp());
}

class JeevSathiApp extends StatelessWidget {
  const JeevSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jeev Sathi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981), // Emerald Green
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFFEF4444), // Crimson Red for SOS
          background: const Color(0xFFF8FAFC), // Slate 50
        ),
        fontFamily: 'Roboto',
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SOSScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF10B981).withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.home, color: Color(0xFF10B981)),
              label: 'होम',
            ),
            NavigationDestination(
              icon: Icon(Icons.emergency_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.emergency, color: Color(0xFFEF4444)),
              label: 'SOS',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.grey),
              selectedIcon: Icon(Icons.person, color: Color(0xFF10B981)),
              label: 'प्रोफाइल',
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. HOME SCREEN
// ==========================================
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
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🤝', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'जीवा साथी',
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
                      title: 'गौशाला रजिस्टर करें',
                      subtitle: 'Gaushala Registration',
                      emoji: '🏡',
                      gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GaushalaRegistrationScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Reels Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🎬 ट्रेंडिंग रील्स (Trending Reels)',
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
              const SizedBox(height: 24),

              // 4. Women Safety Banner (Optional highlight / CTA)
              _buildWomenSafetyBanner(),
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
                      color: Colors.white.withOpacity(0.9),
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
              const SizedBox(height: 16),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  value: 0.68,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹68,000 / ₹1,00,000 जमा हुए',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                  Text(
                    '68% पूर्ण',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Donation flow triggered! Thank you for your support 🙏')),
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
              color: gradient.first.withOpacity(0.3),
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
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
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
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
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

  Widget _buildWomenSafetyBanner() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFEF2F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFEE2E2)),
      ),
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
                    'SOS Women Safety SOS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'एक टैप में पुलिस और परिवार को अलर्ट करें',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFEF4444)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. SOS SCREEN (ANIMAL RESCUE SOS)
// ==========================================
class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with SingleTickerProviderStateMixin {
  int _activeSubTab = 0; // 0 = Report, 1 = Status, 2 = Sevak
  String _selectedAnimal = 'Cow';
  bool _isUploadingPhoto = false;
  bool _isAddingLocation = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚨 Animal Rescue SOS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'जानवर की मदद के लिए SOS भेजें',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444), // SOS Red
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sub tabs (Report, Status, Sevak)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _buildSubTab(0, '📍 Report', const Color(0xFFEF4444)),
                _buildSubTab(1, '📊 Status', const Color(0xFFEF4444)),
                _buildSubTab(2, '🤝 Sevak', const Color(0xFFEF4444)),
              ],
            ),
          ),
          Expanded(
            child: _activeSubTab == 0
                ? _buildReportTab()
                : _activeSubTab == 1
                    ? _buildStatusTab()
                    : _buildSevakTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab(int index, String label, Color accentColor) {
    bool isSelected = _activeSubTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeSubTab = index;
          });
        },
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? accentColor : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sub Tab 1: REPORT FORM
  Widget _buildReportTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flashing Big Emergency SOS Button Card
            ScaleTransition(
              scale: _pulseController,
              child: Card(
                elevation: 6,
                shadowColor: const Color(0xFFEF4444).withOpacity(0.3),
                color: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  onTap: () => _triggerInstantSOS(),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        const Icon(Icons.warning, color: Colors.white, size: 48),
                        const SizedBox(height: 8),
                        const Text(
                          'EMERGENCY SOS',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'टैप करें — Nearby Sevaks को Alert करें',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Select Animal Type
            const Text(
              'जानवर का प्रकार चुनें (Select Animal Type)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAnimalChip('Cow', '🐄'),
                _buildAnimalChip('Dog', '🐕'),
                _buildAnimalChip('Cat', '🐈'),
                _buildAnimalChip('Bird', '🐦'),
                _buildAnimalChip('Buffalo', '🐃'),
                _buildAnimalChip('Other', '🐾'),
              ],
            ),
            const SizedBox(height: 24),

            // Upload Media Card
            const Text(
              'फोटो / वीडियो जोड़ें (Add Photo/Video)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isUploadingPhoto = true;
                      });
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _isUploadingPhoto = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📸 फोटो सफलतापूर्वक जोड़ी गई!')),
                          );
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt, color: const Color(0xFF10B981), size: 28),
                          const SizedBox(height: 8),
                          const Text('Camera / कैमरा', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isUploadingPhoto = true;
                      });
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _isUploadingPhoto = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('🖼️ गैलरी से मीडिया जोड़ा गया!')),
                          );
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.photo_library, color: Colors.orange.shade600, size: 28),
                          const SizedBox(height: 8),
                          const Text('Gallery / गैलरी', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isUploadingPhoto)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const SizedBox(height: 24),

            // Live Location Card
            const Text(
              'स्थान (Live Location)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                onTap: () {
                  setState(() {
                    _isAddingLocation = true;
                  });
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) {
                      setState(() {
                        _isAddingLocation = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📍 लाइव लोकेशन प्राप्त हो चुकी है: 26.9124° N, 75.7873° E')),
                      );
                    }
                  });
                },
                leading: const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 28),
                title: const Text('टैप करें — GPS से Location जोड़ें', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('सटीक रेस्क्यू के लिए आवश्यक', style: TextStyle(fontSize: 11)),
                trailing: _isAddingLocation
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_ios, size: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Description Input
            const Text(
              'विवरण लिखें (Description)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'जानवर की स्थिति का विवरण लिखें...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Help Hotlines Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call Gaushala', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.call_made, size: 18),
                    label: const Text('Call NGO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: () => _triggerInstantSOS(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notification_important, size: 22),
                  SizedBox(width: 8),
                  Text('🚨 SOS Alert भेजें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalChip(String type, String emoji) {
    bool isSelected = _selectedAnimal == type;
    return ChoiceChip(
      label: Text('$emoji $type'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedAnimal = type;
          });
        }
      },
      selectedColor: const Color(0xFF10B981),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  void _triggerInstantSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('SOS Alert Sent!'),
          ],
        ),
        content: const Text(
          'आपका इमरजेंसी SOS अलर्ट भेज दिया गया है। नजदीकी गौ सेवकों और संबंधित एनजीओ को सूचित किया जा रहा है। कृपया स्थान पर बने रहें।',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ठीक है', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Sub Tab 2: STATUS LIST
  Widget _buildStatusTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusItem(
          id: '#SOS-8802',
          animal: 'Cow (गाय)',
          location: 'शास्त्री नगर, जयपुर',
          status: 'In Progress (सक्रिय)',
          statusColor: Colors.orange.shade700,
          time: '10 मिनट पहले',
        ),
        _buildStatusItem(
          id: '#SOS-8761',
          animal: 'Dog (कुत्ता)',
          location: 'मालवीय नगर, जयपुर',
          status: 'Resolved (सुलझाया गया)',
          statusColor: const Color(0xFF10B981),
          time: 'कल दोपहर 2:30',
        ),
      ],
    );
  }

  Widget _buildStatusItem({
    required String id,
    required String animal,
    required String location,
    required String status,
    required Color statusColor,
    required String time,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.pets, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(animal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text(location, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Sub Tab 3: SEVAK LIST
  Widget _buildSevakTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildSevakItem(
          name: 'राम किशोर शर्मा',
          distance: '0.8 km दूर',
          skills: 'First Aid, Transport',
          phone: '+91 98765 XXXXX',
          isAvailable: true,
        ),
        _buildSevakItem(
          name: 'दिनेश कुमार सैनी',
          distance: '1.5 km दूर',
          skills: 'Rescue, Cow Care',
          phone: '+91 94140 XXXXX',
          isAvailable: true,
        ),
        _buildSevakItem(
          name: 'सुरेश कुमार यादव',
          distance: '2.1 km दूर',
          skills: 'First Aid, Transport, Nursing',
          phone: '+91 88750 XXXXX',
          isAvailable: false,
        ),
      ],
    );
  }

  Widget _buildSevakItem({
    required String name,
    required String distance,
    required String skills,
    required String phone,
    required bool isAvailable,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
          child: const Text('🤝', style: TextStyle(fontSize: 18)),
        ),
        title: Row(
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isAvailable ? const Color(0xFF10B981) : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('कौशल: $skills', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(distance, style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Color(0xFF10B981)),
          onPressed: () {},
        ),
      ),
    );
  }
}

// ==========================================
// 3. PROFILE SCREEN
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('प्रोफाइल', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                          child: const Text('🤠', style: TextStyle(fontSize: 48)),
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
                  const Text(
                    'गौरव कुमार (Gaurav Kumar)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'प्रमाणित गौ सेवक (Verified Gau Sevak)',
                    style: TextStyle(fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProfileStat('रेस्क्यू (Rescues)', '12'),
                      _buildProfileStat('पॉइंट्स (Points)', '450'),
                      _buildProfileStat('योगदान (Rank)', '#15'),
                    ],
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
                    subtitle: 'सत्यापित / सक्रिय',
                    trailingColor: const Color(0xFF10B981),
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
                    subtitle: 'अपडेट करें / देखें',
                    trailingColor: const Color(0xFF3B82F6),
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
                    subtitle: 'मेरे योगदान का विवरण',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildProfileOption(
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'एप्लिकेशन सेटिंग्स',
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),

                  // Logout
                  ElevatedButton.icon(
                    onPressed: () {},
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
      ),
    );
  }

  Widget _buildProfileStat(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
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

// ==========================================
// 4. GAU SEVAK REGISTRATION SCREEN
// ==========================================
class GauSevakRegistrationScreen extends StatefulWidget {
  const GauSevakRegistrationScreen({super.key});

  @override
  State<GauSevakRegistrationScreen> createState() => _GauSevakRegistrationScreenState();
}

class _GauSevakRegistrationScreenState extends State<GauSevakRegistrationScreen> {
  final List<String> _skillsList = ['First Aid', 'Transport', 'Cow Care', 'Rescue', 'Nursing', 'Awareness', 'Fundraising'];
  final List<String> _selectedSkills = ['Cow Care', 'Rescue'];
  bool _isEmergencyAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('🤝 Gau Sevak Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormInput(label: 'नाम (Name) *', hint: 'अपना पूरा नाम लिखें'),
              const SizedBox(height: 16),
              _buildFormInput(label: 'जिला (District) *', hint: 'जिले का नाम'),
              const SizedBox(height: 16),
              _buildFormInput(label: 'गाँव (Village)', hint: 'गाँव का नाम'),
              const SizedBox(height: 16),
              _buildFormInput(label: 'मोबाइल नंबर (Mobile Number) *', hint: '+91 XXXXX XXXXX', keyboardType: TextInputType.phone),
              const SizedBox(height: 24),

              // Skills Choice Section
              const Text(
                'कौशल चुनें (Skills)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skillsList.map((skill) {
                  bool isSelected = _selectedSkills.contains(skill);
                  return ChoiceChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkills.add(skill);
                        } else {
                          _selectedSkills.remove(skill);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: const Color(0xFFE2E8F0))),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Emergency Availability Switch Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text('आपातकाल में उपलब्ध रहें', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      Switch(
                        value: _isEmergencyAvailable,
                        onChanged: (val) {
                          setState(() {
                            _isEmergencyAvailable = val;
                          });
                        },
                        activeColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ID Proof Upload Card
              const Text(
                'Upload ID Proof',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.file_upload, color: Color(0xFF10B981)),
                  title: const Text('Aadhaar / Voter ID / Driving License', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('फ़ाइल अपलोड करें', style: TextStyle(fontSize: 10)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 32),

              // Register Button
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 रजिस्ट्रेशन सफल! आपका आवेदन रिव्यु में है।')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('पंजीकरण करें (Register)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormInput({
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 5. GAUSHALA REGISTRATION SCREEN
// ==========================================
class GaushalaRegistrationScreen extends StatefulWidget {
  const GaushalaRegistrationScreen({super.key});

  @override
  State<GaushalaRegistrationScreen> createState() => _GaushalaRegistrationScreenState();
}

class _GaushalaRegistrationScreenState extends State<GaushalaRegistrationScreen> {
  bool _medicalSupportAvailable = true;
  bool _donationAccept = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('🏡 Gaushala Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormInput(label: 'गौशाला का नाम (Gaushala Name) *', hint: 'गौशाला नाम लिखें'),
              const SizedBox(height: 16),
              _buildFormInput(label: 'पूरा पता (Full Address) *', hint: 'गाँव, तहसील, जिला...', maxLines: 3),
              const SizedBox(height: 16),
              _buildFormInput(label: 'गायों की क्षमता (Cow Capacity)', hint: '0', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildFormInput(label: 'संपर्क नंबर (Contact Number) *', hint: '+91 XXXXX XXXXX', keyboardType: TextInputType.phone),
              const SizedBox(height: 24),

              // Map Location pin
              const Text(
                'लोकेशन चुनें',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.map, color: Color(0xFF3B82F6)),
                  title: const Text('Map पर Location Pin करें', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('गौशाला की सही स्थिति चुनें', style: TextStyle(fontSize: 10)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 24),

              // Medical Support Available Switch Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Medical Support Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text('चिकित्सा सहायता उपलब्ध है', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      Switch(
                        value: _medicalSupportAvailable,
                        onChanged: (val) {
                          setState(() {
                            _medicalSupportAvailable = val;
                          });
                        },
                        activeColor: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Donation Accept Switch Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Donation Accept करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text('दान स्वीकार करें', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      Switch(
                        value: _donationAccept,
                        onChanged: (val) {
                          setState(() {
                            _donationAccept = val;
                          });
                        },
                        activeColor: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Register Button
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 गौशाला सफलतापूर्वक पंजीकृत की गई!')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('गौशाला पंजीकृत करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormInput({
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}
