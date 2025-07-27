import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Text editing controllers for form fields
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  // State variables for file uploads and user interactions
  File? _selectedDocument; // Stores the selected ID document
  File? _selfieImage; // Stores the captured image
  bool _acceptedTerms = false; // Tracks terms and conditions acceptance
  bool _isLoading = false; // Shows loading state during submission
  
  // Image picker instance for camera and gallery access
  final ImagePicker _picker = ImagePicker();
  
  // Step tracking for multi-step form experience
  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _mobileController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // Mobile number validation
  String? _validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    // Remove any non-digit characters for validation
    String cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.length < 10 || cleanNumber.length > 15) {
      return 'Enter a valid mobile number (10-15 digits)';
    }
    return null;
  }

  //Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }
    // Comprehensive email validation pattern
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  //Full name validation
  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    // Check for at least first and last name
    if (!value.trim().contains(' ')) {
      return 'Please enter your full name (first and last name)';
    }
    return null;
  }

  // Document upload functionality with file type validation
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedDocument = File(result.files.single.path!);
        });
        
        // Show success feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Handle file picker errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking document: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Selfie capture functionality 
  Future<void> _captureSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
       // Force camera usage for selfie
        source: ImageSource.camera, 
        // Use front camera
        preferredCameraDevice: CameraDevice.front, 
         // Optimize image quality vs file size
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() {
          _selfieImage = File(image.path);
        });
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selfie captured successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Handle camera access errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing camera: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Form submission with validation and OTP initiation
  Future<void> _submitRegistration() async {
    // Validate all form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if document is uploaded
    if (_selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload your ID document'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check if selfie is captured
    if (_selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please capture your selfie'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check terms acceptance
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call for registration
      await Future.delayed(Duration(seconds: 2));
      // showing success and navigate to OTP screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful! Please verify your mobile number.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Handle registration errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // Hide loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Build progress indicator for multi-step experience
  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: index <= _currentStep 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  // Build form input field with consistent styling
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  //Build file upload card with visual feedback
  Widget _buildFileUploadCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    File? selectedFile,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                selectedFile != null ? Icons.check_circle : icon,
                size: 48,
                color: selectedFile != null ? Colors.green : color,
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                selectedFile != null 
                  ? 'File selected successfully' 
                  : 'Tap to select',
                style: TextStyle(
                  fontSize: 12,
                  color: selectedFile != null ? Colors.green : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //App bar with back navigation and title
      appBar: AppBar(
        title: Text('Create Account'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      
      body: Container(
        //Gradient background for visual appeal
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome header section
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Join Our Platform',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your account to get started',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  //Progress indicator
                  _buildProgressIndicator(),

                  //Personal information section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 24),
                          _buildInputField(
                            controller: _fullNameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person,
                            validator: _validateFullName,
                            keyboardType: TextInputType.name,
                          ),
                          _buildInputField(
                            controller: _mobileController,
                            label: 'Mobile Number',
                            hint: 'Enter your mobile number',
                            icon: Icons.phone,
                            validator: _validateMobileNumber,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                          ),
                          _buildInputField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'Enter your email address',
                            icon: Icons.email,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),
                  // Document verification section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identity Verification',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Upload your ID and take a selfie for verification',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 24),
                          // Document and selfie upload cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildFileUploadCard(
                                  title: 'ID Document',
                                  icon: Icons.description,
                                  onTap: _pickDocument,
                                  selectedFile: _selectedDocument,
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildFileUploadCard(
                                  title: 'Take Selfie',
                                  icon: Icons.camera_alt,
                                  onTap: _captureSelfie,
                                  selectedFile: _selfieImage,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _acceptedTerms = !_acceptedTerms;
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                    children: [
                                      TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms and Conditions',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32),
                  //Submit button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? Row(
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
                              Text(
                                'Creating Account...',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        : Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),

                  SizedBox(height: 24),

                  //Login redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to login screen (to be implemented)
                          // Navigator.pushNamed(context, '/login');
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}