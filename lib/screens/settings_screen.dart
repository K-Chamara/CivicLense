import 'package:flutter/material.dart';
<<<<<<< Updated upstream
<<<<<<< Updated upstream
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/otp_service.dart';
=======
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../main.dart';
>>>>>>> Stashed changes
=======
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../main.dart';
>>>>>>> Stashed changes

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
  final AuthService _authService = AuthService();
  final OTPService _otpService = OTPService();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  File? _selectedImage;
  String? _currentProfileImageUrl;
  bool _isLoading = false;
  bool _isPasswordChangeMode = false;
  bool _isOTPVerificationMode = false;
  String? _otpSessionId;
=======
  String _selectedLanguage = 'en';
  String _selectedCurrency = 'LKR';
  bool _isLoading = true;
>>>>>>> Stashed changes
=======
  String _selectedLanguage = 'en';
  String _selectedCurrency = 'LKR';
  bool _isLoading = true;
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData != null) {
          setState(() {
            _usernameController.text = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
            _currentProfileImageUrl = userData['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error loading user data: $e');
=======
=======
>>>>>>> Stashed changes
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final language = await SettingsService.getLanguage();
      final currency = await SettingsService.getCurrency();
      
      setState(() {
        _selectedLanguage = language;
        _selectedCurrency = currency;
      });
    } catch (e) {
      print('Error loading settings: $e');
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    } finally {
      setState(() => _isLoading = false);
    }
  }

<<<<<<< Updated upstream
<<<<<<< Updated upstream
  Future<void> _pickImage() async {
    // Clear any existing error messages
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Show direct Gallery/Camera selection dialog
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from your photo library'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImageFromSource(source);
    }
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      // Check and request permissions first
      bool hasPermission = await _checkAndRequestPermission(source);
      if (!hasPermission) {
        _showErrorSnackBar('Permission denied. Please try again and allow ${source == ImageSource.gallery ? 'gallery' : 'camera'} access when prompted.');
        return;
      }

      // Show loading indicator
      _showLoadingSnackBar('Opening ${source == ImageSource.gallery ? 'Gallery' : 'Camera'}...');
      
      // Add a small delay to ensure the dialog is closed
      await Future.delayed(const Duration(milliseconds: 300));
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null && image.path.isNotEmpty) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showSuccessSnackBar('Image selected successfully!');
      }
    } catch (e) {
      // Handle specific errors with clear messages
      String errorMessage = '';
      if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please try again and allow ${source == ImageSource.gallery ? 'gallery' : 'camera'} access when prompted.';
      } else if (e.toString().contains('camera') && source == ImageSource.camera) {
        errorMessage = 'Camera not available. Please try selecting from gallery instead.';
      } else if (e.toString().contains('channel-error')) {
        errorMessage = 'Image picker service is temporarily unavailable. Please try again in a few moments.';
      } else {
        errorMessage = 'Error picking image: ${e.toString()}';
      }
      
      _showErrorSnackBarWithRetry(errorMessage);
    }
  }

  void _showErrorSnackBarWithRetry(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Try Again',
          textColor: Colors.white,
          onPressed: () {
            _pickImage(); // Retry the image picker
          },
        ),
      ),
    );
  }

  Future<bool> _checkAndRequestPermission(ImageSource source) async {
    Permission permission;
    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      permission = Permission.photos;
    }

    // Always request permission to trigger native popup
    PermissionStatus status = await permission.request();
    
    if (status.isGranted) {
      return true;
    }

    // If permission is denied but not permanently, try again
    if (status.isDenied) {
      // Show a brief message and try again
      _showLoadingSnackBar('Requesting permission...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Try requesting again
      status = await permission.request();
      if (status.isGranted) {
        return true;
      }
    }

    // If permission is permanently denied, show dialog to open settings
    if (status.isPermanentlyDenied) {
      if (mounted) {
        bool? shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: Text(
              '${source == ImageSource.gallery ? 'Gallery' : 'Camera'} permission is required to select images. Please enable it in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
      }
    }

    return false;
  }


  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload image to Firebase Storage
      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
      await ref.putFile(_selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      // Update user document in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _currentProfileImageUrl = imageUrl;
        _selectedImage = null;
      });

      _showSuccessSnackBar('Profile image updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Error uploading image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a username');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final nameParts = _usernameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await _firestore.collection('users').doc(user.uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Username updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Error updating username: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiatePasswordChange() async {
    if (_currentPasswordController.text.isEmpty) {
      _showErrorSnackBar('Please enter your current password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Verify current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      
      await user.reauthenticateWithCredential(credential);

      // Send OTP for password change
      final otpResult = await _otpService.sendOTP(user.email!);
      
      setState(() {
        _isPasswordChangeMode = true;
        _isOTPVerificationMode = true;
        _otpSessionId = otpResult['sessionId'];
      });

      // Show success message with email method info
      String successMessage = 'OTP sent to your email. Please check your inbox and enter the code below.';
      if (otpResult['emailMethod'] != null) {
        successMessage += '\n\nSent via: ${otpResult['emailMethod']}';
      }
      _showSuccessSnackBar(successMessage);
    } catch (e) {
      String errorMessage = 'Error verifying current password: ';
      
      // Provide more specific error messages
      if (e.toString().contains('Failed to send OTP')) {
        errorMessage += 'Unable to send OTP email. Please check your internet connection and try again.';
      } else if (e.toString().contains('reauthenticateWithCredential')) {
        errorMessage += 'Current password is incorrect. Please try again.';
      } else if (e.toString().contains('network')) {
        errorMessage += 'Network error. Please check your internet connection.';
      } else {
        errorMessage += e.toString();
      }
      
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTPAndChangePassword() async {
    if (_otpController.text.isEmpty) {
      _showErrorSnackBar('Please enter the OTP');
      return;
    }

    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showErrorSnackBar('Please enter new password and confirmation');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Verify OTP
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _otpService.verifyOTP(_otpController.text, _otpSessionId!);

      // Change password
      await user.updatePassword(_newPasswordController.text);

      // Clear form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _otpController.clear();

      setState(() {
        _isPasswordChangeMode = false;
        _isOTPVerificationMode = false;
        _otpSessionId = null;
      });

      _showSuccessSnackBar('Password changed successfully!');
    } catch (e) {
      _showErrorSnackBar('Error changing password: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }


  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Settings'),
=======
=======
>>>>>>> Stashed changes
  Future<void> _saveSettings() async {
    try {
      await SettingsService.setLanguage(_selectedLanguage);
      await SettingsService.setCurrency(_selectedCurrency);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.success),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload the app locale to apply language changes
        reloadAppLocale();
        
        // Navigate back to home
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
      backgroundColor: Colors.grey.shade50,
>>>>>>> Stashed changes
=======
      backgroundColor: Colors.grey.shade50,
>>>>>>> Stashed changes
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
<<<<<<< Updated upstream
<<<<<<< Updated upstream
                  _buildProfileSection(),
                  const SizedBox(height: 24),
                  _buildUsernameSection(),
                  const SizedBox(height: 24),
                  _buildPasswordSection(),
                  const SizedBox(height: 24),
                  _buildAccountInfoSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_currentProfileImageUrl != null
                            ? NetworkImage(_currentProfileImageUrl!)
                            : null),
                    child: _selectedImage == null && _currentProfileImageUrl == null
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedImage != null ? 'New image selected' : 'Current profile image',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedImage != null
                            ? 'Tap to change or upload to save'
                            : 'Tap to change your profile picture',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploadProfileImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Profile Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Username',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateUsername,
                icon: const Icon(Icons.save),
                label: const Text('Update Username'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!_isPasswordChangeMode) ...[
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  hintText: 'Enter your current password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _initiatePasswordChange,
                  icon: const Icon(Icons.security),
                  label: const Text('Verify Current Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else if (_isOTPVerificationMode) ...[
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
                  hintText: 'Enter the 6-digit OTP',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.verified_user),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter your new password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  hintText: 'Confirm your new password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isPasswordChangeMode = false;
                          _isOTPVerificationMode = false;
                          _otpSessionId = null;
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                          _otpController.clear();
                        });
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _verifyOTPAndChangePassword,
                      icon: const Icon(Icons.check),
                      label: const Text('Change Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
=======
=======
>>>>>>> Stashed changes
                  // Language Section
                  _buildSectionCard(
                    title: l10n.language,
                    icon: Icons.language,
                    children: [
                      ...SettingsService.languages.entries.map((entry) {
                        return _buildRadioTile(
                          title: entry.value,
                          value: entry.key,
                          groupValue: _selectedLanguage,
                          onChanged: (value) async {
                            setState(() {
                              _selectedLanguage = value!;
                            });
                            // Save language immediately
                            await SettingsService.setLanguage(value!);
                            // Reload the app locale to apply changes
                            reloadAppLocale();
                          },
                        );
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Currency Section
                  _buildSectionCard(
                    title: l10n.currency,
                    icon: Icons.attach_money,
                    children: [
                      ...SettingsService.currencies.entries.map((entry) {
                        return _buildRadioTile(
                          title: entry.value,
                          value: entry.key,
                          groupValue: _selectedCurrency,
                          onChanged: (value) async {
                            setState(() {
                              _selectedCurrency = value!;
                            });
                            // Save currency immediately
                            await SettingsService.setCurrency(value!);
                          },
                        );
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.save,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reset Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await SettingsService.resetToDefaults();
                        await _loadSettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${l10n.settings} ${l10n.reset.toLowerCase()}'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '${l10n.reset} ${l10n.settings.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
                      ),
                    ),
                  ),
                ],
              ),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    final user = FirebaseAuth.instance.currentUser;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
=======
=======
>>>>>>> Stashed changes
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< Updated upstream
<<<<<<< Updated upstream
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', user?.email ?? 'Not available'),
            _buildInfoRow(Icons.person, 'User ID', user?.uid ?? 'Not available'),
            _buildInfoRow(Icons.access_time, 'Last Sign In', 
                user?.metadata.lastSignInTime?.toString() ?? 'Not available'),
            _buildInfoRow(Icons.verified, 'Email Verified', 
                user?.emailVerified == true ? 'Yes' : 'No'),
=======
=======
>>>>>>> Stashed changes
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
          ],
        ),
      ),
    );
  }

<<<<<<< Updated upstream
<<<<<<< Updated upstream
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
=======
=======
>>>>>>> Stashed changes
  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: groupValue == value ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: groupValue == value ? Colors.blue : Colors.grey.withOpacity(0.3),
          width: groupValue == value ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: groupValue == value ? FontWeight.bold : FontWeight.normal,
            color: groupValue == value ? Colors.blue : null,
          ),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: Colors.blue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
      ),
    );
  }
}
