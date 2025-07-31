import 'package:flutter/material.dart';

class SecurityTipsScreen extends StatelessWidget {
  const SecurityTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Tips'),
        backgroundColor: const Color(0xFF0D1B4A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B4A),
              Color(0xFF1A237E),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSecurityTipCard(
                icon: Icons.lock,
                title: "Password Protection",
                tips: [
                  "Use strong, unique passwords for your account",
                  "Never share your PIN or passwords with anyone",
                  "Change passwords every 3 months",
                  "Avoid using personal information in passwords"
                ],
              ),
              const SizedBox(height: 20),
              _buildSecurityTipCard(
                icon: Icons.phone_android,
                title: "Mobile Security",
                tips: [
                  "Always lock your mobile device",
                  "Install apps only from official stores",
                  "Keep your operating system updated",
                  "Enable remote wipe feature"
                ],
              ),
              const SizedBox(height: 20),
              _buildSecurityTipCard(
                icon: Icons.wifi,
                title: "Online Safety",
                tips: [
                  "Avoid using public WiFi for transactions",
                  "Look for 'https://' in website URLs",
                  "Log out after online banking sessions",
                  "Beware of phishing emails pretending to be from SACCO"
                ],
              ),
              const SizedBox(height: 20),
              _buildSecurityTipCard(
                icon: Icons.credit_card,
                title: "Transaction Safety",
                tips: [
                  "Verify all transaction details before confirming",
                  "Regularly check your account statements",
                  "Report lost cards immediately",
                  "Set up transaction alerts"
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityTipCard({
    required IconData icon,
    required String title,
    required List<String> tips,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B4A).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF0D1B4A)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B4A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tips.map((tip) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
}