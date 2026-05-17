import 'package:flutter/material.dart';

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
                          const Icon(Icons.camera_alt, color: Color(0xFF10B981), size: 28),
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
