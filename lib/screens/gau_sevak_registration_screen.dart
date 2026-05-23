import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GauSevakRegistrationScreen extends StatefulWidget {
  const GauSevakRegistrationScreen({super.key});

  @override
  State<GauSevakRegistrationScreen> createState() => _GauSevakRegistrationScreenState();
}

class _GauSevakRegistrationScreenState extends State<GauSevakRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final List<String> _skillsList = ['First Aid', 'Transport', 'Cow Care', 'Rescue', 'Nursing', 'Awareness', 'Fundraising'];
  final List<String> _selectedSkills = ['Cow Care', 'Rescue'];
  bool _isEmergencyAvailable = true;
  bool _isLoading = false;
  bool _isAlreadyRegistered = false;

  @override
  void initState() {
    super.initState();
    _loadRegistrationDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrationDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('gau_sevaks')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _nameController.text = data['name'] ?? '';
          _districtController.text = data['district'] ?? '';
          _villageController.text = data['village'] ?? '';
          _phoneController.text = data['phone'] ?? '';

          if (data['skills'] != null) {
            _selectedSkills.clear();
            _selectedSkills.addAll(List<String>.from(data['skills']));
          }

          _isEmergencyAvailable = data['isAvailable'] ?? true;
          _isAlreadyRegistered = true;
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _registerGauSevak() async {
    if (_formKey.currentState!.validate() == false) {
      return;
    }

    final name = _nameController.text.trim();
    final district = _districtController.text.trim();
    final village = _villageController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Save volunteer details in Firestore
        await FirebaseFirestore.instance.collection('gau_sevaks').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'district': district,
          'village': village,
          'phone': phone,
          'skills': _selectedSkills,
          'isAvailable': _isEmergencyAvailable,
          'registeredAt': FieldValue.serverTimestamp(),
        });

        // 2. Flag the user profile with isGauSevak true
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isGauSevak': true,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isAlreadyRegistered
                  ? '🎉 विवरण सफलतापूर्वक अपडेट किया गया!'
                  : '🎉 रजिस्ट्रेशन सफल! आपका आवेदन रिव्यु में है।'),
              backgroundColor: const Color(0xFF10B981),
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

  Future<void> _showSubmitConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _isAlreadyRegistered ? 'विवरण अपडेट करें?' : 'पंजीकरण करें?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  _isAlreadyRegistered
                      ? 'क्या आप अपना Gau Sevak विवरण अपडेट करना चाहते हैं?'
                      : 'क्या आप गौ सेवक के रूप में पंजीकरण सबमिट करना चाहते हैं?',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('नहीं (No)', style: TextStyle(color: Color(0xFF64748B))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
              ),
              child: const Text('हाँ, सबमिट करें (Yes, Submit)', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _registerGauSevak(); // Actually perform save
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('पंजीकरण रद्द करें?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('क्या आप वाकई अपना Gau Sevak पंजीकरण रद्द करना चाहते हैं?'),
                SizedBox(height: 8),
                Text('यह क्रिया पूर्ववत नहीं की जा सकती और आपका सारा डेटा हटा दिया जाएगा।', style: TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('नहीं (No)', style: TextStyle(color: Color(0xFF64748B))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('हाँ, हटाएं (Yes, Delete)', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteGauSevakRegistration();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGauSevakRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Delete volunteer details from Firestore
        await FirebaseFirestore.instance.collection('gau_sevaks').doc(user.uid).delete();

        // 2. Set isGauSevak flag to false in users collection
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isGauSevak': false,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 आपका गौ सेवक पंजीकरण सफलतापूर्वक रद्द कर दिया गया है।'),
              backgroundColor: Color(0xFF10B981),
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
        title: const Text('🤝 Gau Sevak Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        actions: _isAlreadyRegistered
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmationDialog();
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
                            Text('पंजीकरण रद्द करें', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormInput(
                        label: 'नाम (Name) *',
                        hint: 'अपना पूरा नाम लिखें',
                        controller: _nameController,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'कृपया अपना नाम दर्ज करें';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFormInput(
                        label: 'जिला (District) *',
                        hint: 'जिले का नाम',
                        controller: _districtController,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'कृपया जिला दर्ज करें';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFormInput(
                        label: 'गाँव (Village)',
                        hint: 'गाँव का नाम',
                        controller: _villageController,
                      ),
                      const SizedBox(height: 16),
                      _buildFormInput(
                        label: 'मोबाइल नंबर (Mobile Number) *',
                        hint: '+91 XXXXX XXXXX',
                        keyboardType: TextInputType.phone,
                        controller: _phoneController,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'कृपया मोबाइल नंबर दर्ज करें';
                          }
                          final regExp = RegExp(r'^[0-9]{10}$');
                          if (!regExp.hasMatch(val.trim())) {
                            return 'कृपया सही 10-अंकीय मोबाइल नंबर दर्ज करें';
                          }
                          return null;
                        },
                      ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                            ),
                          ),
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
                              activeThumbColor: const Color(0xFF10B981),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _showSubmitConfirmationDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _isAlreadyRegistered
                            ? 'विवरण अपडेट करें (Update Details)'
                            : 'पंजीकरण करें (Register)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildFormInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
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
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
