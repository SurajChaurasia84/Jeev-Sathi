import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sos_report_detail_screen.dart';
import '../services/notification_service.dart';

class GauSevakDashboardScreen extends StatefulWidget {
  const GauSevakDashboardScreen({super.key});

  @override
  State<GauSevakDashboardScreen> createState() => _GauSevakDashboardScreenState();
}

class _GauSevakDashboardScreenState extends State<GauSevakDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markCaseAsResolved(
    BuildContext context,
    String docId,
    String animalName, {
    String reporterId = '',
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              '$animalName रेस्क्यू!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'क्या आप वाकई इस रिपोर्ट को सुलझाया हुआ (Resolved) मार्क करना चाहते हैं? इससे सभी गौ सेवकों को सूचित हो जाएगा कि जानवर सुरक्षित है।',
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

    if (confirm == true && context.mounted) {
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
          'status': 'Resolved (सुलझाया)'
        });

        // Notify the SOS reporter that their case is resolved
        if (reporterId.isNotEmpty && reporterId != 'anonymous') {
          NotificationService.notifySOSResolved(
            reporterUid: reporterId,
            animal: animalName,
            reportId: docId.substring(0, 6).toUpperCase(),
          );
        }

        if (context.mounted) {
          Navigator.pop(context); // Dismiss loader
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('केस को सफलतापूर्वक सुलझाया हुआ मार्क किया गया। 🎉'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Dismiss loader
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('अपडेट करने में विफल: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Marks a case as Accepted and notifies the SOS reporter.
  Future<void> _acceptCase(
    BuildContext context,
    String docId,
    String animalName, {
    required String reporterId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final sevakName = user?.displayName ?? 'गौ सेवक';

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

      // Notify the SOS reporter
      if (reporterId.isNotEmpty && reporterId != 'anonymous') {
        NotificationService.notifySOSAccepted(
          reporterUid: reporterId,
          animal: animalName,
          reportId: docId.substring(0, 6).toUpperCase(),
          sevakName: sevakName,
        );
      }

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$animalName केस स्वीकार किया गया! रिपोर्टर को सूचित किया गया। ✅'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('अपडेट करने में विफल: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'गौ सेवक डैशबोर्ड (Gau Sevak)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF10B981),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(
              icon: Icon(Icons.emergency_outlined, size: 20),
              text: 'सक्रिय केस (Active)',
            ),
            Tab(
              icon: Icon(Icons.task_alt, size: 20),
              text: 'सुलझाए गए (Resolved)',
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sos_reports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState('कोई SOS रिपोर्ट नहीं मिली।');
          }

          final allDocs = snapshot.data!.docs;

          // Process and Filter docs client-side
          final List<QueryDocumentSnapshot> activeCases = [];
          final List<QueryDocumentSnapshot> resolvedCases = [];

          for (final doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final String status = data['status'] ?? 'Active';
            final bool isResolved = status.contains('Resolved') || status.contains('सुलझाया');

            if (isResolved) {
              resolvedCases.add(doc);
            } else {
              activeCases.add(doc);
            }
          }

          // Sort by createdAt descending
          int sortFunction(QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final Timestamp? aTime = aData['createdAt'] as Timestamp?;
            final Timestamp? bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          }

          activeCases.sort(sortFunction);
          resolvedCases.sort(sortFunction);

          return Column(
            children: [
              // Welcome & Stats Banner
              _buildStatsHeader(user?.displayName ?? 'गौ सेवक', activeCases.length, resolvedCases.length),
              
              // Tabs Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCasesList(activeCases, isActive: true),
                    _buildCasesList(resolvedCases, isActive: false),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(String name, int activeCount, int resolvedCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF10B981), const Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'नमस्ते, $name 🤝',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'जीव दया ही सबसे बड़ा धर्म है। आपके रेस्क्यू का विवरण नीचे है:',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBadge('सक्रिय मामले', activeCount.toString(), Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBadge('आपके योगदान (Resolved)', resolvedCount.toString(), Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color badgeColor) {
    final isWhite = badgeColor == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white.withValues(alpha: 0.2) : badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCasesList(List<QueryDocumentSnapshot> cases, {required bool isActive}) {
    if (cases.isEmpty) {
      return _buildEmptyState(isActive ? 'कोई सक्रिय रेस्क्यू केस नहीं है।' : 'कोई सुलझाया हुआ केस नहीं है।');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final doc = cases[index];
        final data = doc.data() as Map<String, dynamic>;

        // Ensure docId is present
        final Map<String, dynamic> rawData = Map<String, dynamic>.from(data);
        rawData['docId'] = doc.id;
        final String docIdStr = rawData['id'] ?? doc.id.substring(0, 6).toUpperCase();
        if (!rawData.containsKey('id')) {
          rawData['id'] = docIdStr;
        }

        final String animal = data['animal'] ?? 'Cow';
        final String creator = data['reporterName'] ?? 'Anonymous';
        final String reporterId = data['reporterId'] ?? '';
        final String? imageUrl = data['imageUrl'];
        final String description = data['description'] ?? '';
        final String status = data['status'] ?? 'Active';
        final bool isAccepted = status.contains('Accepted') || status.contains('स्वीकृत');

        final double? lat = data['latitude'] is num ? (data['latitude'] as num).toDouble() : null;
        final double? lng = data['longitude'] is num ? (data['longitude'] as num).toDouble() : null;
        final String locationText = (lat != null && lng != null)
            ? '📍 स्थान: ${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E'
            : 'जयपुर राजस्थान';

        String dateStr = 'हाल ही में';
        if (data['createdAt'] != null) {
          final Timestamp timestamp = data['createdAt'] as Timestamp;
          final DateTime date = timestamp.toDate();
          dateStr = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
        }

        String animalEmoji = '🐄';
        if (animal.toLowerCase().contains('dog')) animalEmoji = '🐕';
        if (animal.toLowerCase().contains('cat')) animalEmoji = '🐈';
        if (animal.toLowerCase().contains('bird')) animalEmoji = '🐦';
        if (animal.toLowerCase().contains('buffalo')) animalEmoji = '🐃';
        if (animal.toLowerCase().contains('other')) animalEmoji = '🐾';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          child: Column(
            children: [
              // Top Row layout
              SizedBox(
                height: 100,
                child: Row(
                  children: [
                    // Image Left
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Text(animalEmoji, style: const TextStyle(fontSize: 32)),
                              ),
                            ),
                    ),
                    // Details Right
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '#SOS-$docIdStr • $creator',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.orange.withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: isActive ? Colors.orange.shade700 : const Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$animal $animalEmoji',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              description.trim().isNotEmpty ? description.trim() : 'घटना की स्थान पर पहुंचे।',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    locationText,
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons Bottom
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Route/Navigate button
                    if (lat != null && lng != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          foregroundColor: const Color(0xFF10B981),
                        ),
                        onPressed: () async {
                          final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                          if (await canLaunchUrl(googleMapsUrl)) {
                            await launchUrl(googleMapsUrl);
                          }
                        },
                        icon: const Icon(Icons.navigation, size: 14),
                        label: const Text('दिशा (Route)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 8),
                    // Details Screen navigation
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(60, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        foregroundColor: const Color(0xFF334155),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SOSReportDetailScreen(data: rawData),
                          ),
                        );
                      },
                      child: const Text('विवरण (Details)', style: TextStyle(fontSize: 11)),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      // Accept button (only if not already accepted)
                      if (!isAccepted)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(60, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            foregroundColor: const Color(0xFF10B981),
                          ),
                          onPressed: () => _acceptCase(
                            context,
                            doc.id,
                            animal,
                            reporterId: reporterId,
                          ),
                          child: const Text('स्वीकार करें', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(width: 8),
                      // Mark resolved button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        onPressed: () => _markCaseAsResolved(
                          context,
                          doc.id,
                          animal,
                          reporterId: reporterId,
                        ),
                        child: const Text('मार्क सुलझ गया', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
