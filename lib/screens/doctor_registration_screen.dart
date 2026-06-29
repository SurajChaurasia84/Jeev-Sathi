import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() => _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _emergencySupportAvailable = true;
  bool _isLoading = false;
  bool _isAlreadyRegistered = false;
  bool _isFetchingLocation = false;
  double? _latitude;
  double? _longitude;

  Future<void> _fetchLocationInWords() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('कृपया डिवाइस की लोकेशन सर्विस चालू करें।')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('लोकेशन अनुमति अस्वीकार कर दी गई।')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('लोकेशन अनुमति स्थायी रूप से अस्वीकार है, कृपया सेटिंग्स से अनुमति दें।')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10), onTimeout: () async {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) return lastPos;
        throw Exception('लोकेशन प्राप्त करने में समय समाप्त हो गया।');
      });

      _latitude = position.latitude;
      _longitude = position.longitude;

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=16&addressdetails=1&accept-language=hi,en',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'JeevSathiApp/1.0',
      }).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(res.body);
        final address = json['address'] as Map<String, dynamic>?;

        if (address != null) {
          final String? suburb = address['suburb'] ?? address['neighbourhood'] ?? address['residential'];
          final String? road = address['road'] ?? address['amenity'] ?? address['building'];
          final String? villageOrTown = address['village'] ?? address['town'];

          final List<String> areaParts = [];
          if (road != null && road.isNotEmpty) areaParts.add(road);
          if (suburb != null && suburb.isNotEmpty && !areaParts.contains(suburb)) areaParts.add(suburb);
          if (villageOrTown != null && villageOrTown.isNotEmpty && !areaParts.contains(villageOrTown)) areaParts.add(villageOrTown);

          if (areaParts.isNotEmpty) {
            _addressController.text = areaParts.join(', ');
          } else if (json['display_name'] != null) {
            final parts = (json['display_name'] as String).split(',');
            _addressController.text = parts.take(2).join(',').trim();
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📍 सटीक लोकल एरिया लोकेशन प्राप्त हो गई!'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('लोकेशन प्राप्त करने में त्रुटि: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRegistrationDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
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
            .collection('doctors')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _nameController.text = data['name'] ?? '';
          _addressController.text = data['clinicAddress'] ?? '';
          _specializationController.text = data['specialization'] ?? '';
          _experienceController.text = (data['experience'] ?? 0).toString();
          _phoneController.text = data['phone'] ?? '';
          _latitude = (data['latitude'] is num) ? (data['latitude'] as num).toDouble() : null;
          _longitude = (data['longitude'] is num) ? (data['longitude'] as num).toDouble() : null;

          _emergencySupportAvailable = data['emergencySupport'] ?? true;
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

  Future<void> _registerDoctor() async {
    if (_formKey.currentState!.validate() == false) {
      return;
    }

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final specialization = _specializationController.text.trim();
    final experienceStr = _experienceController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final experience = int.tryParse(experienceStr) ?? 0;

        final doctorData = <String, dynamic>{
          'uid': user.uid,
          'name': name,
          'clinicAddress': address,
          'specialization': specialization,
          'experience': experience,
          'phone': phone,
          'emergencySupport': _emergencySupportAvailable,
          'registeredAt': FieldValue.serverTimestamp(),
        };

        if (_latitude != null && _longitude != null) {
          doctorData['latitude'] = _latitude;
          doctorData['longitude'] = _longitude;
        }

        // 1. Save Doctor record in Firestore 'doctors' collection
        await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set(doctorData);

        // 2. Flag the user profile with isDoctor true
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isDoctor': true,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isAlreadyRegistered
                  ? '🎉 पशु चिकित्सक का विवरण सफलतापूर्वक अपडेट किया गया!'
                  : '🎉 पशु चिकित्सक पंजीकरण सफलतापूर्वक संपन्न हुआ!'),
              backgroundColor: const Color(0xFFEC4899),
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
                      ? 'क्या आप अपना Doctor विवरण अपडेट करना चाहते हैं?'
                      : 'क्या आप पशु चिकित्सक के रूप में पंजीकरण सबमिट करना चाहते हैं?',
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
                foregroundColor: const Color(0xFFEC4899),
              ),
              child: const Text('हाँ, सबमिट करें (Yes, Submit)', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _registerDoctor(); // Actually perform save
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
                Text('क्या आप वाकई अपना Doctor पंजीकरण रद्द करना चाहते हैं?'),
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
                _deleteDoctorRegistration();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDoctorRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Delete doctor details from Firestore
        await FirebaseFirestore.instance.collection('doctors').doc(user.uid).delete();

        // 2. Set isDoctor flag to false in users collection
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isDoctor': false,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 आपका डॉक्टर पंजीकरण सफलतापूर्वक रद्द कर दिया गया है।'),
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'कृपया डॉक्टर का नाम दर्ज करें';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFormInput(
                        label: 'विशेषज्ञता / योग्यता (Specialization / Degree) *',
                        hint: 'जैसे: B.V.Sc & A.H, M.V.Sc...',
                        controller: _specializationController,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'कृपया विशेषज्ञता / योग्यता दर्ज करें';
                          }
                          return null;
                        },
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'कृपया संपर्क नंबर दर्ज करें';
                          }
                          final regExp = RegExp(r'^[0-9]{10}$');
                          if (!regExp.hasMatch(val.trim())) {
                            return 'कृपया सही 10-अंकीय मोबाइल नंबर दर्ज करें';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFormInput(
                        label: 'क्लिनिक का पता (Clinic Address) *',
                        hint: 'लोकेशन फ़ैच करें बटन पर टैप करें...',
                        maxLines: 1,
                        readOnly: true,
                        onTap: _isFetchingLocation ? null : _fetchLocationInWords,
                        controller: _addressController,
                        actionWidget: InkWell(
                          onTap: _isFetchingLocation ? null : _fetchLocationInWords,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isFetchingLocation
                                    ? const SizedBox(
                                        height: 12,
                                        width: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
                                        ),
                                      )
                                    : const Icon(Icons.my_location, size: 14, color: Color(0xFFEC4899)),
                                const SizedBox(width: 4),
                                Text(
                                  _isFetchingLocation ? 'फ़ैच हो रहा है...' : 'लोकेशन फ़ैच करें',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEC4899),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'कृपया लोकेशन फ़ैच करें बटन पर क्लिक करके पता प्राप्त करें';
                          }
                          return null;
                        },
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _showSubmitConfirmationDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isAlreadyRegistered
                            ? 'विवरण अपडेट करें (Update Details)'
                            : 'डॉक्टर पंजीकृत करें (Register Doctor)',
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
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    Widget? actionWidget,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
            ?actionWidget,
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
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
              borderSide: const BorderSide(color: Color(0xFFEC4899), width: 1.5),
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
