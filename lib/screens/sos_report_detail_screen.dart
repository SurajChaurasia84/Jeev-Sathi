import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/cloudinary_service.dart';
import '../services/notification_service.dart';
import '../widgets/safe_avatar.dart';
import '../widgets/banner_ad_widget.dart';

class SOSReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const SOSReportDetailScreen({super.key, required this.data});

  @override
  State<SOSReportDetailScreen> createState() => _SOSReportDetailScreenState();
}

class _SOSReportDetailScreenState extends State<SOSReportDetailScreen> {
  String _placeName = 'स्थान की जानकारी लोड हो रही है...';
  String? _distanceStr;
  late String _currentStatus;
  int _myReportSubTab = 0; // 0 = Accepted list, 1 = Resolved list for reporter's own post

  final Map<String, String?> _photoUrlCache = {};

  Future<String?> _fetchPhotoUrl(String uid) async {
    if (uid.isEmpty) return null;
    if (_photoUrlCache.containsKey(uid)) return _photoUrlCache[uid];
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final url = (doc.data())?['photoUrl'] as String?;
      _photoUrlCache[uid] = url;
      return url;
    } catch (_) {
      _photoUrlCache[uid] = null;
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['status'] ?? 'In Progress (सक्रिय)';
    _loadLocationDetails();
  }

  Future<void> _loadLocationDetails() async {
    final double? reportLat = widget.data['latitude'] is num ? (widget.data['latitude'] as num).toDouble() : null;
    final double? reportLng = widget.data['longitude'] is num ? (widget.data['longitude'] as num).toDouble() : null;

    if (reportLat == null || reportLng == null) {
      if (mounted) {
        setState(() {
          _placeName = 'जयपुर, राजस्थान';
        });
      }
      return;
    }

    String place = 'जयपुर, राजस्थान';
    String? dist;

    // 1. Fetch Reverse Geocode for City/Place Name in words
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$reportLat&lon=$reportLng&zoom=14&addressdetails=1',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'JeevSathiApp/1.0',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(res.body);
        final address = json['address'] as Map<String, dynamic>?;
        if (address != null) {
          final String? suburb = address['suburb'] ?? address['neighbourhood'] ?? address['residential'];
          final String? city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? address['state_district'];
          final String? state = address['state'];

          final List<String> parts = [];
          if (suburb != null && suburb.isNotEmpty) parts.add(suburb);
          if (city != null && city.isNotEmpty && city != suburb) parts.add(city);
          if (parts.isEmpty && state != null && state.isNotEmpty) parts.add(state);

          if (parts.isNotEmpty) {
            place = parts.join(', ');
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }

    // 2. Calculate Distance from Current User
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position? position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        ).timeout(const Duration(seconds: 4));

        final double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          reportLat,
          reportLng,
        );

        if (distanceInMeters >= 1000) {
          dist = '${(distanceInMeters / 1000).toStringAsFixed(1)} km दूर';
        } else {
          dist = '${distanceInMeters.round()} m दूर';
        }
      }
    } catch (e) {
      debugPrint('Geolocator position error: $e');
    }

    if (mounted) {
      setState(() {
        _placeName = place;
        _distanceStr = dist;
      });
    }
  }

  Future<void> _acceptCase(String docId, String animal, String reporterId, String? reporterToken) async {
    final user = FirebaseAuth.instance.currentUser;
    final sevakName = user?.displayName ?? 'सहायक';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('sos_reports').doc(docId).update({
        'status': 'Accepted (स्वीकृत)',
        'acceptedBy': user?.uid,
        'acceptedByName': sevakName,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (reporterId.isNotEmpty && reporterId != 'anonymous') {
        NotificationService.notifySOSAccepted(
          reporterUid: reporterId,
          animal: animal,
          reportId: docId.length >= 6 ? docId.substring(0, 6).toUpperCase() : docId,
          sevakName: sevakName,
          targetToken: reporterToken,
        );
      }

      if (mounted) {
        Navigator.pop(context); // dismiss loader
        setState(() {
          _currentStatus = 'Accepted (स्वीकृत)';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$animal केस स्वीकार किया गया! रिपोर्टर को सूचित किया गया। ✅'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटि: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resolveCase(String docId, String animal, String reporterId, String? reporterToken) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('केस सुलझाएं?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'क्या आप इस SOS रिपोर्ट को सुलझाया हुआ (Resolved) मार्क करना चाहते हैं?',
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
              'सुलझ गया (Resolve)',
              style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('sos_reports').doc(docId).update({
        'status': 'Resolved (सुलझाया)',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (reporterId.isNotEmpty && reporterId != 'anonymous') {
        NotificationService.notifySOSResolved(
          reporterUid: reporterId,
          animal: animal,
          reportId: docId.length >= 6 ? docId.substring(0, 6).toUpperCase() : docId,
          targetToken: reporterToken,
        );
      }

      if (mounted) {
        Navigator.pop(context); // dismiss loader
        setState(() {
          _currentStatus = 'Resolved (सुलझाया)';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('केस को सफलतापूर्वक सुलझाया हुआ मार्क किया गया। 🎉'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटि: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String animal = widget.data['animal'] ?? 'Cow';
    final String id = widget.data['id'] ?? 'SOS';
    final String descRaw = widget.data['description'] ?? '';
    final String desc = descRaw.trim().isEmpty ? 'कोई विवरण उपलब्ध नहीं है।' : descRaw;
    final String? imageUrl = widget.data['imageUrl'];
    final String status = _currentStatus;
    final String creator = widget.data['reporterName'] ?? 'Anonymous';
    final double? lat = widget.data['latitude'] is num ? (widget.data['latitude'] as num).toDouble() : null;
    final double? lng = widget.data['longitude'] is num ? (widget.data['longitude'] as num).toDouble() : null;
    final String reporterId = widget.data['reporterId'] ?? '';
    final String? docId = widget.data['docId'];
    final String? reporterPhone = widget.data['reporterPhone'];
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isMyReport = currentUser != null && currentUser.uid == reporterId;

    final String? acceptedByName = widget.data['acceptedByName'] as String?;
    final String? acceptedByUid = widget.data['acceptedBy'] as String?;
    String? acceptedAtStr;
    if (widget.data['acceptedAt'] != null && widget.data['acceptedAt'] is Timestamp) {
      final Timestamp ts = widget.data['acceptedAt'] as Timestamp;
      final DateTime dt = ts.toDate();
      acceptedAtStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    String? resolvedAtStr;
    if (widget.data['resolvedAt'] != null && widget.data['resolvedAt'] is Timestamp) {
      final Timestamp ts = widget.data['resolvedAt'] as Timestamp;
      final DateTime dt = ts.toDate();
      resolvedAtStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    // Format timestamp if available
    String dateStr = 'हाल ही में';
    if (widget.data['createdAt'] != null) {
      final Timestamp timestamp = widget.data['createdAt'] as Timestamp;
      final DateTime date = timestamp.toDate();
      dateStr = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    String animalEmoji = '🐄';
    if (animal.toLowerCase().contains('dog')) animalEmoji = '🐕';
    if (animal.toLowerCase().contains('cat')) animalEmoji = '🐈';
    if (animal.toLowerCase().contains('bird')) animalEmoji = '🐦';
    if (animal.toLowerCase().contains('buffalo')) animalEmoji = '🐃';
    if (animal.toLowerCase().contains('other')) animalEmoji = '🐾';

    // Status Styling
    Color statusColor = Colors.orange.shade700;
    if (status.contains('Accepted') || status.contains('स्वीकृत')) {
      statusColor = Colors.blue.shade700;
    } else if (status.contains('Resolved') || status.contains('सुलझाया')) {
      statusColor = const Color(0xFF10B981); // Green
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        title: Text(
          'विवरण: #SOS-$id',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: isMyReport
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF0F172A)),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmAndDeleteReport(context, docId);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'रिपोर्ट हटाएं (Delete)',
                              style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Image or Emoji Gradient Header
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
                      ),
                    );
                  },
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Text(
                              animalEmoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      animalEmoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Main Title and Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(animalEmoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            '$animal रेस्क्यू रिपोर्ट',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Info Cards Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person_outline, 'रिपोर्टर', creator),
                        const Divider(height: 24),
                        if (reporterPhone != null && reporterPhone.trim().isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'फ़ोन नंबर',
                            reporterPhone,
                            onTap: () async {
                              final Uri launchUri = Uri(
                                scheme: 'tel',
                                path: reporterPhone.trim(),
                              );
                              try {
                                if (await canLaunchUrl(launchUri)) {
                                  await launchUrl(launchUri, mode: LaunchMode.externalApplication);
                                } else {
                                  await launchUrl(launchUri, mode: LaunchMode.externalApplication);
                                }
                              } catch (e) {
                                debugPrint('Could not launch dialer: $e');
                              }
                            },
                          ),
                          const Divider(height: 24),
                        ],
                        _buildInfoRow(Icons.calendar_today_outlined, 'रिपोर्ट की तारीख', dateStr),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.emergency_outlined, 'रिपोर्ट आईडी', '#SOS-$id'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Description section
                  const Text(
                    'जानवर की स्थिति (Description)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Location section
                  const Text(
                    '📍 घटना का स्थान (Location)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _distanceStr != null
                                    ? '$_placeName • $_distanceStr'
                                    : _placeName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (lat != null && lng != null) ...[
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final Uri googleMapsUrl = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                              );
                              if (await canLaunchUrl(googleMapsUrl)) {
                                await launchUrl(googleMapsUrl);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.navigation, size: 18),
                            label: const Text('दिशा निर्देश प्राप्त करें (Navigate)'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Action Section / Case Activity Section
                  if (isMyReport) ...[
                    const Text(
                      '📋 केस सहायता स्थिति (Case Activity)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subtabs Toggle (Accepted / Resolved)
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _myReportSubTab = 0),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _myReportSubTab == 0 ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _myReportSubTab == 0 ? Colors.blue : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.handshake_outlined,
                                          size: 16,
                                          color: _myReportSubTab == 0 ? Colors.blue.shade700 : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'स्वीकृत (Accepted)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _myReportSubTab == 0 ? Colors.blue.shade700 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _myReportSubTab = 1),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _myReportSubTab == 1 ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _myReportSubTab == 1 ? const Color(0xFF10B981) : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 16,
                                          color: _myReportSubTab == 1 ? const Color(0xFF10B981) : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'सुलझाया (Resolved)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _myReportSubTab == 1 ? const Color(0xFF10B981) : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Subtab 0 Content: Accepted Details
                          if (_myReportSubTab == 0) ...[
                            if (status.contains('Accepted') || status.contains('स्वीकृत') || status.contains('Resolved') || status.contains('सुलझाया') || (acceptedByName != null && acceptedByName.isNotEmpty)) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Row(
                                  children: [
                                     FutureBuilder<String?>(
                                       future: (acceptedByUid != null && acceptedByUid.isNotEmpty)
                                           ? _fetchPhotoUrl(acceptedByUid)
                                           : Future.value(null),
                                       builder: (context, photoSnap) {
                                         return SafeNetworkAvatar(
                                           radius: 20,
                                           backgroundColor: Colors.blue.shade100,
                                           photoUrl: photoSnap.data,
                                           fallbackChild: const Text('🤝', style: TextStyle(fontSize: 18)),
                                         );
                                       },
                                     ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            acceptedByName != null && acceptedByName.isNotEmpty ? acceptedByName : 'गौ सेवक / सहायक',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            acceptedAtStr != null ? 'स्वीकृत समय: $acceptedAtStr' : 'केस सहायता के लिए स्वीकार किया गया है',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Accepted',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: Column(
                                    children: const [
                                      Icon(Icons.hourglass_empty_rounded, size: 36, color: Color(0xFF94A3B8)),
                                      SizedBox(height: 8),
                                      Text(
                                        'अभी तक किसी सहायक ने यह केस स्वीकार नहीं किया है।',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'जैसे ही कोई गौ सेवक सहायता स्वीकार करेगा, यहाँ विवरण आ जाएगा।',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],

                          // Subtab 1 Content: Resolved Details
                          if (_myReportSubTab == 1) ...[
                            if (status.contains('Resolved') || status.contains('सुलझाया') || resolvedAtStr != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                     FutureBuilder<String?>(
                                       future: (acceptedByUid != null && acceptedByUid.isNotEmpty)
                                           ? _fetchPhotoUrl(acceptedByUid)
                                           : Future.value(null),
                                       builder: (context, photoSnap) {
                                         return SafeNetworkAvatar(
                                           radius: 20,
                                           backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                                           photoUrl: photoSnap.data,
                                           fallbackChild: const Text('🎉', style: TextStyle(fontSize: 18)),
                                         );
                                       },
                                     ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'SOS रेस्क्यू पूर्ण',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            resolvedAtStr != null ? 'सुलझाने का समय: $resolvedAtStr' : 'केस सफलता पूर्वक सुलझा लिया गया है',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Resolved',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: Column(
                                    children: const [
                                      Icon(Icons.pending_actions_rounded, size: 36, color: Color(0xFF94A3B8)),
                                      SizedBox(height: 8),
                                      Text(
                                        'यह केस अभी तक सुलझाया नहीं गया है।',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'रेस्क्यू पूरा होने पर यहाँ स्थिति अपडेट हो जाएगी।',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    // Helper Action Section (for other users' posts)
                    const Text(
                      '⚡ केस पर कार्रवाई (Case Actions)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          if (status.contains('Resolved') || status.contains('सुलझाया')) ...[
                            Row(
                              children: const [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'यह SOS रेस्क्यू रिपोर्ट सफलतापूर्वक सुलझाई जा चुकी है। 🎉',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (status.contains('Accepted') || status.contains('स्वीकृत')) ...[
                            Row(
                              children: const [
                                Icon(Icons.volunteer_activism, color: Colors.blue, size: 24),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'यह केस किसी सहायक द्वारा स्वीकार किया गया है और प्रगति पर है।',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: docId == null ? null : () => _resolveCase(docId, animal, reporterId, widget.data['reporterToken']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.check_circle_outline, size: 20),
                                label: const Text(
                                  'केस को सुलझाया हुआ (Resolved) मार्क करें',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'यदि आप पशु की सहायता के लिए जा रहे हैं, तो नीचे दिए बटन पर टैप करके केस स्वीकार करें ताकि रिपोर्टर को आपकी सहायता की सूचना मिल सके।',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: docId == null ? null : () => _acceptCase(docId, animal, reporterId, widget.data['reporterToken']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.handshake_outlined, size: 20),
                                    label: const Text(
                                      'केस स्वीकार करें (Accept SOS)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: docId == null ? null : () => _resolveCase(docId, animal, reporterId, widget.data['reporterToken']),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF10B981),
                                      side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text(
                                      'सुलझाया मार्क करें',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const Spacer(),
        onTap != null
            ? InkWell(
                onTap: onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.call, size: 14, color: Color(0xFF10B981)),
                  ],
                ),
              )
            : Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
      ],
    );
  }

  Future<void> _confirmAndDeleteReport(BuildContext context, String? docId) async {
    if (docId == null || docId.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text(
              'रिपोर्ट हटाएं?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'क्या आप वाकई इस SOS रिपोर्ट को हटाना चाहते हैं? यह कार्रवाई स्थायी है और इसे वापस नहीं लिया जा सकता।',
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
              'हटाएं (Delete)',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
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
        final String? imageUrl = widget.data['imageUrl'];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            await CloudinaryService.deleteImage(imageUrl);
          } catch (_) {}
        }

        await FirebaseFirestore.instance.collection('sos_reports').doc(docId).delete();

        if (context.mounted) {
          Navigator.pop(context); // Dismiss loader
          Navigator.pop(context); // Go back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('रिपोर्ट सफलतापूर्वक हटा दी गई। (Report deleted successfully)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Dismiss loader
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('हटाने में विफल: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
