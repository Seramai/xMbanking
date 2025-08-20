import 'package:flutter/material.dart';
import 'dart:io'; 
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../Utils/phone_utils.dart';
import '../Utils/status_messages.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final String email;
  // Image data properties for profile picture
  final File? profileImageFile;
  final Uint8List? profileImageBytes;
  final String? authToken; 
  final Map<String, dynamic>? loginData;
  final String? mobileNumber; 
  
  const UserProfileScreen({
    super.key,
    required this.username,
    required this.email,
    this.profileImageFile,  
    this.profileImageBytes,
    this.authToken, 
    this.loginData,
    this.mobileNumber, 
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Uint8List? _cachedImageBytes;
  File? _cachedImageFile;
  String? _cachedEmail;
  String? _cachedUsername;

  @override
  void initState() {
    super.initState();
    _loadRegistrationDataFromCache();
  }

  Future<void> _loadRegistrationDataFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedEmail;
      String? cachedUsername;
      String? cachedImageBytes;
      String? cachedImagePath;
      if (widget.mobileNumber != null) {
        final key = PhoneUtils.canonicalPhoneKey(widget.mobileNumber!);
        cachedEmail = prefs.getString('user_${key}_email');
        cachedUsername = prefs.getString('user_${key}_fullName');
        cachedImageBytes = prefs.getString('user_${key}_profileImage_bytes');
        cachedImagePath = prefs.getString('user_${key}_profileImage_path');
        
      }
      if (cachedEmail == null) {
        cachedEmail = prefs.getString('registration_email');
        cachedUsername = prefs.getString('registration_fullName');
        cachedImageBytes = prefs.getString('registration_profileImage_bytes');
        cachedImagePath = prefs.getString('registration_profileImage_path');
        
      }
      
      setState(() {
        _cachedEmail = cachedEmail;
        _cachedUsername = cachedUsername;
        
        if (cachedImageBytes != null) {
          try {
            _cachedImageBytes = base64Decode(cachedImageBytes);
          } catch (e) {}
        }
        
        if (cachedImagePath != null && !kIsWeb) {
          _cachedImageFile = File(cachedImagePath);
        }
      });
      
      
    } catch (e) {
      
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Color.fromARGB(255, 25, 35, 126)),
              Text('Logout Confirmation'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: const Color.fromARGB(255, 255, 255, 255),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build profile image 
  Widget _buildProfileImage(BuildContext context) {
    if (widget.profileImageBytes != null) {
      return Image.memory(
        widget.profileImageBytes!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (widget.profileImageFile != null && !kIsWeb) {
      return Image.file(
        widget.profileImageFile!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (_cachedImageBytes != null) {
      return Image.memory(
        _cachedImageBytes!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (_cachedImageFile != null && !kIsWeb) {
      return Image.file(
        _cachedImageFile!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    } else {
      return Icon(
        Icons.person,
        size: 60,
        color: Theme.of(context).primaryColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView( 
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Color(0xFF1A237E).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _buildProfileImage(context),
                  ),
                ),
                
                const SizedBox(height: 24),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Username',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _cachedUsername ?? widget.username, 
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _cachedEmail ?? widget.email, 
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/edit-profile',
                                    arguments: {
                                      'username': _cachedUsername ?? widget.username,
                                      'email': _cachedEmail ?? widget.email,
                                      'mobileNumber': widget.mobileNumber,
                                    },
                                  );
                                  if (result is Map<String, dynamic>) {
                                    setState(() {
                                      _cachedUsername = result['username'] ?? _cachedUsername;
                                      _cachedEmail = result['email'] ?? _cachedEmail;
                                      if (result['imageBytes'] != null) {
                                        _cachedImageBytes = result['imageBytes'];
                                        _cachedImageFile = null;
                                      }
                                    });
                                  }
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Profile'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                            onPressed: () async {
                              String tokenToUse = widget.authToken ?? '';
                              if (tokenToUse.isEmpty) {
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  tokenToUse = prefs.getString('authToken') ?? '';
                                } catch (_) {}
                              }
                              if (tokenToUse.isEmpty) {
                                StatusMessages.error(context, message: 'Authentication error. Please login again to change PIN.');
                                return;
                              }
                              Navigator.pushNamed(
                                context,
                                '/change-pin',
                                arguments: {
                                  'authToken': tokenToUse,
                                  'isFirstTime': false,
                                  'username': _cachedUsername ?? widget.username,
                                  'email': _cachedEmail ?? widget.email,
                                  'loginData': widget.loginData,
                                },
                              );
                            },
                                icon: const Icon(Icons.lock),
                                label: const Text('Change PIN'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}