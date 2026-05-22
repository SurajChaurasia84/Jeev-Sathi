import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  int _activeSubTab = 0; // 0 = Report, 1 = Status, 2 = Sevak
  String _selectedAnimal = 'Cow';
  bool _isUploadingPhoto = false;
  bool _isAddingLocation = false;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      final File file = File(pickedFile.path);
      final String url = await CloudinaryService.uploadImage(file);

      setState(() {
        _uploadedImageUrl = url;
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 फोटो सफलतापूर्वक अपलोड की गई!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingPhoto = false;
      });
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('Cloudinary setup is incomplete')) {
          errorMsg = 'क्लाउडिनरी सेटअप अधूरा है। कृपया Config फाइल सेट करें।';
        } else if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('फ़ोटो अपलोड करने में त्रुटि: $errorMsg'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  final List<DocumentSnapshot> _gauSevaks = [];
  bool _isLoadingSevaks = false;
  bool _hasMoreSevaks = true;
  DocumentSnapshot? _lastSevakDocument;
  late final ScrollController _sevakScrollController;

  @override
  void initState() {
    super.initState();
    _sevakScrollController = ScrollController();
    _sevakScrollController.addListener(() {
      if (_sevakScrollController.position.pixels >=
          _sevakScrollController.position.maxScrollExtent - 200) {
        _loadMoreGauSevaks();
      }
    });
    _loadMoreGauSevaks();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isAddingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('कृपया अपने फोन की GPS/लोकेशन सेवा चालू करें।'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isAddingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('स्थान अनुमति (Location permission) अस्वीकार कर दी गई।'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isAddingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('स्थान अनुमति हमेशा के लिए अस्वीकार कर दी गई है। कृपया सेटिंग से अनुमति दें।'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isAddingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isAddingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 लाइव लोकेशन प्राप्त हो चुकी है: ${_latitude!.toStringAsFixed(4)}° N, ${_longitude!.toStringAsFixed(4)}° E'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          setState(() {
            _latitude = lastPosition.latitude;
            _longitude = lastPosition.longitude;
            _isAddingLocation = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📍 अंतिम ज्ञात स्थान प्राप्त किया गया: ${_latitude!.toStringAsFixed(4)}° N, ${_longitude!.toStringAsFixed(4)}° E'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      } catch (_) {}

      setState(() {
        _isAddingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('स्थान प्राप्त करने में विफल: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreGauSevaks() async {
    if (_isLoadingSevaks || !_hasMoreSevaks) return;

    setState(() {
      _isLoadingSevaks = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('gau_sevaks')
          .orderBy('registeredAt', descending: true)
          .limit(10);

      if (_lastSevakDocument != null) {
        query = query.startAfterDocument(_lastSevakDocument!);
      }

      final QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.length < 10) {
        _hasMoreSevaks = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastSevakDocument = querySnapshot.docs.last;
        setState(() {
          _gauSevaks.addAll(querySnapshot.docs);
        });
      }
    } catch (e) {
      debugPrint("Error loading gau sevaks: $e");
    } finally {
      setState(() {
        _isLoadingSevaks = false;
      });
    }
  }

  Future<void> _refreshGauSevaks() async {
    setState(() {
      _gauSevaks.clear();
      _lastSevakDocument = null;
      _hasMoreSevaks = true;
    });
    await _loadMoreGauSevaks();
  }

  @override
  void dispose() {
    _sevakScrollController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitSOSAlert() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final reportsRef = FirebaseFirestore.instance.collection('sos_reports');
      final newReportDoc = reportsRef.doc();

      await newReportDoc.set({
        'id': newReportDoc.id.substring(0, 6).toUpperCase(),
        'animal': _selectedAnimal,
        'description': _descriptionController.text.trim(),
        'latitude': _latitude ?? 26.9124,
        'longitude': _longitude ?? 75.7873,
        'imageUrl': _uploadedImageUrl,
        'status': 'In Progress (सक्रिय)',
        'createdAt': FieldValue.serverTimestamp(),
        'reporterId': user?.uid ?? 'anonymous',
        'reporterName': user?.displayName ?? 'Anonymous User',
      });

      _descriptionController.clear();
      setState(() {
        _uploadedImageUrl = null;
      });

      if (mounted) {
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
              'आपका इमरजेंसी SOS अलर्ट सफलतापूर्वक भेज दिया गया है। नजदीकी गौ सेवकों और संबंधित एनजीओ को सूचित किया जा रहा है। कृपया स्थान पर बने रहें।',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('त्रुटि: ${e.toString()}'),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
              ),
            )
          : Column(
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
              'फोटो जोड़ें (Add Photo)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickAndUploadImage(ImageSource.camera),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt, color: Color(0xFF10B981), size: 28),
                          SizedBox(height: 8),
                          Text('Camera / कैमरा', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickAndUploadImage(ImageSource.gallery),
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
                padding: EdgeInsets.only(top: 12.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      color: Color(0xFFEF4444),
                      backgroundColor: Color(0xFFFEE2E2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'फोटो अपलोड हो रही है, कृपया प्रतीक्षा करें...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            if (_uploadedImageUrl != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      image: DecorationImage(
                        image: NetworkImage(_uploadedImageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _uploadedImageUrl = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
                onTap: _isAddingLocation ? null : _getCurrentLocation,
                leading: Icon(
                  Icons.location_on,
                  color: _latitude != null ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 28,
                ),
                title: Text(
                  _latitude != null
                      ? '📍 लाइव स्थान: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                      : 'टैप करें — GPS से Location जोड़ें',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _latitude != null
                      ? 'स्थान सफलतापूर्वक जोड़ा गया (GPS Coordinates Attached)'
                      : 'सटीक रेस्क्यू के लिए आवश्यक',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: _isAddingLocation
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : (_latitude != null
                        ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
                        : const Icon(Icons.arrow_forward_ios, size: 14)),
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
              controller: _descriptionController,
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



            // Submit Button
            ElevatedButton(
              onPressed: _submitSOSAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: const Text(
                'Submit Report',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  // Sub Tab 2: REAL-TIME STATUS LIST (Firestore Stream)
  Widget _buildStatusTab() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'anonymous';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_reports')
          .where('reporterId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📝', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'कोई SOS रिपोर्ट नहीं मिली।',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }

        // Sort documents client-side by createdAt descending to avoid custom index requirement
        final sortedDocs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final Timestamp? aTime = aData['createdAt'] as Timestamp?;
          final Timestamp? bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;

            final String idStr = data['id'] ?? doc.id.substring(0, 6).toUpperCase();
            final String animalStr = data['animal'] ?? 'Cow';
            final String descStr = data['description'] ?? '';
            final String statusStr = data['status'] ?? 'In Progress (सक्रिय)';
            
            // Format Timestamp
            String timeStr = 'अभी';
            if (data['createdAt'] != null) {
              final timestamp = data['createdAt'] as Timestamp;
              final diff = DateTime.now().difference(timestamp.toDate());
              if (diff.inMinutes < 60) {
                timeStr = '${diff.inMinutes} मिनट पहले';
              } else if (diff.inHours < 24) {
                timeStr = '${diff.inHours} घंटे पहले';
              } else {
                timeStr = '${diff.inDays} दिन पहले';
              }
            }

            // Determine status color
            Color statusColor = Colors.orange.shade700;
            if (statusStr.contains('Resolved') || statusStr.contains('सुलझाया')) {
              statusColor = const Color(0xFF10B981);
            }

            final double? lat = data['latitude'] is num ? (data['latitude'] as num).toDouble() : null;
            final double? lng = data['longitude'] is num ? (data['longitude'] as num).toDouble() : null;
            final String locationText = (lat != null && lng != null)
                ? '📍 स्थान: ${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E'
                : 'जयपुर राजस्थान (26.91° N, 75.78° E)';

            final String? imageUrlStr = data['imageUrl'];

            return _buildStatusItem(
              id: '#SOS-$idStr',
              animal: animalStr,
              description: descStr,
              location: locationText,
              status: statusStr,
              statusColor: statusColor,
              time: timeStr,
              imageUrl: imageUrlStr,
            );
          },
        );
      },
    );
  }

  Widget _buildStatusItem({
    required String id,
    required String animal,
    required String description,
    required String location,
    required String status,
    required Color statusColor,
    required String time,
    String? imageUrl,
  }) {
    String animalEmoji = '🐄';
    if (animal.toLowerCase().contains('dog')) animalEmoji = '🐕';
    if (animal.toLowerCase().contains('cat')) animalEmoji = '🐈';
    if (animal.toLowerCase().contains('bird')) animalEmoji = '🐦';
    if (animal.toLowerCase().contains('buffalo')) animalEmoji = '🐃';
    if (animal.toLowerCase().contains('other')) animalEmoji = '🐾';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
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
                    color: statusColor.withValues(alpha: 0.1),
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
                Text(animalEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text('$animal ($animalEmoji)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                ),
              ),
            ],
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey, size: 36),
                            SizedBox(height: 8),
                            Text(
                              'छवि लोड करने में विफल',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(location, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                ),
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


  // Sub Tab 3: SEVAK ROSTER DIRECTORY (Firestore Paginated List)
  Widget _buildSevakTab() {
    if (_gauSevaks.isEmpty && _isLoadingSevaks) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
        ),
      );
    }

    if (_gauSevaks.isEmpty && !_isLoadingSevaks) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🤝', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'कोई पंजीकृत गौ सेवक उपलब्ध नहीं है।',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'सेवा से जुड़ने के लिए प्रोफाइल में पंजीकरण करें!',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshGauSevaks,
      color: const Color(0xFFEF4444),
      child: ListView.builder(
        controller: _sevakScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _gauSevaks.length + (_hasMoreSevaks ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _gauSevaks.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                ),
              ),
            );
          }

          final doc = _gauSevaks[index];
          final data = doc.data() as Map<String, dynamic>;

          final String nameStr = data['name'] ?? 'Gau Sevak';
          final String districtStr = data['district'] ?? 'Rajasthan';
          final String villageStr = data['village'] ?? '';
          final String phoneStr = data['phone'] ?? '';
          final List<dynamic> skillsList = data['skills'] ?? ['First Aid', 'Rescue'];
          final bool isAvailable = data['isAvailable'] ?? true;

          final skillsStr = skillsList.join(', ');
          final addressStr = villageStr.isNotEmpty ? '$villageStr, $districtStr' : districtStr;

          return _buildSevakItem(
            name: nameStr,
            distance: addressStr,
            skills: skillsStr,
            phone: phoneStr,
            isAvailable: isAvailable,
          );
        },
      ),
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
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
          child: const Text('🤝', style: TextStyle(fontSize: 18)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
          onPressed: () {
            _showCallDialog(context, name, phone);
          },
        ),
      ),
    );
  }

  void _showCallDialog(BuildContext context, String name, String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            const Text('संपर्क करें (Call)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('क्या आप $name से संपर्क करना चाहते हैं?', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    phone,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📋 नंबर क्लिपबोर्ड पर कॉपी किया गया!')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करें', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('📞 $phone पर कॉल लगाया जा रहा है...')),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('कॉल करें'),
          ),
        ],
      ),
    );
  }
}
