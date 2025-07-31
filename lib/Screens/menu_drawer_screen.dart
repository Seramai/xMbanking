import 'package:flutter/material.dart';
import 'package:mobile_system/Screens/contact_us_screen.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';
import 'security_tips_screen.dart';

class MenuDrawerScreen extends StatelessWidget {
  const MenuDrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
               Color(0xFF0D1B4A),  
               Color(0xFF1A237E),
               Color(0xFF303F9F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              
              const SizedBox(height: 20),
              // Menu items list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildMenuItem(
                      icon: Icons.info,
                      title: 'About us',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context)=> const AboutUsScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.shield, 
                      title: 'Security tips',
                      onTap: () {
                        Navigator.push(
                          context,
                        MaterialPageRoute(builder: (context)=> const SecurityTipsScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.contact_support,
                      title: 'Contact us',
                      onTap: () {
                        Navigator.push(
                          context,
                        MaterialPageRoute(builder: (context)=> const ContactUsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.3),
                      margin: const EdgeInsets.only(bottom: 16),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'App ID: ONLINE BANK-2025',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}