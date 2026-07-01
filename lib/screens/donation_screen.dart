import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/banner_ad_widget.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  final String _upiId = '7518338831@okbizaxis';
  final String _razorpayUrl = 'https://razorpay.me/@sinuxindiafoundationhelp';
  final String _youtubeUrl = 'https://rb.gy/9r5kq4';
  final String _instagramUrl = 'https://rebrand.ly/sinuxindia';
  final String _facebookUrl = 'https://tinyurl.com/k4zux62b';
  
  final String _bankDetails = 'Organization Name: Sinux India Foundation\nAccount Number: 44220468629\nIFSC Code: SBIN0012828\nBank Name: State Bank of India (SBI)';

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    String formattedUrl = urlString;
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      formattedUrl = 'https://$urlString';
    }
    final Uri url = Uri.parse(formattedUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('लिंक खोलने में असमर्थ: $formattedUrl'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _launchUPI(BuildContext context) async {
    final String upiUrl = 'upi://pay?pa=$_upiId&pn=Sinux%20India%20Foundation&cu=INR';
    final Uri url = Uri.parse(upiUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Copy UPI ID and tell the user
        if (context.mounted) {
          Clipboard.setData(ClipboardData(text: _upiId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('UPI ऐप्स नहीं मिले। UPI ID कॉपी कर ली गई है!'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: _upiId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI ID कॉपी कर ली गई है! इसे अपने UPI ऐप में पेस्ट करें।'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate UPI QR Code URL
    final String qrCodeUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=upi%3A%2F%2Fpay%3Fpa%3D7518338831%40okbizaxis%26pn%3DSinux%2520India%2520Foundation%26cu%3DINR';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        title: const Text(
          'दान एवं सहयोग (Donate)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF334155), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Emotional appeal Hero Banner
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE11D48), Color(0xFFBE123C)], // Rose 600 to Rose 700
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          '⚠️ कब तक चुप रहेंगे?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'सड़क पर तड़पती गौ माता… और हम सिर्फ देखते रहें? 💔',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.double_arrow_rounded, color: Colors.amberAccent, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'अगर आज नहीं जागे, तो कब जागेंगे?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFDE047), // Amber 300
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Foundation & Campaign Details Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: const Color(0xFFFFFBEB), // Amber 50
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🐄', style: TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '(गौ जीवन आश्रय) गौशाला संचालन',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'गौशालाओं के सुचारू संचालन हेतु',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFFEF3C7)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🏢', style: TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sinux India Foundation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Registered Foundation / संस्था',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section Title
              const Row(
                children: [
                  Icon(Icons.payment_rounded, color: Color(0xFF0F172A), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'सहयोग राशि भेजें (Donate Now)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // UPI ID & QR Card
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFF1F5F9)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 6),
                          Text(
                            'UPI QR कोड स्कैन करें',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Google Pay, PhonePe, Paytm, या किसी भी UPI ऐप से स्कैन करें',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Network QR Code Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            qrCodeUrl,
                            height: 200,
                            width: 200,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                width: 200,
                                color: const Color(0xFFF8FAFC),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 200,
                              width: 200,
                              color: const Color(0xFFF1F5F9),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFF94A3B8)),
                                  SizedBox(height: 8),
                                  Text(
                                    'QR लोड नहीं हो सका\nUPI ID का उपयोग करें',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Pay via UPI App button
                      ElevatedButton.icon(
                        onPressed: () => _launchUPI(context),
                        icon: const Icon(Icons.flash_on_rounded, size: 18),
                        label: const Text('UPI ऐप से सीधे भुगतान करें'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Copy UPI ID Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'UPI ID',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(
                                    _upiId,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: Color(0xFF0284C7), size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _upiId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('UPI ID कॉपी हो गई है!'),
                                    backgroundColor: Color(0xFF0284C7),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              tooltip: 'Copy UPI ID',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Razorpay Link Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.link_rounded, color: Color(0xFF2563EB), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Donate Link (Razorpay)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _razorpayUrl.replaceFirst('https://', ''),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _launchUrl(context, _razorpayUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Text('Donate Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bank Transfer Details Card
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: Color(0xFF16A34A), size: 20),
                    ),
                    title: const Text(
                      'बैंक खाते में ट्रांसफर करें (Bank Details)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBankDetailRow('Organization', 'Sinux India Foundation'),
                              const Divider(height: 16),
                              _buildBankDetailRow('Account No.', '44220468629'),
                              const Divider(height: 16),
                              _buildBankDetailRow('IFSC Code', 'SBIN0012828'),
                              const Divider(height: 16),
                              _buildBankDetailRow('Bank Name', 'State Bank of India (SBI)'),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _bankDetails));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('बैंक विवरण कॉपी हो गया है!'),
                                      backgroundColor: Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text('सभी विवरण कॉपी करें'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF16A34A),
                                  side: const BorderSide(color: Color(0xFF16A34A)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Connect With Us Section
              const Row(
                children: [
                  Icon(Icons.share_rounded, color: Color(0xFF0F172A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'हमसे जुड़ें (Connect With Us)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialButton(
                    context: context,
                    icon: Icons.play_circle_fill_rounded,
                    label: 'YouTube',
                    color: const Color(0xFFFF0000),
                    url: _youtubeUrl,
                  ),
                  _buildSocialButton(
                    context: context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Instagram',
                    color: const Color(0xFFE1306C),
                    url: _instagramUrl,
                  ),
                  _buildSocialButton(
                    context: context,
                    icon: Icons.facebook_rounded,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    url: _facebookUrl,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Footer Cards/Info
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFFFEF2F2), // Red 50
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '🔥 छोटा सा सहयोग = एक जीवन बच सकता है',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'चुप मत रहो… मदद करो',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchUrl(context, url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
