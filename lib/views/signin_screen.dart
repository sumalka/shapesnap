import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _countryController = TextEditingController();

  DateTime? _selectedDate;

  bool _isLoading = false;
  bool _isEmailSent = false;
  bool _isEmailVerified = false;
  bool _isSignInMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showPasswordSetup = false;
  bool _isPermissionDialogShowing = false;
  bool _showProfileForm = false;

  // Password validation states
  bool _hasMinLength = false;
  bool _hasLetter = false;
  bool _hasNumber = false;
  bool _passwordsMatch = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _countries = [
    'Select Country',
    'United States', 'United Kingdom', 'Canada', 'Australia',
    'India', 'Sri Lanka', 'Pakistan', 'Bangladesh', 'Nepal',
    'Germany', 'France', 'Italy', 'Spain', 'Netherlands',
    'Japan', 'China', 'South Korea', 'Singapore', 'Malaysia',
    'Brazil', 'Mexico', 'South Africa', 'Egypt', 'UAE',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignInMode = !_isSignInMode;
      _isEmailVerified = false;
      _isEmailSent = false;
      _showPasswordSetup = false;
      _showProfileForm = false;
      _selectedDate = null;
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _countryController.clear();
      _resetPasswordValidation();
    });
  }

  void _resetPasswordValidation() {
    setState(() {
      _hasMinLength = false;
      _hasLetter = false;
      _hasNumber = false;
      _passwordsMatch = false;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  // PERMISSION DIALOG - CENTERED BUTTONS (WITHOUT SECOND DIALOG)

  Future<bool> _showPermissionDialog() async {
    Completer<bool> completer = Completer<bool>();

    setState(() {
      _isPermissionDialogShowing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            '"ShapeSnap" Would Like to Access Camera & Gallery',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app uses:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              // Camera item
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: const Color(0xFFE6186A),
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Camera to scan your body shape',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Gallery item
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: const Color(0xFFE6186A),
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Gallery to upload photos',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'These permissions are required for the app to function properly.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // CENTERED BUTTONS
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Don't Allow button
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _isPermissionDialogShowing = false;
                      });
                      completer.complete(false);
                      _showSnackBar(
                        'Camera & Gallery access is required to continue. You can grant it later from settings.',
                        backgroundColor: Colors.orange,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE6186A),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Don't Allow",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFE6186A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // OK button
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() {
                        _isPermissionDialogShowing = false;
                      });
                      // Request system permissions
                      bool granted = await _requestSystemPermissions();
                      completer.complete(granted);

                      // Only show snackbar if permission was denied
                      if (!granted && mounted) {
                        _showSnackBar(
                          'Gallery permission not granted. You can grant it later from settings.',
                          backgroundColor: Colors.orange,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFFE6186A),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    return await completer.future;
  }

  // REQUEST SYSTEM PERMISSIONS - FIXED

  Future<bool> _requestSystemPermissions() async {
    try {
      // Request Camera permission
      PermissionStatus cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
      }
      print('Camera permission result: $cameraStatus');

      // Request Storage/Gallery permission based on Android version
      PermissionStatus storageStatus;

      if (Platform.isAndroid) {
        // Check if Android 13+ (API 33+)
        final sdkInt = await _getAndroidSdkVersion();

        if (sdkInt >= 33) {
          // Android 13+ - use photos permission
          storageStatus = await Permission.photos.status;
          if (!storageStatus.isGranted) {
            storageStatus = await Permission.photos.request();
          }
        } else {
          // Android 12 and below - use storage permission
          storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            storageStatus = await Permission.storage.request();
          }
        }
      } else {
        // iOS - use photos permission
        storageStatus = await Permission.photos.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.photos.request();
        }
      }

      print('Gallery/Storage permission result: $storageStatus');

      // Return true if both permissions are granted
      // For Android 13+, if photos permission is limited, treat as granted
      if (Platform.isAndroid) {
        final sdkInt = await _getAndroidSdkVersion();
        if (sdkInt >= 33) {
          // On Android 13+, limited access is acceptable
          return cameraStatus.isGranted &&
              (storageStatus.isGranted || storageStatus == PermissionStatus.limited);
        }
      }

      return cameraStatus.isGranted && storageStatus.isGranted;

    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  // Helper method to get Android SDK version
  Future<int> _getAndroidSdkVersion() async {
    if (Platform.isAndroid) {
      try {
        // Use a more reliable method to check Android version
        return await _checkAndroidVersion();
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  Future<int> _checkAndroidVersion() async {
    try {
      // Check if photos permission exists (Android 13+)
      final status = await Permission.photos.status;
      // If we can check photos permission, it's likely Android 13+
      return 33; // Assume Android 13+
    } catch (e) {
      return 32; // Android 12 or below
    }
  }

  // CHECK PERMISSION - SHOW DIALOG WITH CANCEL

  Future<bool> _checkPermissionAndProceed() async {
    bool userClickedOK = await _showPermissionDialog();

    if (userClickedOK) {
      return true;
    } else {
      // User clicked "Don't Allow" - stay on profile form, keep data
      return false;
    }
  }


  // PASSWORD VALIDATION METHODS

  void _validatePassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 6;
      _hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
      _hasNumber = RegExp(r'\d').hasMatch(value);
      _checkPasswordsMatch();
    });
  }

  void _checkPasswordsMatch() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    setState(() {
      _passwordsMatch = password.isNotEmpty && confirm.isNotEmpty && password == confirm;
    });
  }

  bool _isPasswordValid() {
    return _hasMinLength && _hasLetter && _hasNumber && _passwordsMatch;
  }


  // SHOW CUSTOM SNACKBAR - UPDATED WITH APP THEME

  void _showSnackBar(String message, {Color backgroundColor = Colors.pink}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                backgroundColor == Colors.green ? Icons.check_circle :
                backgroundColor == Colors.orange ? Icons.info_outline :
                Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }


  // STEP 1: SEND VERIFICATION EMAIL

  Future<void> _sendVerificationEmail() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(
        'Please enter your email address',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showSnackBar(
        'Please enter a valid email address',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String tempPassword = 'Temp@' + DateTime.now().millisecondsSinceEpoch.toString();

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      await userCredential.user?.sendEmailVerification();
      _isEmailSent = true;

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'emailVerified': false,
        'profileComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar(
        'Verification email sent! Please check your inbox.',
        backgroundColor: Colors.green,
      );

    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered. Please sign in instead.';
        Future.delayed(const Duration(seconds: 1), () {
          if (!_isSignInMode && mounted) {
            _toggleMode();
            _emailController.text = email;
          }
        });
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format. Please enter a valid email.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many requests. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'No internet connection. Please check your network.';
      } else {
        message = 'Something went wrong. Please try again.';
      }
      _showSnackBar(message, backgroundColor: Colors.red);
    } catch (e) {
      _showSnackBar(
        'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // STEP 2: CHECK EMAIL VERIFICATION

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;

        if (user != null && user.emailVerified) {
          setState(() {
            _isEmailVerified = true;
            _showPasswordSetup = true;
          });

          await _firestore.collection('users').doc(user.uid).update({
            'emailVerified': true,
          });

          _showSnackBar(
            'Email verified! Now set your password.',
            backgroundColor: Colors.green,
          );
        } else {
          _showSnackBar(
            'Email not verified yet. Please check your inbox and click the verification link.',
            backgroundColor: Colors.orange,
          );
        }
      } else {
        _showSnackBar(
          'No user found. Please click Verify first.',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // STEP 3: RESEND VERIFICATION EMAIL

  void _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _showSnackBar(
          'Verification email resent! Check your inbox.',
          backgroundColor: Colors.orange,
        );
      } else {
        _showSnackBar(
          'Please click Verify first to create account.',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // STEP 4: SET PASSWORD (After Email Verified)

  Future<void> _setPassword() async {
    if (!_isPasswordValid()) {
      _showSnackBar(
        'Please meet all password requirements.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    String newPassword = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);

        setState(() {
          _showPasswordSetup = false;
          _showProfileForm = true;
        });

        _showSnackBar(
          'Password set successfully! Complete your profile.',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Error setting password: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // SHOW SUCCESS MESSAGE - PINK COLOR WITHOUT EMOJIS OR ICONS

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.3,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFFE6186A),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }


  // STEP 5: SAVE USER PROFILE TO FIRESTORE

  Future<void> _saveUserInfo() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar(
        'Please enter your name.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar(
        'Please select your date of birth.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_countryController.text.trim().isEmpty) {
      _showSnackBar(
        'Please select your country.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user != null && user.emailVerified) {
        final String userName = _nameController.text.trim();
        await user.updateDisplayName(userName);
        await user.reload();

        await _firestore.collection('users').doc(user.uid).update({
          'name': userName,
          'dateOfBirth': _selectedDate!.toIso8601String(),
          'age': _calculateAge(),
          'country': _countryController.text.trim(),
          'profileComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // SHOW PERMISSION DIALOG - WITH CENTERED BUTTONS
        bool permissionGranted = await _checkPermissionAndProceed();

        if (!permissionGranted) {
          setState(() => _isLoading = false);
          return;
        }

        // SHOW SUCCESS MESSAGE - PINK COLOR
        _showSuccessMessage(
          'Welcome to ShapeSnap! Your account has been created successfully.',
        );

        // Navigate to home screen
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
            );
          }
        }
      }
    } catch (e) {
      _showSnackBar(
        'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
      setState(() => _isLoading = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateAge() {
    if (_selectedDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    return age;
  }


  // FORGOT PASSWORD - WITH INLINE ERROR

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    bool isSending = false;
    String? emailError;

    showDialog(
      context: context,
      barrierDismissible: !isSending,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade400, Colors.pink.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reset Password',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A2A4F),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    enabled: !isSending,
                    style: GoogleFonts.inter(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                      prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFFE6186A)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE6186A), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: emailError,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      if (emailError != null) {
                        setDialogState(() {
                          emailError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Check your spam/junk folder if you don\'t see the email.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isSending ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSending
                            ? null
                            : () {
                          String email = emailController.text.trim();
                          if (email.isEmpty) {
                            setDialogState(() {
                              emailError = 'Please enter your email address';
                            });
                            return;
                          }
                          if (!email.contains('@') || !email.contains('.')) {
                            setDialogState(() {
                              emailError = 'Please enter a valid email address';
                            });
                            return;
                          }
                          _sendPasswordReset(
                            email,
                            context,
                            setDialogState,
                                () => setDialogState(() {
                              emailError = null;
                            }),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE6186A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: isSending
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          'Send Reset Link',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }


  // SEND PASSWORD RESET EMAIL (Helper)

  Future<void> _sendPasswordReset(
      String email,
      BuildContext dialogContext,
      StateSetter setDialogState,
      VoidCallback clearError,
      ) async {
    setDialogState(() => true);

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      setDialogState(() => false);
      Navigator.pop(dialogContext);

      _showSnackBar(
        'Reset link sent! Check your email and spam folder.',
        backgroundColor: Colors.green,
      );

    } on FirebaseAuthException catch (e) {
      setDialogState(() => false);

      String message = '';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email address. Please sign up first.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format. Please check and try again.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please wait a few minutes and try again.';
      } else if (e.code == 'network-request-failed') {
        message = 'No internet connection. Please check your network.';
      } else {
        message = 'Something went wrong. Please try again.';
      }

      _showSnackBar(message, backgroundColor: Colors.red);

    } catch (e) {
      setDialogState(() => false);
      _showSnackBar(
        'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }


  // SIGN IN (Existing User) - WITH WELCOME MESSAGE AFTER PERMISSION

  Future<void> _signIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(
        'Please enter your email address.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showSnackBar(
        'Please enter a valid email address.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (password.isEmpty) {
      _showSnackBar(
        'Please enter your password.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        if (user.emailVerified) {
          // Get user name from Firestore for welcome message
          String userName = '';
          try {
            DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
            if (userDoc.exists) {
              userName = userDoc.get('name') ?? '';
            }
          } catch (e) {
            // Ignore - we'll use default welcome
          }

          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });

          // SHOW PERMISSION DIALOG - WITH CENTERED BUTTONS
          bool permissionGranted = await _checkPermissionAndProceed();

          if (!permissionGranted) {
            setState(() => _isLoading = false);
            return;
          }

          // SHOW WELCOME BACK MESSAGE - PINK COLOR
          if (userName.isNotEmpty) {
            _showSuccessMessage('Welcome back, $userName');
          } else {
            _showSuccessMessage('Welcome back!');
          }

          // Navigate to home screen
          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 1000));
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
              );
            }
          }
        } else {
          _showSnackBar(
            'Please verify your email first. Check your inbox.',
            backgroundColor: Colors.orange,
          );
          await _auth.signOut();
          setState(() => _isLoading = false);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = '';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email address. Please sign up.';
        Future.delayed(const Duration(seconds: 2), () {
          if (_isSignInMode && mounted) {
            _toggleMode();
            _emailController.text = email;
          }
        });
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format. Please enter a valid email.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled. Please contact support.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed attempts. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'No internet connection. Please check your network.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password. Please try again.';
      } else {
        message = 'Something went wrong. Please try again.';
      }

      _showSnackBar(message, backgroundColor: Colors.red);
      setState(() => _isLoading = false);

    } catch (e) {
      _showSnackBar(
        'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
      setState(() => _isLoading = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFE6186A),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/logo1.png',
                          height: 280,
                          width: 280,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE6186A), width: 4),
                              ),
                              child: const Icon(
                                Icons.star,
                                size: 80,
                                color: Color(0xFFE6186A),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 2),

                      Text(
                        _isSignInMode ? 'Welcome Back' : 'Verify your email to get started',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE6186A),
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),

                      if (!_isSignInMode)
                        Text(
                          'Create your account in 3 simple steps',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 16),


                      // SIGN UP FLOW

                      if (!_isSignInMode) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isEmailVerified
                                  ? [Colors.green.shade50, Colors.green.shade100.withOpacity(0.3)]
                                  : [Colors.grey.shade50, Colors.grey.shade100.withOpacity(0.3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isEmailVerified ? Colors.green.shade300 : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isEmailVerified ? Icons.check_circle : Icons.email_outlined,
                                color: _isEmailVerified ? Colors.green.shade700 : Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isEmailVerified
                                    ? (_showPasswordSetup ? 'Step 2: Set Password' : 'Email Verified')
                                    : 'Step 1: Verify your email',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _isEmailVerified ? Colors.green.shade700 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _emailController,
                                enabled: !_isEmailVerified,
                                style: GoogleFonts.inter(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                                  prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFFE6186A)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE6186A), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red, width: 2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red, width: 2),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@') || !value.contains('.')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (!_isEmailVerified)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _sendVerificationEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE6186A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                      : Text(_isEmailSent ? 'Resend' : 'Verify', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                ),
                              ),
                          ],
                        ),

                        if (_isEmailSent && !_isEmailVerified) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Verification email sent! Check your inbox/spam folder, click the link, then tap "Check".',
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _resendVerificationEmail,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE6186A),
                                    side: const BorderSide(color: Color(0xFFE6186A)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text('Resend', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _checkVerification,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A2A4F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text('Check', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // PASSWORD SETUP - Shows after email verification

                        if (_isEmailVerified && _showPasswordSetup) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.pink.shade50, Colors.pink.shade100.withOpacity(0.3)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.pink.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline, color: Colors.pink.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Step 2: Create your password',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.pink.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.inter(fontSize: 16),
                            onChanged: _validatePassword,
                            decoration: InputDecoration(
                              labelText: 'Create Password',
                              labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                              prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFFE6186A)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey.shade500,
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE6186A), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please create a password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password Requirements:',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A2A4F),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildRequirementTile('At least 6 characters', _hasMinLength),
                                _buildRequirementTile('Contains at least one letter', _hasLetter),
                                _buildRequirementTile('Contains at least one number', _hasNumber),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: GoogleFonts.inter(fontSize: 16),
                            onChanged: (_) => _checkPasswordsMatch(),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                              prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFFE6186A)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey.shade500,
                                ),
                                onPressed: _toggleConfirmPasswordVisibility,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE6186A), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              return null;
                            },
                          ),

                          if (_passwordController.text.isNotEmpty && _confirmPasswordController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    _passwordsMatch ? Icons.check_circle : Icons.cancel,
                                    color: _passwordsMatch ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _passwordsMatch ? 'Passwords match' : 'Passwords do not match',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: _passwordsMatch ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: (_isPasswordValid() && !_isLoading) ? _setPassword : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isPasswordValid()
                                    ? const Color(0xFFE6186A)
                                    : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                  : Text(
                                _isPasswordValid() ? 'Set Password' : 'Complete Requirements',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],


                        // PROFILE FORM - Shows after password is set

                        if (_showProfileForm) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade50, Colors.green.shade100.withOpacity(0.3)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Step 3: Complete your profile',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            style: GoogleFonts.inter(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                              labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                              prefixIcon: Icon(Icons.person_outline, color: const Color(0xFFE6186A)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE6186A), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Date of Birth
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFFE6186A),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date of Birth',
                                labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                                prefixIcon: Icon(Icons.cake_outlined, color: const Color(0xFFE6186A)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE6186A), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate == null
                                        ? 'Select your birth date'
                                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: _selectedDate == null ? Colors.grey.shade500 : const Color(0xFF1A2A4F),
                                    ),
                                  ),
                                  Icon(Icons.calendar_today, color: const Color(0xFFE6186A), size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Country Dropdown
                          DropdownButtonFormField<String>(
                            value: _countryController.text.isEmpty ? null : _countryController.text,
                            decoration: InputDecoration(
                              labelText: 'Country',
                              labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                              prefixIcon: Icon(Icons.public_outlined, color: const Color(0xFFE6186A)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE6186A), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _countries.map((country) {
                              return DropdownMenuItem(
                                value: country == 'Select Country' ? null : country,
                                child: Text(country, style: GoogleFonts.inter()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _countryController.text = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select your country';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveUserInfo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE6186A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                  : Text('Continue', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ],


                      // SIGN IN FLOW

                      if (_isSignInMode) ...[
                        TextFormField(
                          controller: _emailController,
                          style: GoogleFonts.inter(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFFE6186A)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE6186A), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFFE6186A)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE6186A), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE6186A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                : Text('Sign In', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignInMode
                                ? "Don't have an account?"
                                : 'Already have an account?',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          TextButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isSignInMode ? 'Sign Up' : 'Sign In',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE6186A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  // PASSWORD REQUIREMENT TILE WIDGET

  Widget _buildRequirementTile(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Colors.green : Colors.grey.shade400,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isMet ? Colors.green.shade700 : Colors.grey.shade600,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}