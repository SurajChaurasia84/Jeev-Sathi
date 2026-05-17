import 'package:flutter/material.dart';

class GauSevakRegistrationScreen extends StatefulWidget {
  const GauSevakRegistrationScreen({super.key});

  @override
  State<GauSevakRegistrationScreen> createState() => _GauSevakRegistrationScreenState();
}

class _GauSevakRegistrationScreenState extends State<GauSevakRegistrationScreen> {
  final List<String> _skillsList = ['First Aid', 'Transport', 'Cow Care', 'Rescue', 'Nursing', 'Awareness', 'Fundraising'];
  final List<String> _selectedSkills = ['Cow Care', 'Rescue'];
  bool _isEmergencyAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('🤝 Gau Sevak Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormInput(label: 'नाम (Name) *', hint: 'अपना पूरा नाम लिखें'),
              const SizedBox(height: 16),
              _buildFormInput(label: 'जिला (District) *', hint: 'जिले का नाम'),
              const SizedBox(height: 16),
              _buildFormInput(label: 'गाँव (Village)', hint: 'गाँव का नाम'),
              const SizedBox(height: 16),
              _buildFormInput(label: 'मोबाइल नंबर (Mobile Number) *', hint: '+91 XXXXX XXXXX', keyboardType: TextInputType.phone),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: const Color(0xFFE2E8F0))),
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
                        activeColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ID Proof Upload Card
              const Text(
                'Upload ID Proof',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.file_upload, color: Color(0xFF10B981)),
                  title: const Text('Aadhaar / Voter ID / Driving License', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('फ़ाइल अपलोड करें', style: TextStyle(fontSize: 10)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 32),

              // Register Button
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 रजिस्ट्रेशन सफल! आपका आवेदन रिव्यु में है।')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('पंजीकरण करें (Register)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
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
