import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Widgets/custom_dialogs.dart';
import 'dart:convert';
import '../Services/api_service.dart';
import 'dart:io';
import 'dart:typed_data';
import '../Utils/validators.dart';
import '../Utils/status_messages.dart';
import '../Utils/phone_utils.dart';

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
        
        CustomDialogs.showSuccessDialog(
          context: context,
          title: 'Successful Capture',
          message: kIsWeb ? 'Profile photo selected successfully' : 'Profile photo captured successfully',
        );
      }
    } catch (e) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'Photo Error',
        message: kIsWeb ? 'Failed to select photo: $e' : 'Failed to capture photo: $e',
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
        CustomDialogs.showErrorDialog(
          context: context,
          title: 'Camera Error',
          message: 'Camera error: $error',
        );
        return null;
      });

      if (image != null) {
        setState(() {
          // store the file in mobile
          _selfieImage = File(image.path);
          _selfieImageBytes = null;
        });
        
        StatusMessages.success(context, message: 'Photo captured successfully!');
      }
    } catch (e) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'Camera Error',
        message: 'Camera error: $e',
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
        StatusMessages.success(context, message: 'Photo selected successfully!');
      }
    } catch (e) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'Image Selection Error',
        message: 'Error selecting image: $e',
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
      CustomDialogs.showSuccessDialog(
        context: context, 
        title: 'Successful Selection', 
        message: 'Signature selected successfully',
        );
    }
  } catch (e) {
    CustomDialogs.showErrorDialog(
      context: context,
      title: 'Signature Selection Error',
      message: 'Failed to select signature: $e',
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
            CustomDialogs.showErrorDialog(
              context: context,
              title: 'Validation Error',
              message: result['message'],
            );
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
            CustomDialogs.showErrorDialog(
              context: context,
              title: 'Validation Failed',
              message: 'Validation failed: $e',
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
      CustomDialogs.showWarningDialog(
        context: context,
        title: 'Photo Required',
        message: 'Please capture your photo',
      );
      return;
    }
    if (!_hasSignature()) {
      CustomDialogs.showWarningDialog(
        context: context,
        title: 'Signature Required',
        message: 'Please upload your signature',
      );
      return;
    }

    if (!_acceptedTerms) {
      CustomDialogs.showWarningDialog(
        context: context,
        title: 'Terms Required',
        message: 'Please accept the terms and conditions',
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
        // Save registration data to cache before navigating
        await _saveRegistrationDataToCache(
          _emailController.text,
          _selfieImageBytes ?? _selfieImage,
          _fullNameController.text,
        );
        
       CustomDialogs.showSuccessDialog(
          context: context,
          title: 'Registration Successful',
          message: 'Registration successful! Please login to your account.',
          buttonText: 'Login',
          onPressed: () {
            Navigator.of(context).pop();
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
            'fromRegistration': true,
          },
        );
        }
       );
      } else {
        CustomDialogs.showErrorDialog(
          context: context,
          title: 'Registration Failed',
          message: result['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'Registration Error',
        message: 'Registration failed: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _saveRegistrationDataToCache(String email, dynamic imageData, String fullName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String phoneKey = PhoneUtils.canonicalPhoneKey(_mobileController.text.trim());
      await prefs.setString('user_${phoneKey}_email', email);
      await prefs.setString('user_${phoneKey}_fullName', fullName);
      
      if (_selfieImageBytes != null) {
        String base64Image = base64Encode(_selfieImageBytes!);
        await prefs.setString('user_${phoneKey}_profileImage_bytes', base64Image);
        await prefs.remove('user_${phoneKey}_profileImage_path');
      } else if (_selfieImage != null) {
        await prefs.setString('user_${phoneKey}_profileImage_path', _selfieImage!.path);
        await prefs.remove('user_${phoneKey}_profileImage_bytes');
      }
      await prefs.setString('registration_email', email);
      await prefs.setString('registration_fullName', fullName);
      if (_selfieImageBytes != null) {
        String base64Image = base64Encode(_selfieImageBytes!);
        await prefs.setString('registration_profileImage_bytes', base64Image);
      } else if (_selfieImage != null) {
        await prefs.setString('registration_profileImage_path', _selfieImage!.path);
      }
    } catch (e) {}
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
            validator: Validators.fullName(),
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            validator: Validators.requiredDropdown('Gender'),
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
            validator: Validators.memberNumber(),
            decoration: const InputDecoration(
              labelText: 'Member Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _mobileController,
            validator: Validators.mobileNumberBasic(),
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
            validator: Validators.requiredDropdown('Identification type'),
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
            validator: Validators.idNumber(),
            decoration: const InputDecoration(
              labelText: 'Identification Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            validator: (v) => Validators.email(v, label: 'Email address'),
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
            validator: Validators.fullName(),
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _memberNumberController,
            validator: Validators.memberNumber(),
            decoration: const InputDecoration(
              labelText: 'Member Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _mobileController,
            validator: Validators.mobileNumberBasic(),
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
            validator: Validators.requiredDropdown('Identification type'),
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
            validator: Validators.idNumber(),
            decoration: const InputDecoration(
              labelText: 'Identification Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            validator: (v) => Validators.email(v, label: 'Email address'),
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
