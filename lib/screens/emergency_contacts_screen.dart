import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/banner_ad_widget.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _guardianPhoneController = TextEditingController();
  
  final TextEditingController _friendNameController = TextEditingController();
  final TextEditingController _friendPhoneController = TextEditingController();

  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _includeLocation = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyDetails();
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _friendNameController.dispose();
    _friendPhoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data();
          if (data != null) {
            _parentNameController.text = data['emergencyContactName1'] ?? '';
            _parentPhoneController.text = data['emergencyContactPhone1'] ?? '';
            
            _guardianNameController.text = data['emergencyContactName2'] ?? '';
            _guardianPhoneController.text = data['emergencyContactPhone2'] ?? '';
            
            _friendNameController.text = data['emergencyContactName3'] ?? '';
            _friendPhoneController.text = data['emergencyContactPhone3'] ?? '';

            _messageController.text = data['emergencyMessage'] ?? 
                '🚨 EMERGENCY! I am in danger, please help me immediately. Here is my location:';
            _includeLocation = data['includeLocation'] ?? true;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('डेटा लोड करने में त्रुटि: ${e.toString()}'),
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

  Future<void> _saveEmergencyDetails() async {
    final pName = _parentNameController.text.trim();
    final pPhone = _parentPhoneController.text.trim();
    final gName = _guardianNameController.text.trim();
    final gPhone = _guardianPhoneController.text.trim();
    final fName = _friendNameController.text.trim();
    final fPhone = _friendPhoneController.text.trim();
    final msg = _messageController.text.trim();

    if (pName.isEmpty && pPhone.isEmpty && gName.isEmpty && gPhone.isEmpty && fName.isEmpty && fPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया कम से कम एक आपातकालीन संपर्क (Emergency Contact) दर्ज करें।'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Quick validation: If name is filled, phone must be filled, and vice versa
    if ((pName.isNotEmpty && pPhone.isEmpty) || (pName.isEmpty && pPhone.isNotEmpty)) {
      _showWarningSnackBar('कृपया माता-पिता (Parent) का पूरा विवरण (नाम और नंबर दोनों) दर्ज करें।');
      return;
    }
    if ((gName.isNotEmpty && gPhone.isEmpty) || (gName.isEmpty && gPhone.isNotEmpty)) {
      _showWarningSnackBar('कृपया अभिभावक (Guardian) का पूरा विवरण दर्ज करें।');
      return;
    }
    if ((fName.isNotEmpty && fPhone.isEmpty) || (fName.isEmpty && fPhone.isNotEmpty)) {
      _showWarningSnackBar('कृपया मित्र (Friend) का पूरा विवरण दर्ज करें।');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'emergencyContactName1': pName,
          'emergencyContactPhone1': pPhone,
          'emergencyContactName2': gName,
          'emergencyContactPhone2': gPhone,
          'emergencyContactName3': fName,
          'emergencyContactPhone3': fPhone,
          'emergencyMessage': msg.isNotEmpty ? msg : '🚨 EMERGENCY! I am in danger, please help me immediately.',
          'includeLocation': _includeLocation,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 आपातकालीन संपर्क विवरण सफलतापूर्वक सहेजे गए!'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('सहेजने में त्रुटि: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showWarningSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        title: const Text(
          '🚨 Emergency SOS Setup',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Explanation Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFFEE2E2)),
                      ),
                      color: const Color(0xFFFEF2F2),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text('🚨', style: TextStyle(fontSize: 32)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'महिला सुरक्षा SOS सेटअप',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'जब आप होम स्क्रीन पर SOS दबाएंगे, तब इन नंबरों पर आपका संकट संदेश और जीपीएस लोकेशन भेजी जाएगी। कृपया कम से कम 1 संपर्क अवश्य भरें।',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF7F1D1D), height: 1.4),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contact 1: Parent
                    _buildContactCard(
                      title: 'माता-पिता (Parent)',
                      nameHint: 'माता या पिता का नाम लिखें',
                      nameController: _parentNameController,
                      phoneController: _parentPhoneController,
                      icon: Icons.family_restroom,
                    ),
                    const SizedBox(height: 16),

                    // Contact 2: Guardian
                    _buildContactCard(
                      title: 'अभिभावक (Guardian)',
                      nameHint: 'अभिभावक का नाम लिखें',
                      nameController: _guardianNameController,
                      phoneController: _guardianPhoneController,
                      icon: Icons.shield,
                    ),
                    const SizedBox(height: 16),

                    // Contact 3: Friend
                    _buildContactCard(
                      title: 'मित्र / अन्य (Friend / Other)',
                      nameHint: 'मित्र का नाम लिखें',
                      nameController: _friendNameController,
                      phoneController: _friendPhoneController,
                      icon: Icons.people_outline,
                    ),
                    const SizedBox(height: 20),

                    // Custom Distress Message Section
                    const Text(
                      'आपातकालीन संदेश (SOS Message)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'संकट के समय भेजे जाने वाला संदेश लिखें...',
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Include GPS Location Switch
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: SwitchListTile(
                        activeThumbColor: const Color(0xFFEF4444),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: const Text(
                          'लाइव लोकेशन शामिल करें',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        subtitle: const Text(
                          'अलर्ट संदेश के साथ आपका GPS स्थान भी भेजा जाएगा',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        value: _includeLocation,
                        onChanged: (bool val) {
                          setState(() {
                            _includeLocation = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveEmergencyDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('विवरण सुरक्षित करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildContactCard({
    required String title,
    required String nameHint,
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFEF4444), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            
            // Name Field
            const Text('नाम (Name)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: nameHint,
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Phone Field
            const Text('मोबाइल नंबर (Mobile Number)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+91 XXXXX XXXXX',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
