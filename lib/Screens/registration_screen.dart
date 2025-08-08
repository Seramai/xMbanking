import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../Services/api_service.dart';
import 'dart:io';
import 'dart:typed_data';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}
class _RegistrationScreenState extends State<RegistrationScreen> {
  // For step 1 and validation-form keys validate form fields
  final _formKey1 = GlobalKey<FormState>();
  // for the upload final step
  final _formKey2 = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _memberNumberController = TextEditingController();
  final _mobileController = TextEditingController();
  final _identificationNumberController = TextEditingController();
  final _emailController = TextEditingController();
  
  // File storage for mobile and desktop
  File? _selfieImage;
  File? _signatureDocument;
  
  // Web file storage
  Uint8List? _selfieImageBytes;
  Uint8List? _signatureDocumentBytes;
  String? _signatureDocumentName;
  // tracks the three step
  int _currentStep = 0;
  String? _selectedIdType;
  String? _selectedGender;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();
  final List<String> _idTypes = [
    'National ID',
    'Passport No',
    'Military No',
    'Driver\'s License No',
    'Birth Certificate No',
  ];
  final List<String> _genders =['M', 'F'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _memberNumberController.dispose();
    _mobileController.dispose();
    _identificationNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  // validation
  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  String? _validateMemberNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Member number is required';
    }
    if (value.trim().length < 3) {
      return 'Member number must be at least 3 characters';
    }
    return null;
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

  String? _validateIdType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select an identification type';
    }
    return null;
  }
  String? _validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select Gender';
    }
    return null;
  }


  String? _validateIdNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Identification number is required';
    }
    if (value.trim().length < 5) {
      return 'Identification number must be at least 5 characters';
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
  // Photo capture methods(enables selecting picture from gallery)-higher quality imgs
  Future<void> _captureSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        // Use camera for mobile, gallery for web
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selfieImageBytes = bytes;
            _selfieImage = null;
          });
        } else {
          setState(() {
            _selfieImage = File(image.path);
            _selfieImageBytes = null;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb ? 'Profile photo selected successfully' : 'Profile photo captured successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kIsWeb ? 'Failed to select photo: $e' : 'Failed to capture photo: $e'),
          backgroundColor: Colors.red,
        ),
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
          // store the file in mobile
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
Future<void> _pickSignature() async {
  try {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _signatureDocumentBytes = bytes;
        _signatureDocument = null; 
        _signatureDocumentName = 'signature.jpg';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature image selected successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to select signature: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  bool _hasSelfie() {
    return (_selfieImage != null || _selfieImageBytes != null);
  }

  bool _hasSignature() {
    return (_signatureDocument != null || _signatureDocumentBytes != null);
  }
  void _nextStep() async {
    if (_currentStep == 0) {
      if (_formKey1.currentState!.validate()) {
        setState(() {
          _currentStep = 1;
        });
      }
    } else if (_currentStep == 1) {
      // Second step here validate details with API
      if (_formKey1.currentState!.validate()) {
        setState(() {
          _isLoading = true;
        });
        
        try {
          final result = await ApiService.validateRegistration(
            fullName: _fullNameController.text,
            clientId: _memberNumberController.text,
            mobileNumber: _mobileController.text,
            identificationType: _selectedIdType!,
            identificationNumber: _identificationNumberController.text,
            emailAddress: _emailController.text,
          );
          
          setState(() {
            _isLoading = false;
          });
          
          if (result['success']) {
            setState(() {
              _currentStep = 2;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Validation failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep = _currentStep - 1;
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey2.currentState!.validate()) {
      return;
    }

    if (!_hasSelfie()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture your photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_hasSignature()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your signature'),
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
      final result = await ApiService.registerUser(
        fullName: _fullNameController.text,
        clientId: _memberNumberController.text,
        mobileNumber: _mobileController.text,
        identificationType: _selectedIdType!,
        identificationNumber: _identificationNumberController.text,
        emailAddress: _emailController.text,
        profileImageFile: _selfieImage,
        profileImageBytes: _selfieImageBytes,
        signatureFile: _signatureDocument,
        signatureBytes: _signatureDocumentBytes,
        signatureFileName: _signatureDocumentName,
        gender: _selectedGender!,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful! Please login to your account.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/login',
          (route)=> false,
          arguments: {
            'email': _emailController.text,
            'mobileNumber': _mobileController.text,
            'fullName': _fullNameController.text,
            'profileImageBytes': _selfieImageBytes,
            'profileImageFile': _selfieImage,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle network/connection errors
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

  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

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
          DropdownButtonFormField<String>(
            value: _selectedGender,
            validator: _validateGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: _genders.map((String gender){
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(gender == 'M' ? 'Male': 'Female'),
              );
            }).toList(),
            onChanged: (String? newValue){
              setState((){
                _selectedGender = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _memberNumberController,
            validator: _validateMemberNumber,
            decoration: const InputDecoration(
              labelText: 'Member Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
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

          DropdownButtonFormField<String>(
            value: _selectedIdType,
            validator: _validateIdType,
            decoration: const InputDecoration(
              labelText: 'Identification Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
            items: _idTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedIdType = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _identificationNumberController,
            validator: _validateIdNumber,
            decoration: const InputDecoration(
              labelText: 'Identification Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
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
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,  
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
                        Text('Validating...'),
                      ],
                    )
                  : const Text(
                      'Next Step',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
    // validation widget(confirm your details)
  Widget _buildValidationStep() {
    return Form(
      key: _formKey1, 
      child: Column(
        children: [
          const Text(
            'Confirm Your Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
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
            controller: _memberNumberController,
            validator: _validateMemberNumber,
            decoration: const InputDecoration(
              labelText: 'Member Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
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

          DropdownButtonFormField<String>(
            value: _selectedIdType,
            validator: _validateIdType,
            decoration: const InputDecoration(
              labelText: 'Identification Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
            items: _idTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedIdType = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _identificationNumberController,
            validator: _validateIdNumber,
            decoration: const InputDecoration(
              labelText: 'Identification Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
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
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                  child: const Text('Edit Details'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                  child: const Text(
                    'Confirm and Continue',
                    style: TextStyle(fontSize: 16)
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: Column(
        children: [
          const Text(
            'Photo & Signature',
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
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (_hasSelfie()) ...[
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: ClipOval(
                      child: _selfieImageBytes != null
                          ? Image.memory(
                              _selfieImageBytes!,
                              width: 116,
                              height: 116,
                              fit: BoxFit.cover,
                            )
                          : (_selfieImage != null && !kIsWeb)
                              ? Image.file(
                                  _selfieImage!,
                                  width: 116,
                                  height: 116,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.green,
                                ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Photo Selected ✓',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ] else ...[
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.grey, width: 2),
                      color: Colors.grey.shade100,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _captureSelfie,
                  icon: Icon(_hasSelfie() 
                    ? Icons.check_circle 
                    : (kIsWeb ? Icons.photo_library : Icons.camera_alt)),
                  label: Text(_hasSelfie() 
                    ? 'Change Photo' 
                    : (kIsWeb ? 'Select Photo' : 'Take Selfie')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasSelfie() 
                      ? Colors.green 
                      : Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'Signature',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_hasSignature()) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A237E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Signature: ${_signatureDocumentName ?? 'Selected'}'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A237E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.upload_file, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('No signature uploaded'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickSignature,
                  icon: Icon(_hasSignature() 
                    ? Icons.check_circle 
                    : Icons.upload_file),
                  label: Text(_hasSignature() 
                    ? 'Change Signature' 
                    : 'Upload Signature'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasSignature() 
                      ? Colors.green 
                      : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

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

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
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
            ],
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'Personal Details' : 
        _currentStep == 1 ? 'Confirm Details' : 'Photo & Signature'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentStep >= 1 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentStep >= 2
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)
                      ),
                    )
                  )
                ],
              ),
            ),
            Text(
              'Step ${_currentStep + 1} of 3',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _currentStep == 0 ? _buildStep1():
            _currentStep == 1 ? _buildValidationStep() : _buildStep2(),
            const SizedBox(height: 32),
            if (_currentStep == 0) ...[
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
          ],
        ),
      ),
    );
  }
}
