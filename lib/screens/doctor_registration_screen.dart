import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() => _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _emergencySupportAvailable = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _registerDoctor() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final specialization = _specializationController.text.trim();
    final experienceStr = _experienceController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || address.isEmpty || specialization.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया आवश्यक जानकारी (*) दर्ज करें।'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final experience = int.tryParse(experienceStr) ?? 0;

        // 1. Save Doctor record in Firestore 'doctors' collection
        await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'clinicAddress': address,
          'specialization': specialization,
          'experience': experience,
          'phone': phone,
          'emergencySupport': _emergencySupportAvailable,
          'registeredAt': FieldValue.serverTimestamp(),
        });

        // 2. Flag the user profile with isDoctor true
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'isDoctor': true,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 पशु चिकित्सक पंजीकरण सफलतापूर्वक संपन्न हुआ!'),
              backgroundColor: Color(0xFFEC4899),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception("उपयोगकर्ता लॉग इन नहीं है।");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('त्रुटि: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
        title: const Text(
          '🩺 Doctor Registration',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEC4899),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Info Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: const Color(0xFFF0FDF4), // Emerald 50 tint for health/medical feel
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text('🩺', style: TextStyle(fontSize: 32)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'पशु चिकित्सक पंजीकरण',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'घायल और असहाय पशुओं के इलाज में अपना अमूल्य सहयोग देने के लिए रजिस्टर करें।',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF15803D), height: 1.4),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildFormInput(
                      label: 'डॉक्टर का नाम (Doctor\'s Name) *',
                      hint: 'डॉक्टर का नाम लिखें',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    _buildFormInput(
                      label: 'विशेषज्ञता / योग्यता (Specialization / Degree) *',
                      hint: 'जैसे: B.V.Sc & A.H, M.V.Sc...',
                      controller: _specializationController,
                    ),
                    const SizedBox(height: 16),
                    _buildFormInput(
                      label: 'अनुभव (Experience in Years)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      controller: _experienceController,
                    ),
                    const SizedBox(height: 16),
                    _buildFormInput(
                      label: 'संपर्क नंबर (Contact Number) *',
                      hint: '+91 XXXXX XXXXX',
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 16),
                    _buildFormInput(
                      label: 'क्लिनिक / अस्पताल का पता (Clinic Address) *',
                      hint: 'क्लिनिक का नाम, गली, शहर...',
                      maxLines: 3,
                      controller: _addressController,
                    ),
                    const SizedBox(height: 24),

                    // Location Selector Mock
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
                        leading: const Icon(Icons.map_rounded, color: Color(0xFFEC4899)),
                        title: const Text('Map पर Location Pin करें', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: const Text('अपने क्लिनिक / सेवा क्षेत्र की सही स्थिति चुनें', style: TextStyle(fontSize: 10)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📍 मैप लोकेशन सफलतापूर्वक सेट की गई (Mock)'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Emergency Switch Card
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
                                Text(
                                  'Emergency Support Available',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'आपातकालीन चिकित्सा सहायता के लिए उपलब्ध',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            Switch(
                              value: _emergencySupportAvailable,
                              onChanged: (val) {
                                setState(() {
                                  _emergencySupportAvailable = val;
                                });
                              },
                              activeThumbColor: const Color(0xFFEC4899),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    ElevatedButton(
                      onPressed: _registerDoctor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('डॉक्टर पंजीकृत करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEC4899), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
