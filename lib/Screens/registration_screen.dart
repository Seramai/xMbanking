import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  // Mobile and Desktop file storage
  File? _selectedDocument;
  File? _selfieImage;
  
  // Web file storage
  Uint8List? _selectedDocumentBytes;
  Uint8List? _selfieImageBytes;
  String? _documentName;
  
  bool _acceptedTerms = false;
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  String? _validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    String cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.length < 10 || cleanNumber.length > 15) {
      return 'Enter a valid mobile number (10-15 digits)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null) {
        setState(() {
          if (kIsWeb) {
            _selectedDocumentBytes = result.files.single.bytes;
            _documentName = result.files.single.name;
            _selectedDocument = null;
          } else {
            _selectedDocument = File(result.files.single.path!);
            _selectedDocumentBytes = null;
            _documentName = result.files.single.name;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document uploaded: ${result.files.single.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureSelfie() async {
    if (kIsWeb) {
      await _pickImageFromGallery();
    } else {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _takeCameraPhoto();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _takeCameraPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      ).onError((error, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $error'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      });

      if (image != null) {
        setState(() {
          _selfieImage = File(image.path);
          _selfieImageBytes = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        if (kIsWeb) {
          _selfieImageBytes = await image.readAsBytes();
          _selfieImage = null;
        } else {
          _selfieImage = File(image.path);
          _selfieImageBytes = null;
        }
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _hasDocument() {
    return (_selectedDocument != null || _selectedDocumentBytes != null);
  }

  bool _hasSelfie() {
    return (_selfieImage != null || _selfieImageBytes != null);
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasDocument()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your ID document'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_hasSelfie()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture your selfie or select a photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate registration API call
      await Future.delayed(const Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to ${_emailController.text}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamed(
        context, 
        '/otp-verification',
        arguments: {
          'email': _emailController.text,
          'mobileNumber': _mobileController.text,
          'fullName': _fullNameController.text,
          'profileImageBytes': _selfieImageBytes,
          'profileImageFile': _selfieImage,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              const Icon(
                Icons.account_circle,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Join Our Platform',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Form fields
              TextFormField(
                controller: _fullNameController,
                validator: _validateFullName,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _mobileController,
                validator: _validateMobileNumber,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickDocument,
                      icon: Icon(_hasDocument() 
                        ? Icons.check_circle 
                        : Icons.description),
                      label: Text(_hasDocument() 
                        ? 'Document Selected' 
                        : 'Upload ID'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasDocument() 
                          ? Colors.green 
                          : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _captureSelfie,
                      icon: Icon(_hasSelfie() 
                        ? Icons.check_circle 
                        : (kIsWeb ? Icons.photo_library : Icons.camera_alt)),
                      label: Text(_hasSelfie() 
                        ? 'Photo Selected' 
                        : (kIsWeb ? 'Select Photo' : 'Take Photo')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasSelfie() 
                          ? Colors.green 
                          : Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              if (_hasDocument()) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Document: ${_documentName ?? 'Selected'}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              if (_hasSelfie()) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Photo: Selected'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: ClipOval(
                    child: _selfieImageBytes != null
                        ? Image.memory(
                            _selfieImageBytes!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          )
                        : (_selfieImage != null && !kIsWeb)
                            ? Image.file(
                                _selfieImage!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.green,
                              ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptedTerms = value ?? false;
                  });
                },
                title: const Text('I agree to the Terms and Conditions'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Account...'),
                          ],
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}