import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                icon: Icons.location_on,
                title: "Our Branch Network",
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactItem(Icons.home_work, "Head Office"),
                    _buildContactDetail("Plot 11c, Birch Avenue, Masaka City"),
                    _buildContactDetail("P.O.Box 300 Masaka Uganda"),
                    const SizedBox(height: 10),
                    _buildContactItem(Icons.email, "Email:"),
                    _buildContactDetail("info@buddupewosacco.com"),
                    const SizedBox(height: 10),
                    _buildContactItem(Icons.phone, "Tel:"),
                    _buildContactDetail("+256 708 882 921"),
                    const SizedBox(height: 10),
                    _buildContactItem(Icons.public, "Website:"),
                    _buildContactDetail("www.buddupewosacco.com"),
                    const SizedBox(height: 10),
                    _buildContactItem(Icons.share, "Social Media:"),
                    _buildContactDetail("@bupesaco (Facebook, Instagram, Twitter, LinkedIn, TikTok)"),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildSection(
                icon: Icons.access_time,
                title: "Business Hours",
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactDetail("Monday - Friday: 9:00 AM - 5:00 PM"),
                    _buildContactDetail("Saturday: 8:00 AM - 1:00 PM"),
                    _buildContactDetail("Sunday: Closed"),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildSection(
                icon: Icons.map,
                title: "Our Location",
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactItem(Icons.location_pin, "Address:"),
                    _buildContactDetail("Plot 11c Birch Avenue, Masaka City"),
                    _buildContactDetail("P.O.Box Masaka Uganda"),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget content,
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
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0D1B4A)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B4A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetail(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}