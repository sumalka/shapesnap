import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../widgets/bottom_nav_bar.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploading = false;
  Map<String, dynamic> _userData = {};
  String _userId = '';
  String _profileImagePath = '';
  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        _userId = user.uid;

        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _userData = data;
          });
          print('User data loaded from Firestore: $_userData');
        } else {
          print('No user document found in Firestore');
          await _createUserDocument(user);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? 'No name set',
        'email': user.email ?? 'No email set',
        'emailVerified': user.emailVerified,
        'profileComplete': false,
        'country': 'Not set',
        'dateOfBirth': 'Not set',
        'age': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _loadUserData();
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = 'profile_${user.uid}.jpg';
        final String localPath = path.join(appDir.path, fileName);

        final File imageFile = File(localPath);
        if (await imageFile.exists()) {
          setState(() {
            _profileImageFile = imageFile;
            _profileImagePath = localPath;
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final User? user = _auth.currentUser;
      if (user == null) return;

      final File imageFile = File(image.path);
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'profile_${user.uid}.jpg';
      final String localPath = path.join(appDir.path, fileName);

      await imageFile.copy(localPath);

      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': localPath,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageFile = File(localPath);
        _profileImagePath = localPath;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture saved!'),
            backgroundColor: Colors.pink,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.pink,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    if (_profileImageFile == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Picture'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (_profileImageFile != null && await _profileImageFile!.exists()) {
          await _profileImageFile!.delete();
        }

        final User? user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'profileImage': FieldValue.delete(),
          });
        }

        setState(() {
          _profileImageFile = null;
          _profileImagePath = '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile picture removed'),
              backgroundColor: Colors.pink,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.pink,
            ),
          );
        }
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bool hasImage = _profileImageFile != null;
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profile Picture',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2A4F),
                ),
              ),
              const SizedBox(height: 16),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Picture'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.pink),
                title: Text(hasImage ? 'Change Picture' : 'Upload Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }


  // FIXED: Format Date - Handles Firestore Timestamps

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Not set';

    try {
      DateTime date;

      // Check if it's a Firestore Timestamp
      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      }
      // Check if it's a String
      else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      }
      // Check if it's already a DateTime
      else if (dateValue is DateTime) {
        date = dateValue;
      }
      // Check if it's a Map (sometimes Firestore returns maps)
      else if (dateValue is Map) {
        // Try to parse as timestamp
        try {
          final seconds = dateValue['_seconds'] ?? dateValue['seconds'];
          final nanoseconds = dateValue['_nanoseconds'] ?? dateValue['nanoseconds'];
          if (seconds != null) {
            date = DateTime.fromMillisecondsSinceEpoch(
                (seconds * 1000).toInt() + ((nanoseconds ?? 0) / 1000000).toInt()
            );
          } else {
            return 'Not set';
          }
        } catch (e) {
          return 'Not set';
        }
      }
      // If it's a number (seconds since epoch)
      else if (dateValue is num) {
        date = DateTime.fromMillisecondsSinceEpoch((dateValue * 1000).toInt());
      }
      else {
        return 'Not set';
      }

      // Format the date
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      // Return formatted date: "15 Oct 2024 at 14:30"
      return '$day $month $year at $hour:$minute';

    } catch (e) {
      print('Error formatting date: $e');
      return 'Not set';
    }
  }

  String _cleanEmail(String? email) {
    if (email == null || email.isEmpty) return 'Not set';
    return email.trim();
  }

  String _getDisplayName() {
    if (_userData['name'] != null && _userData['name'].toString().isNotEmpty) {
      return _userData['name'];
    }
    final User? user = _auth.currentUser;
    return user?.displayName ?? 'No name set';
  }

  // SIGN OUT DIALOG - Without "Account" label

  Future<void> _signOut() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sign Out text
                Text(
                  'Sign Out?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2A4F),
                  ),
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  'On proceeding, you will be signed out\nof the app.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Divider
                Divider(
                  color: Colors.grey.shade200,
                  thickness: 1,
                ),
                const SizedBox(height: 16),
                // Action Buttons - CANCEL | SIGN OUT
                Row(
                  children: [
                    // Cancel Button - Outlined style
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sign Out Button - Primary
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE6186A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'SIGN OUT',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // If user confirmed, proceed with sign out
    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _auth.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Signed out successfully',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
                (route) => false,
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Error signing out',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.pink.shade100,
      child: Center(
        child: Icon(
          Icons.person,
          size: 60,
          color: Colors.pink.shade700,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.pink.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2A4F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String email = _cleanEmail(_userData['email']);
    String name = _getDisplayName();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Colors.pink,
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // HEADER - Big Logo with "Profile" text on right (PINK COLOR)
              SizedBox(
                height: 60,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Logo - big like home page with margin from left corner
                    Positioned(
                      left: 5,
                      top: -50,
                      child: Image.asset(
                        'assets/logo1.png',
                        height: 170,
                        width: 170,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.star,
                            color: Colors.pink,
                            size: 140,
                          );
                        },
                      ),
                    ),
                    // "Profile" text on the right - PINK COLOR
                    Positioned(
                      right: 15,
                      top: 20,
                      child: Text(
                        'Profile',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profile Avatar with Upload Option
              GestureDetector(
                onTap: _isUploading ? null : _showImageOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.pink.shade200,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _profileImageFile != null &&
                            _profileImageFile!.existsSync()
                            ? Image.file(
                          _profileImageFile!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                            : _buildDefaultAvatar(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.pink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: _isUploading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to change profile picture',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Verified User',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.pink.shade700,
                      ),
                    ),
                  ),
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2A4F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // User Info Cards
              _buildInfoCard(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: name,
              ),
              _buildInfoCard(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: email,
              ),
              _buildInfoCard(
                icon: Icons.public_outlined,
                label: 'Country',
                value: _userData['country'] ?? 'Not set',
              ),
              _buildInfoCard(
                icon: Icons.cake_outlined,
                label: 'Date of Birth',
                value: _formatDate(_userData['dateOfBirth']),
              ),
              _buildInfoCard(
                icon: Icons.calendar_today,
                label: 'Age',
                value: _userData['age'] != null && _userData['age'] > 0
                    ? '${_userData['age']} years'
                    : 'Not set',
              ),
              _buildInfoCard(
                icon: Icons.access_time,
                label: 'Member Since',
                value: _formatDate(_userData['createdAt']),
              ),

              const SizedBox(height: 16),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6186A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}