import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: const Color(0xFF0D1B4A),
        foregroundColor: Colors.white,
      ),
      body: const AboutUsContent(),
    );
  }
}

class AboutUsContent extends StatelessWidget {
  const AboutUsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                Scaffold.of(context).appBarMaxHeight!,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                icon: Icons.info_outline,
                title: "About Us",
                content:
                    "Buddu CBS PEWOSA SACCO is a community-focused financial institution dedicated to delivering innovative financial solutions. We empower individuals and businesses in the Greater Masaka region through accessible financial services, driving economic growth and improving livelihoods.",
              ),
              const SizedBox(height: 30),
              _buildSection(
                icon: Icons.visibility,
                title: "Our Vision",
                content:
                    "To be a leading provider of sustainable financial services that lead to a dignified life in Uganda.",
              ),
              const SizedBox(height: 30),
              _buildSection(
                icon: Icons.flag,
                title: "Our Mission",
                content:
                    "To provide appropriate access to financial and non-financial services to reduce vulnerability and enhance socioeconomic status on a sustainable basis.",
              ),
              const SizedBox(height: 30),
              _buildSection(
                icon: Icons.history,
                title: "Corporate Background",
                content:
                    "Established in 2019, we're a licensed SACCO under the Cooperative Societies Act. With our headquarters in Masaka City, we've become a trusted financial partner through transparency, innovation, and cultural alignment.",
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
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
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}