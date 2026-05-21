import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GaushalaRegistrationScreen extends StatefulWidget {
  const GaushalaRegistrationScreen({super.key});

  @override
  State<GaushalaRegistrationScreen> createState() => _GaushalaRegistrationScreenState();
}

class _GaushalaRegistrationScreenState extends State<GaushalaRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _medicalSupportAvailable = true;
  bool _donationAccept = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _registerGaushala() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final capacityStr = _capacityController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया आवश्यक जानकारी (*) दर्ज करें।'),
          backgroundColor: Colors.orange,
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
        final capacity = int.tryParse(capacityStr) ?? 0;

        // 1. Save Gaushala record in Firestore
        await FirebaseFirestore.instance.collection('gaushalas').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'address': address,
          'capacity': capacity,
          'phone': phone,
          'medicalSupport': _medicalSupportAvailable,
          'acceptsDonations': _donationAccept,
          'registeredAt': FieldValue.serverTimestamp(),
        });

        // 2. Flag the user profile with isGaushalaOwner true
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'isGaushalaOwner': true,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 गौशाला सफलतापूर्वक पंजीकृत की गई!'),
              backgroundColor: Color(0xFF3B82F6),
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
        title: const Text('🏡 Gaushala Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormInput(label: 'गौशाला का नाम (Gaushala Name) *', hint: 'गौशाला नाम लिखें', controller: _nameController),
                    const SizedBox(height: 16),
                    _buildFormInput(label: 'पूरा पता (Full Address) *', hint: 'गाँव, तहसील, जिला...', maxLines: 3, controller: _addressController),
                    const SizedBox(height: 16),
                    _buildFormInput(label: 'गायों की क्षमता (Cow Capacity)', hint: '0', keyboardType: TextInputType.number, controller: _capacityController),
                    const SizedBox(height: 16),
                    _buildFormInput(
                      label: 'संपर्क नंबर (Contact Number) *',
                      hint: '+91 XXXXX XXXXX',
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                    ),
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
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📍 मैप लोकेशन सफलतापूर्वक सेट की गई (Mock)')),
                          );
                        },
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
                      onPressed: _registerGaushala,
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
          ),
        ),
      ],
    );
  }
}
