import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sos_report_detail_screen.dart';

class AllSOSReportsScreen extends StatefulWidget {
  const AllSOSReportsScreen({super.key});

  @override
  State<AllSOSReportsScreen> createState() => _AllSOSReportsScreenState();
}

class _AllSOSReportsScreenState extends State<AllSOSReportsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<QueryDocumentSnapshot> _reports = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 6;

  @override
  void initState() {
    super.initState();
    _fetchInitialReports();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchMoreReports();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialReports() async {
    // 1. Try Cache First
    try {
      final query = FirebaseFirestore.instance
          .collection('sos_reports')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);
      
      final cacheSnapshot = await query.get(const GetOptions(source: Source.cache));
      
      if (cacheSnapshot.docs.isNotEmpty) {
        setState(() {
          _reports.clear();
          _reports.addAll(cacheSnapshot.docs);
          _lastDocument = cacheSnapshot.docs.last;
          if (cacheSnapshot.docs.length < _pageSize) {
            _hasMore = false;
          } else {
            _hasMore = true;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
    }

    // 2. Try Server
    try {
      final query = FirebaseFirestore.instance
          .collection('sos_reports')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);
      
      final serverSnapshot = await query.get(const GetOptions(source: Source.server));
      
      if (serverSnapshot.docs.isNotEmpty) {
        setState(() {
          _reports.clear();
          _reports.addAll(serverSnapshot.docs);
          _lastDocument = serverSnapshot.docs.last;
          if (serverSnapshot.docs.length < _pageSize) {
            _hasMore = false;
          } else {
            _hasMore = true;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _reports.clear();
          _hasMore = false;
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

  Future<void> _fetchMoreReports() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      var query = FirebaseFirestore.instance
          .collection('sos_reports')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);
      
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        setState(() {
          _reports.addAll(snapshot.docs);
          if (snapshot.docs.length < _pageSize) {
            _hasMore = false;
          }
        });
      } else {
        setState(() {
          _hasMore = false;
        });
      }
    } catch (_) {
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'सभी SOS रिपोर्ट्स (All SOS Reports)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            )
          : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🐾', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        'कोई सक्रिय SOS रिपोर्ट उपलब्ध नहीं है।',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 140 / 220, // Matching home screen card ratio
                  ),
                  itemCount: _reports.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _reports.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        ),
                      );
                    }

                    final doc = _reports[index];
                    final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
                    data['docId'] = doc.id;

                    final String animal = data['animal'] ?? 'Cow';
                    final String creator = data['reporterName'] ?? 'Anonymous';
                    final String? imageUrl = data['imageUrl'];
                    final String status = data['status'] ?? 'Active';
                    final String? description = data['description'];

                    return SOSReportCard(
                      imageUrl: imageUrl,
                      animal: animal,
                      description: description,
                      status: status,
                      creator: creator,
                      rawData: data,
                    );
                  },
                ),
    );
  }
}

class SOSReportCard extends StatelessWidget {
  final String? imageUrl;
  final String animal;
  final String? description;
  final String status;
  final String creator;
  final Map<String, dynamic> rawData;

  const SOSReportCard({
    super.key,
    required this.imageUrl,
    required this.animal,
    required this.description,
    required this.status,
    required this.creator,
    required this.rawData,
  });

  @override
  Widget build(BuildContext context) {
    String animalEmoji = '🐄';
    if (animal.toLowerCase().contains('dog')) animalEmoji = '🐕';
    if (animal.toLowerCase().contains('cat')) animalEmoji = '🐈';
    if (animal.toLowerCase().contains('bird')) animalEmoji = '🐦';
    if (animal.toLowerCase().contains('buffalo')) animalEmoji = '🐃';
    if (animal.toLowerCase().contains('other')) animalEmoji = '🐾';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SOSReportDetailScreen(data: rawData),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Text(animalEmoji, style: const TextStyle(fontSize: 32)),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                        ),
                      ),
                      child: Center(
                        child: Text(animalEmoji, style: const TextStyle(fontSize: 40)),
                      ),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        animal,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (description != null && description!.trim().isNotEmpty)
                      Text(
                        description!.trim(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: TextStyle(
                        color: status.contains('Resolved') || status.contains('सुलझाया')
                            ? const Color(0xFF10B981)
                            : Colors.orange.shade400,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      creator,
                      style: const TextStyle(color: Colors.white70, fontSize: 9),
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
}
