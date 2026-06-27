import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../services/cloudinary_service.dart';
import '../widgets/safe_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  User? _currentUser;

  File? _localProfileImage;
  String? _firestorePhotoUrl;
  bool _isLocalImageUpdated = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Load local profile image path from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final localPath = prefs.getString('profile_image_path_${_currentUser!.uid}');
      if (localPath != null && localPath.isNotEmpty) {
        final file = File(localPath);
        if (await file.exists()) {
          setState(() {
            _localProfileImage = file;
          });
        }
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _firestorePhotoUrl = data['photoUrl'] as String?;
          });
          _nameController.text = data['displayName'] ?? data['name'] ?? _currentUser!.displayName ?? '';
          _phoneController.text = data['phoneNumber'] ?? data['phone'] ?? _currentUser!.phoneNumber ?? '';
          _districtController.text = data['district'] ?? '';
          _villageController.text = data['village'] ?? data['address'] ?? '';
          _bioController.text = data['bio'] ?? '';
        }
      } else {
        // Fallback to Auth values if Firestore document doesn't exist
        _nameController.text = _currentUser!.displayName ?? '';
        _phoneController.text = _currentUser!.phoneNumber ?? '';
      }
    } catch (e) {
      _showSnackBar('त्रुटि: प्रोफाइल विवरण लोड नहीं किया जा सका। (${e.toString()})', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserProfile() async {
    if (_formKey.currentState!.validate() == false) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final district = _districtController.text.trim();
      final village = _villageController.text.trim();
      final bio = _bioController.text.trim();

      if (_currentUser != null) {
        // 1. Update Firebase Auth display name
        await _currentUser!.updateDisplayName(name);

        // 1.5 Handle local profile image saving/removal
        if (_isLocalImageUpdated) {
          final prefs = await SharedPreferences.getInstance();
          final appDocDir = await getApplicationDocumentsDirectory();
          final destinationFile = File('${appDocDir.path}/profile_${_currentUser!.uid}.png');

          if (_localProfileImage == null) {
            // Remove local copy
            if (await destinationFile.exists()) {
              await destinationFile.delete();
            }
            await prefs.remove('profile_image_path_${_currentUser!.uid}');
            await _currentUser!.updatePhotoURL(null);
            // Clear photoUrl in Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUser!.uid)
                .set({'photoUrl': ''}, SetOptions(merge: true));
          } else {
            // Save local copy
            if (_localProfileImage!.path != destinationFile.path) {
              await _localProfileImage!.copy(destinationFile.path);
            }
            await prefs.setString('profile_image_path_${_currentUser!.uid}', destinationFile.path);

            // Upload to Cloudinary and save URL in Firestore
            try {
              final uploadedUrl = await CloudinaryService.uploadImage(_localProfileImage!);
              if (uploadedUrl.isNotEmpty) {
                await _currentUser!.updatePhotoURL(uploadedUrl);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .set({'photoUrl': uploadedUrl}, SetOptions(merge: true));
              }
            } catch (uploadError) {
              // Cloudinary upload failed — show error to user
              if (mounted) {
                _showSnackBar(
                  '⚠️ फोटो अपलोड विफल: ${uploadError.toString().replaceFirst("Exception: ", "")}',
                  isError: true,
                );
              }
              // Still save local path as fallback in Auth
              await _currentUser!.updatePhotoURL(destinationFile.path);
            }
          }
        }

        // 2. Update details in Firestore users collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .set({
          'displayName': name,
          'name': name,
          'phoneNumber': phone,
          'district': district,
          'village': village,
          'bio': bio,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 3. Update volunteer details in gau_sevaks collection if exists
        final volunteerRef = FirebaseFirestore.instance
            .collection('gau_sevaks')
            .doc(_currentUser!.uid);
        final volunteerDoc = await volunteerRef.get();
        if (volunteerDoc.exists) {
          await volunteerRef.update({
            'name': name,
            'phone': phone,
            'district': district,
            'village': village,
          });
        }

        if (mounted) {
          _showSnackBar('🎉 प्रोफाइल सफलतापूर्वक अपडेट कर दी गई है!');
          Navigator.pop(context); // Go back to settings screen
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('त्रुटि: प्रोफाइल सेव करने में समस्या आई। (${e.toString()})', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
                    children: [
                      // Avatar Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                          child: Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _showImagePickerOptions,
                                  child: Stack(
                                    children: [
                                       SafeNetworkAvatar(
                                        radius: 46,
                                        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                                        localFile: _localProfileImage,
                                        photoUrl: (_localProfileImage == null)
                                            ? ((_firestorePhotoUrl != null &&
                                                _firestorePhotoUrl!.isNotEmpty &&
                                                _firestorePhotoUrl!.startsWith('http'))
                                                ? _firestorePhotoUrl
                                                : (_currentUser != null
                                                    ? _getNetworkProfileUrl(_currentUser!)
                                                    : null))
                                            : null,
                                        fallbackChild: const Icon(Icons.person, size: 46, color: Color(0xFF10B981)),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _currentUser?.email ?? 'ईमेल उपलब्ध नहीं है',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'ईमेल बदला नहीं जा सकता है',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input Fields Card
                      Card(
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
                              _buildFormInput(
                                label: 'नाम (Full Name) *',
                                hint: 'अपना नाम दर्ज करें',
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
                                label: 'मोबाइल नंबर (Mobile Number)',
                                hint: '+91 XXXXX XXXXX',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _buildFormInput(
                                label: 'जिला (District)',
                                hint: 'अपने जिले का नाम दर्ज करें',
                                controller: _districtController,
                              ),
                              const SizedBox(height: 16),
                              _buildFormInput(
                                label: 'गाँव / पता (Village / Address)',
                                hint: 'अपने गाँव या पते की जानकारी लिखें',
                                controller: _villageController,
                              ),
                              const SizedBox(height: 16),
                              _buildFormInput(
                                label: 'मेरे बारे में (Bio)',
                                hint: 'अपने बारे में कुछ वाक्य लिखें (वैकल्पिक)',
                                controller: _bioController,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      _isSaving
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _saveUserProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'प्रोफ़ाइल सहेजें (Save Profile)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                      const SizedBox(height: 20),
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
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

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _localProfileImage = File(pickedFile.path);
        _isLocalImageUpdated = true;
      });
    } catch (e) {
      _showSnackBar('फ़ोटो चुनने में त्रुटि: ${e.toString()}', isError: true);
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() {
      _localProfileImage = null;
      _isLocalImageUpdated = true;
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'प्रोफ़ाइल फ़ोटो बदलें (Change Profile Photo)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
              title: const Text('कैमरा (Camera)'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('गैलरी (Gallery)'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            if (_localProfileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('फ़ोटो हटाएं (Remove Photo)'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String? _getNetworkProfileUrl(User user) {
    if (user.photoURL != null && user.photoURL!.startsWith('http')) {
      return user.photoURL;
    }
    for (final profile in user.providerData) {
      if (profile.photoURL != null && profile.photoURL!.startsWith('http')) {
        return profile.photoURL;
      }
    }
    return null;
  }
}
