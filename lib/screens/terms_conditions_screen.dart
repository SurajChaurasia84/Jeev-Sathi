import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatefulWidget {
  final bool initialAccepted;

  const TermsConditionsScreen({
    super.key,
    this.initialAccepted = false,
  });

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final List<bool> _sectionAgreed = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    if (widget.initialAccepted) {
      _sectionAgreed[0] = true;
      _sectionAgreed[1] = true;
      _sectionAgreed[2] = true;
      _sectionAgreed[3] = true;
    }
  }

  bool get _allAgreed => _sectionAgreed.every((agreed) => agreed);

  void _toggleAll(bool? value) {
    setState(() {
      final newValue = value ?? false;
      for (int i = 0; i < _sectionAgreed.length; i++) {
        _sectionAgreed[i] = newValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'नियम और शर्तें (T&C)',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Column(
        children: [
          // Select All Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            child: Row(
              children: [
                Checkbox(
                  value: _allAgreed,
                  activeColor: const Color(0xFF10B981),
                  onChanged: _toggleAll,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'सभी नियमों और शर्तों को एक साथ स्वीकार करें',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionCard(
                  index: 0,
                  title: 'JeevSathi – Gau Sevak Registration Terms & Conditions',
                  icon: Icons.volunteer_activism,
                  points: const [
                    'I confirm that all the information provided by me is true and accurate.',
                    'I will treat all animals with care, compassion, and respect and will not engage in any form of animal cruelty.',
                    'I will submit only genuine and verified rescue reports through the JeevSathi App.',
                    'Any fake report, false information, misuse of the platform, or misleading activity may result in suspension or permanent termination of my account.',
                    'I understand that my safety is my own responsibility while participating in any rescue or volunteer activity.',
                    'Reward Points, Badges, Certificates, ID Cards, and other benefits are subject to verification and may be modified or withdrawn by JeevSathi at any time.',
                    'My registration will become active only after approval by the JeevSathi Administration.',
                    'JeevSathi reserves the right to reject, suspend, or terminate my registration without prior notice if I violate any rules or policies.',
                    'I understand that I must verify the SOS request before taking any action. Any rescue or volunteer activity is performed entirely at my own risk. JeevSathi and Sinux India Foundation shall not be responsible for any accident, injury, death, loss, damage, legal dispute, or any other unforeseen incident that may occur during or after responding to an SOS or participating in any activity through the App.',
                    'I agree to follow all Terms & Conditions and the Privacy Policy of the JeevSathi App.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  index: 1,
                  title: 'JeevSathi – User (SOS Reporter) Terms & Conditions',
                  icon: Icons.emergency,
                  points: const [
                    'I confirm that all information provided by me is true and accurate.',
                    'I will use the SOS feature only for genuine emergencies involving injured, sick, abandoned, or distressed animals.',
                    'I will not submit fake, misleading, duplicate, or false SOS reports.',
                    'Repeated false reports may result in suspension or permanent termination of my account.',
                    'I agree to upload clear photos, videos, and the correct location whenever possible.',
                    'I understand that submitting an SOS request does not guarantee immediate rescue, as response time depends on volunteer and resource availability.',
                    'I will not misuse the platform for harassment, spam, illegal activities, or personal disputes.',
                    'JeevSathi reserves the right to review, reject, suspend, or remove any SOS request or user account that violates these Terms & Conditions.',
                    'I understand that I should provide accurate information and that volunteers or doctors will verify the SOS before taking action. JeevSathi and Sinux India Foundation are not responsible for any delay, accident, injury, death, loss, damage, legal dispute, or any unforeseen incident that may occur during or after any rescue or emergency response.',
                    'I agree to comply with the JeevSathi Privacy Policy and all applicable laws.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  index: 2,
                  title: 'JeevSathi – Doctor Registration Terms & Conditions',
                  icon: Icons.medical_services,
                  points: const [
                    'I confirm that I am a qualified Veterinary Doctor/Animal Health Professional and all information provided by me is true.',
                    'I agree to upload valid professional documents for verification.',
                    'My profile will be activated only after successful verification by the JeevSathi Administration.',
                    'I will provide professional advice only within my area of expertise.',
                    'Online advice provided through the app should not be considered a substitute for a physical examination or emergency veterinary treatment.',
                    'I will maintain the privacy and confidentiality of all user and patient information.',
                    'Any false information, fake documents, or unethical conduct may lead to immediate suspension or permanent removal of my account.',
                    'JeevSathi reserves the right to review, suspend, or terminate my account at any time if any policy is violated.',
                    'I understand that I must verify the SOS request before taking any action. Any medical advice, rescue participation, or emergency response is provided at my own professional judgment and risk. JeevSathi and Sinux India Foundation shall not be responsible for any accident, injury, death, loss, damage, legal dispute, or any unforeseen incident arising during or after such activities.',
                    'I agree to comply with all JeevSathi Terms & Conditions and Privacy Policy.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  index: 3,
                  title: 'JEEVSATHI – WOMEN SAFETY TERMS & CONDITIONS',
                  icon: Icons.security,
                  points: const [
                    'I confirm that all the information provided by me is true and accurate.',
                    'I will use the Women Safety SOS feature only in genuine emergency situations.',
                    'I will not misuse the SOS button by sending false, fake, or misleading emergency alerts.',
                    'I understand that repeated misuse of the SOS feature may result in suspension or permanent termination of my account.',
                    'I agree to keep my emergency contact details updated and accurate.',
                    'I understand that the SOS feature shares my live location and emergency details with my selected emergency contacts and, where applicable, authorized JeevSathi volunteers for safety purposes.',
                    'I understand that JeevSathi is a technology platform and does not guarantee immediate assistance, police response, medical support, or rescue services.',
                    'I understand that any emergency response depends on the availability of volunteers, emergency contacts, and local authorities.',
                    'JeevSathi and Sinux India Foundation shall not be responsible for any delay, accident, injury, death, loss, damage, legal dispute, or any unforeseen incident that may occur during or after the use of the Women Safety feature.',
                    'I agree to comply with all JeevSathi Terms & Conditions, Privacy Policy, and applicable laws.',
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Submit Area
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _allAgreed
                    ? () {
                        Navigator.pop(context, true);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: _allAgreed ? 2 : 0,
                ),
                child: Text(
                  _allAgreed
                      ? 'Accept & Continue'
                      : '(${_sectionAgreed.where((e) => e).length}/4) Accepted',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required int index,
    required String title,
    required IconData icon,
    required List<String> points,
  }) {
    final isChecked = _sectionAgreed[index];

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isChecked ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: isChecked ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF10B981), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...points.map(
              (pt) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    Expanded(
                      child: Text(
                        pt,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                setState(() {
                  _sectionAgreed[index] = !_sectionAgreed[index];
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isChecked
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isChecked,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) {
                        setState(() {
                          _sectionAgreed[index] = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'I Agree to the Terms & Conditions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
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
