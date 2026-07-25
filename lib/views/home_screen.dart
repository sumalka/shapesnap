import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/history_service.dart';
import '../models/history_entry.dart';
import '../models/body_shape.dart';
import '../widgets/bottom_nav_bar.dart';
import 'camera_screen.dart';
import 'occasion_screen.dart';
import 'history_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HistoryService _historyService = HistoryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  List<HistoryEntry> _recentHistory = [];
  List<HistoryEntry> _allHistory = [];
  bool _isLoading = true;
  bool _isBodyShapeExpanded = false;

  String _profileImagePath = '';
  File? _profileImageFile;
  String _userName = '';

  // Mock user body shape - in real app, get from storage
  BodyShape _userBodyShape = BodyShape.hourglass;

  // Style tips for different body shapes
  final Map<BodyShape, String> _styleTips = {
    BodyShape.hourglass: 'Emphasize your waist with belts and wrap dresses!',
    BodyShape.pear: 'Balance your silhouette with bold tops and dark bottoms!',
    BodyShape.rectangle: 'Create curves with peplum tops and ruffles!',
    BodyShape.invertedTriangle: 'Add volume to hips with A-line skirts!',
    BodyShape.apple: 'Create vertical lines with V-necks and long cardigans!',
  };

  // Body shape descriptions
  final Map<String, String> _bodyShapeDescriptions = {
    'Pear': 'Hips are wider than shoulders. Add volume to your upper body with bright colors and bold patterns.',
    'Hourglass': 'Balanced shoulders and hips with a defined waist. Your waist is your asset - emphasize it!',
    'Rectangle': 'Similar measurements throughout. Create curves with peplum tops, belts, and structured garments.',
    'Inverted Triangle': 'Shoulders are wider than hips. Balance your silhouette by adding volume to your lower body.',
    'Apple': 'Waist is wider than shoulders and hips. Create vertical lines with V-necks and long cardigans.',
  };

  // Daily fashion quotes
  final List<String> _fashionQuotes = [
    '"Fashion is the armor to survive the reality of everyday life."',
    '"Style is a way to say who you are without having to speak."',
    '"Fashion is about dreaming and making other people dream."',
    '"Elegance is not standing out, but being remembered."',
    '"Fashion is the most powerful art there is."',
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {'name': 'Casual', 'icon': Icons.style_outlined, 'color': Colors.pink},
    {'name': 'Office', 'icon': Icons.work_outline, 'color': Colors.pink},
    {'name': 'Party', 'icon': Icons.celebration_outlined, 'color': Colors.pink},
    {'name': 'Wedding', 'icon': Icons.auto_awesome, 'color': Colors.pink},
    {'name': 'Gym', 'icon': Icons.fitness_center, 'color': Colors.pink},
  ];

  // Body shape data for the guide
  final List<Map<String, dynamic>> _bodyShapeGuide = [
    {
      'name': 'Pear',
      'icon': Icons.water_drop_outlined,
      'description': 'Hips wider than shoulders',
    },
    {
      'name': 'Hourglass',
      'icon': Icons.hourglass_bottom,
      'description': 'Balanced shoulders & hips',
    },
    {
      'name': 'Rectangle',
      'icon': Icons.crop_square,
      'description': 'Balanced proportions',
    },
    {
      'name': 'Inverted Triangle',
      'icon': Icons.change_history,
      'description': 'Shoulders wider than hips',
    },
    {
      'name': 'Apple',
      'icon': Icons.circle_outlined,
      'description': 'Waist wider than shoulders',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final String userId = user.uid;

        // Load user data from Firebase
        final DataSnapshot snapshot = await _database.child('users').child(userId).get();
        if (snapshot.exists) {
          final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _userName = data['name'] ?? '';
          });
        }

        // Load profile image from local storage
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = 'profile_${userId}.jpg';
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
      print('Error loading profile: $e');
    }
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getAllHistory();
    setState(() {
      _allHistory = history;
      _recentHistory = history.take(3).toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteHistoryEntry(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this scan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyService.deleteEntry(id);
      _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Entry deleted'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('Are you sure you want to delete all scans? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyService.clearAllHistory();
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ All history cleared'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showBodyShapeDetails(BuildContext context, String shapeName) {
    final description = _bodyShapeDescriptions[shapeName] ?? 'Learn more about this body shape.';
    final icon = _bodyShapeGuide.firstWhere(
          (item) => item['name'] == shapeName,
      orElse: () => {'icon': Icons.person_outline},
    )['icon'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.pink.shade700,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                shapeName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2A4F),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pink.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _bodyShapeGuide.firstWhere(
                        (item) => item['name'] == shapeName,
                    orElse: () => {'description': ''},
                  )['description'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.pink.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '💡 Style Tip: ${_styleTips[_bodyShapeGuide.firstWhere((item) => item['name'] == shapeName)['name']] ?? 'Discover your perfect style!'}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.pink.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentDate = DateFormat('EEEE, MMM d').format(DateTime.now());
    final String tip = _styleTips[_userBodyShape] ?? 'Discover your perfect style!';
    final String quote = _fashionQuotes[DateTime.now().day % _fashionQuotes.length];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER - Using Stack to keep header height small while logo is big
              SizedBox(
                height: 60, // Fixed small height for header
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Logo - positioned slightly lower
                    Positioned(
                      left: -20,
                      top: -55, // Changed from -75 to -55 (moved down by 20px)
                      child: Image.asset(
                        'assets/logo1.png',  // Changed from 'assets/logo.png' to 'assets/logo1.png'
                        height: 180,
                        width: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.star,
                            color: Colors.pink,
                            size: 150,
                          );
                        },
                      ),
                    ),
                    // Date text - positioned in the header area
                    Positioned(
                      left: 150,
                      top: 20,
                      child: Text(
                        currentDate,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    // Profile avatar - positioned on the right
                    Positioned(
                      right: 0,
                      top: 5,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.pink.shade200,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _profileImageFile != null && _profileImageFile!.existsSync()
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
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // TOGGLEABLE BODY SHAPE GUIDE
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isBodyShapeExpanded = !_isBodyShapeExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pink.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            color: Colors.pink.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Body Shape Guide',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.pink.shade700,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _isBodyShapeExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.pink.shade700,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              // Body Shape Cards - Toggleable
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstChild: Container(),
                secondChild: Container(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _bodyShapeGuide.map((shape) {
                        return GestureDetector(
                          onTap: () {
                            _showBodyShapeDetails(context, shape['name']);
                          },
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(10),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(shape['icon'], color: Colors.pink, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  shape['name'],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1A2A4F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                crossFadeState: _isBodyShapeExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),

              const SizedBox(height: 16),

              // DAILY STYLE TIP
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💡 Style Tip of the Day',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF1A2A4F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Lottie.asset(
                      'assets/animations/arrow.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // MAIN ACTION - SCAN BUTTON
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE6186A), Color(0xFFC2185B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFFE6186A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan Your Body',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Take a photo to find your body shape',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // QUICK ACTIONS
              Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2A4F),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickActions.length,
                  itemBuilder: (context, index) {
                    final action = _quickActions[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OccasionScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 12),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                action['icon'],
                                color: Colors.pink,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              action['name'],
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1A2A4F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // MEDIA GALLERY SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library,
                        color: Colors.pink.shade400,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Media Gallery',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A2A4F),
                        ),
                      ),
                    ],
                  ),
                  if (_allHistory.isNotEmpty)
                    Text(
                      '${_allHistory.length} photos',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_allHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Center(
                        child: Lottie.asset(
                          'assets/animations/girl_animation.json',
                          height: 200,
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No media gallery yet',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take your first scan to build your gallery',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _allHistory.length > 9 ? 9 : _allHistory.length,
                  itemBuilder: (context, index) {
                    final entry = _allHistory[index];
                    return GestureDetector(
                      onLongPress: () {
                        _deleteHistoryEntry(entry.id);
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryDetailScreen(entry: entry),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(entry.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.pink.shade50,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.pink.shade300,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                entry.bodyShape,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _deleteHistoryEntry(entry.id),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              if (_allHistory.length > 9)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Full gallery view coming soon!'),
                          backgroundColor: Colors.pink,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pink.shade200),
                      ),
                      child: Text(
                        'View All ${_allHistory.length} Photos',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.pink.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // RECENT SCANS / HISTORY LIST
              Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Colors.pink.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Scans',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A2A4F),
                    ),
                  ),
                  if (_recentHistory.isNotEmpty)
                    const Spacer(),
                  if (_recentHistory.isNotEmpty)
                    GestureDetector(
                      onTap: _clearAllHistory,
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_recentHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Center(
                        child: Lottie.asset(
                          'assets/animations/loading.json',
                          height: 150,
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No recent scans yet',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take a photo to get started!',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentHistory.length,
                  itemBuilder: (context, index) {
                    final entry = _recentHistory[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryDetailScreen(entry: entry),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(entry.thumbnailPath),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.pink.shade50,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.pink.shade300,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.bodyShape,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A2A4F),
                                    ),
                                  ),
                                  Text(
                                    _formatDate(entry.timestamp),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteHistoryEntry(entry.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              // FASHION QUOTE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: Colors.pink.shade300,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        quote,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.pink.shade100,
      child: Center(
        child: Icon(
          Icons.person,
          size: 30,
          color: Colors.pink.shade700,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}