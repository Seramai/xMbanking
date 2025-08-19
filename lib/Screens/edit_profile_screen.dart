import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final String initialUsername;
  final String initialEmail;
  final String? mobileNumber;

  const EditProfileScreen({
    super.key,
    required this.initialUsername,
    required this.initialEmail,
    this.mobileNumber,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSaving = false;
  Uint8List? _imageBytes;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialUsername;
    _emailController.text = widget.initialEmail;
    _loadExistingImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Please enter a valid name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _loadExistingImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? bytesB64;
      String? imagePath;
      if (widget.mobileNumber != null && widget.mobileNumber!.isNotEmpty) {
        bytesB64 = prefs.getString('user_${widget.mobileNumber}_profileImage_bytes');
        imagePath = prefs.getString('user_${widget.mobileNumber}_profileImage_path');
      } else {
        bytesB64 = prefs.getString('registration_profileImage_bytes');
        imagePath = prefs.getString('registration_profileImage_path');
      }
      if (bytesB64 != null && bytesB64.isNotEmpty) {
        setState(() {
          _imageBytes = base64Decode(bytesB64!);
          _imageFile = null;
        });
      } else if (imagePath != null && imagePath.isNotEmpty && !kIsWeb) {
        final file = File(imagePath);
        if (await file.exists()) {
          setState(() {
            _imageFile = file;
          });
        }
      }
    } catch (_) {}
  }

  Future<bool> _ensureCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> _captureSelfie() async {
    final granted = await _ensureCameraPermission();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to take a selfie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageFile = !kIsWeb ? File(picked.path) : null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to capture image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String fullName = _nameController.text.trim();
      final String email = _emailController.text.trim();

      if (widget.mobileNumber != null && widget.mobileNumber!.isNotEmpty) {
        await prefs.setString('user_${widget.mobileNumber}_fullName', fullName);
        await prefs.setString('user_${widget.mobileNumber}_email', email);
        if (_imageBytes != null) {
          await prefs.setString('user_${widget.mobileNumber}_profileImage_bytes', base64Encode(_imageBytes!));
        }
        if (_imageFile != null && !kIsWeb) {
          await prefs.setString('user_${widget.mobileNumber}_profileImage_path', _imageFile!.path);
        }
      } else {
        await prefs.setString('registration_fullName', fullName);
        await prefs.setString('registration_email', email);
        if (_imageBytes != null) {
          await prefs.setString('registration_profileImage_bytes', base64Encode(_imageBytes!));
        }
        if (_imageFile != null && !kIsWeb) {
          await prefs.setString('registration_profileImage_path', _imageFile!.path);
        }
      }

      if (mounted) {
        Navigator.of(context).pop({
          'username': fullName,
          'email': email,
          'imageBytes': _imageBytes,
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile changes. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D1B4A).withOpacity(0.03),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).primaryColor, width: 3),
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                        ),
                        child: ClipOval(
                          child: _imageBytes != null
                              ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                              : (_imageFile != null && !kIsWeb)
                                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                                  : Icon(Icons.person, size: 44, color: Theme.of(context).primaryColor),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _captureSelfie,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: const Icon(Icons.photo_camera, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _validateName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save_alt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    label: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}