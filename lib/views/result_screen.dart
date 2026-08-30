import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/body_shape.dart';
import '../services/image_recommendation_service.dart';
import '../services/history_service.dart';
import '../models/history_entry.dart';
import '../widgets/bottom_nav_bar.dart';
import 'camera_screen.dart';

class ResultScreen extends StatefulWidget {
  final File imageFile;
  final BodyShape bodyShape;
  final double shoulderHipRatio;
  final double shoulderWidth;
  final double hipWidth;
  final List<String> doRecommendations;
  final List<String> dontRecommendations;
  final List<String> occasions;
  final double confidence;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.bodyShape,
    required this.shoulderHipRatio,
    required this.shoulderWidth,
    required this.hipWidth,
    required this.doRecommendations,
    required this.dontRecommendations,
    required this.occasions,
    this.confidence = 0.0,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ImageRecommendationService _imageService = ImageRecommendationService();
  List<String> _doImages = [];
  List<String> _dontImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doImages = _imageService.getDoImages(widget.bodyShape);
      final dontImages = _imageService.getDontImages(widget.bodyShape);

      print('=== IMAGE PATHS ===');
      print('Body Shape: ${widget.bodyShape.displayName}');
      print('DO Image paths: $doImages');
      print('DON\'T Image paths: $dontImages');

      List<String> validDoImages = [];
      for (var path in doImages) {
        try {
          final data = await rootBundle.load(path);
          print('DO image found: $path (${data.lengthInBytes} bytes)');
          validDoImages.add(path);
        } catch (e) {
          print('DO image NOT found: $path');
        }
      }

      List<String> validDontImages = [];
      for (var path in dontImages) {
        try {
          final data = await rootBundle.load(path);
          print('DON\'T image found: $path (${data.lengthInBytes} bytes)');
          validDontImages.add(path);
        } catch (e) {
          print('DON\'T image NOT found: $path');
        }
      }

      setState(() {
        _doImages = validDoImages.isNotEmpty ? validDoImages : doImages;
        _dontImages = validDontImages.isNotEmpty ? validDontImages : dontImages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER - Big Logo with "Your Results" text on right (PINK COLOR)
            SizedBox(
              height: 60,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Logo - big with margin from left corner
                  Positioned(
                    left: 5,
                    top: -50,
                    child: Image.asset(
                      'assets/logo1.png',  // Changed from 'assets/logo.png' to 'assets/logo1.png'
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
                  // "Your Results" text on the right - PINK COLOR
                  Positioned(
                    right: 15,
                    top: 20,
                    child: Text(
                      'Your Results',
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
            const SizedBox(height: 10),
            // Body Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Body Shape Title
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink.shade50, Colors.pink.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getShapeIcon(widget.bodyShape),
                                size: 40,
                                color: Colors.pink.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.bodyShape.displayName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Body Shape Detected',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // About Your Shape with Confidence
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.pink.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.pink.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: Colors.pink.shade400,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'About Your Shape',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A2A4F),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: widget.confidence > 0.70
                                      ? Colors.green.shade100
                                      : widget.confidence > 0.50
                                      ? Colors.orange.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${(widget.confidence * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: widget.confidence > 0.70
                                        ? Colors.green.shade700
                                        : widget.confidence > 0.50
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.bodyShape.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.pink.shade400,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _getShapeTip(widget.bodyShape),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.pink.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // DO Recommendations - GREEN Theme
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'DO WEAR THESE',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.doRecommendations.length} styles',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // DO Images - Horizontal Row
                    _doImages.isNotEmpty
                        ? SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _doImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.white,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _buildDoImage(index),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Style ${index + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                        : const SizedBox.shrink(),

                    const SizedBox(height: 12),

                    // DO Numbered List - GREEN Theme
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...widget.doRecommendations.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green.shade800,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.favorite_outline,
                                color: Colors.green.shade400,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Style tips tailored for your body shape',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.green.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // DON'T Recommendations - RED Theme
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'AVOID THESE',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.dontRecommendations.length} styles',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // DON'T Images - Horizontal Row
                    _dontImages.isNotEmpty
                        ? SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _dontImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.white,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _buildDontImage(index),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Style ${index + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                        : const SizedBox.shrink(),

                    const SizedBox(height: 12),

                    // DON'T Numbered List - RED Theme
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...widget.dontRecommendations.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red.shade800,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.favorite_outline,
                                color: Colors.red.shade400,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Style tips tailored for your body shape',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.red.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Action Buttons - Pink Theme
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CameraScreen(),
                                ),
                                    (route) => false,
                              );
                            },
                            icon: const Icon(Icons.camera_alt, size: 20),
                            label: Text(
                              'New Scan',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.pink,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: Colors.pink.shade300, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _saveToHistory(context);
                            },
                            icon: const Icon(Icons.favorite_border, size: 20),
                            label: Text(
                              'Save',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  // DO image builder
  Widget _buildDoImage(int index) {
    if (index >= _doImages.length) {
      return Container(
        color: Colors.green.shade50,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.green, size: 30),
        ),
      );
    }
    return Image.asset(
      _doImages[index],
      fit: BoxFit.contain,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Failed to load DO image: ${_doImages[index]}");
        return Container(
          color: Colors.green.shade50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                color: Colors.green.shade300,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Image not found',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // DON'T image builder
  Widget _buildDontImage(int index) {
    if (index >= _dontImages.length) {
      return Container(
        color: Colors.red.shade50,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.red, size: 30),
        ),
      );
    }
    return Image.asset(
      _dontImages[index],
      fit: BoxFit.contain,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Failed to load DON'T image: ${_dontImages[index]}");
        return Container(
          color: Colors.red.shade50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                color: Colors.red.shade300,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Image not found',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getShapeIcon(BodyShape shape) {
    switch (shape) {
      case BodyShape.pear:
        return Icons.water_drop_outlined;
      case BodyShape.hourglass:
        return Icons.hourglass_bottom;
      case BodyShape.rectangle:
        return Icons.crop_square;
      case BodyShape.invertedTriangle:
        return Icons.change_history;
      case BodyShape.apple:
        return Icons.circle_outlined;
    }
  }

  String _getShapeTip(BodyShape shape) {
    switch (shape) {
      case BodyShape.pear:
        return 'Balance your silhouette by drawing attention to your upper body with bright colors and bold patterns.';
      case BodyShape.hourglass:
        return 'Your defined waist is your asset! Emphasize it with belts, wrap dresses, and fitted clothing.';
      case BodyShape.rectangle:
        return 'Create curves with peplum tops, belts, and structured garments that add volume to your silhouette.';
      case BodyShape.invertedTriangle:
        return 'Balance your broader shoulders by adding volume to your hips with A-line skirts and wide-leg pants.';
      case BodyShape.apple:
        return 'Create vertical lines with V-necks, long cardigans, and A-line dresses that flow away from the waist.';
    }
  }

  // Generate random recommendations for uniqueness
  List<String> _generateRandomRecommendations(BodyShape shape, {required bool isDo}) {
    final Map<BodyShape, Map<String, List<String>>> allRecommendations = {
      BodyShape.pear: {
        'do': [
          'A-line skirts', 'Dark wash jeans', 'Off-shoulder tops', 'Flowy blouses',
          'Wide-leg pants', 'Empire waist tops', 'Statement necklaces', 'Light colored tops',
          'Wrap tops', 'Flared skirts', 'Boat neck tops', 'Patterned blouses'
        ],
        'dont': [
          'Skinny jeans', 'Cropped tops', 'Horizontal stripes', 'Low-rise pants',
          'Tight dresses', 'Boxy tops', 'Pencil skirts', 'Drop waist dresses',
          'Baggy sweaters', 'Stiff fabrics', 'High necklines', 'Straight skirts'
        ],
      },
      BodyShape.hourglass: {
        'do': [
          'Wrap dresses', 'Belted jeans', 'V-neck t-shirts', 'High-waisted shorts',
          'Pencil skirts', 'Fitted blazers', 'Bodycon dresses', 'Deep V-neck tops',
          'Cinch waist belts', 'Peplum tops', 'Sheath dresses', 'Tailored trousers'
        ],
        'dont': [
          'Baggy clothes', 'Drop waist', 'Oversized tops', 'Boxy cuts',
          'Turtlenecks', 'Straight shift dresses', 'Unstructured jackets', 'Empire waist',
          'Loose sweaters', 'Sack dresses', 'Bulky knits', 'No-waist styles'
        ],
      },
      BodyShape.rectangle: {
        'do': [
          'Peplum tops', 'Belted dresses', 'Ruffle blouses', 'High-waisted jeans',
          'A-line skirts', 'Color blocking', 'Wrap dresses', 'Fitted jackets',
          'Layer styles', 'Pleated skirts', 'Tiered dresses', 'Structured shoulders'
        ],
        'dont': [
          'Straight shift dresses', 'Unstructured tops', 'Low-rise pants', 'Monochrome',
          'Baggy clothes', 'Sack dresses', 'Drop waist', 'Oversized blazers',
          'Straight cuts', 'No-waist styles', 'Boxy jackets', 'Tunic tops'
        ],
      },
      BodyShape.invertedTriangle: {
        'do': [
          'A-line skirts', 'Dark tops', 'Wide-leg pants', 'V-neck shirts',
          'Flared bottoms', 'Dark solid colors', 'Pleated skirts', 'Flared trousers',
          'Off-shoulder tops', 'Statement bottoms', 'Empire waist dresses', 'Racerback tops'
        ],
        'dont': [
          'Puff sleeves', 'Boat neck', 'Shoulder pads', 'Skinny pants',
          'Straight skirts', 'Light colored tops', 'Horizontal stripes', 'Cap sleeves',
          'Halter tops', 'Crop tops', 'Tight skirts', 'Bandeau tops'
        ],
      },
      BodyShape.apple: {
        'do': [
          'Empire waist tops', 'Dark jeans', 'V-neck shirts', 'Long cardigans',
          'A-line dresses', 'Dark colored bottoms', 'Flowy tops', 'Straight leg pants',
          'Wrap tops', 'Open cardigans', 'Flared bottoms', 'Tunic tops'
        ],
        'dont': [
          'Crop tops', 'Belted waist', 'Horizontal stripes', 'Tight fabrics',
          'Low-rise pants', 'Bodycon dresses', 'Stiff materials', 'High necklines',
          'Pleated waist', 'Skinny jeans', 'Ruffled tops', 'Button-up shirts'
        ],
      },
    };

    final shapeRecs = allRecommendations[shape] ?? allRecommendations[BodyShape.hourglass]!;
    final recs = isDo ? shapeRecs['do']! : shapeRecs['dont']!;

    final shuffled = List<String>.from(recs)..shuffle();
    return shuffled.take(4).toList();
  }

  String _getRandomStyleTip(BodyShape shape) {
    final Map<BodyShape, List<String>> tips = {
      BodyShape.pear: [
        'Balance your silhouette by drawing attention to your upper body',
        'Choose dark bottoms and bright tops for perfect proportion',
        'A-line and flared styles are your best friends',
        'Create drama with statement jewelry on your neckline',
        'Darker shades on bottom create a slimming effect'
      ],
      BodyShape.hourglass: [
        'Emphasize your defined waist with belts and cinched styles',
        'Wrap dresses are made for your figure - wear them proudly',
        'Highlight your curves with fitted, structured pieces',
        'Deep V-necks show off your balanced proportions beautifully',
        'Pencil skirts and fitted blazers are your power combo'
      ],
      BodyShape.rectangle: [
        'Create the illusion of curves with peplum and ruffles',
        'Define your waist with belts and strategic cinching',
        'Layer your outfits to add dimension and shape',
        'Color blocking can create curves instantly',
        'Structured shoulders and full skirts build feminine shape'
      ],
      BodyShape.invertedTriangle: [
        'Balance your broad shoulders by adding volume to hips',
        'Dark colors on top, light colors on bottom creates balance',
        'A-line and flared bottoms are your wardrobe essentials',
        'V-necks and scoop necks soften your shoulder line',
        'Create a hourglass illusion with fitted waist styles'
      ],
      BodyShape.apple: [
        'Create vertical lines with V-necks and long cardigans',
        'Empire waist styles flow beautifully over your silhouette',
        'Dark, solid colors create a streamlined look',
        'Draw attention to your legs with flared or straight pants',
        'Open necklines and flowing fabrics are your perfect match'
      ],
    };

    final shapeTips = tips[shape] ?? tips[BodyShape.hourglass]!;
    final randomIndex = DateTime.now().millisecondsSinceEpoch % shapeTips.length;
    return shapeTips[randomIndex.toInt()];
  }

  void _saveToHistory(BuildContext context) async {
    try {
      // Create a unique ID
      final String id = DateTime.now().millisecondsSinceEpoch.toString();

      // Save image to app's local storage
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'scan_$id.jpg';
      final String localPath = path.join(appDir.path, fileName);

      // Copy the image to app's local directory
      await widget.imageFile.copy(localPath);

      // Generate unique recommendations for this scan
      final randomDoRecs = _generateRandomRecommendations(widget.bodyShape, isDo: true);
      final randomDontRecs = _generateRandomRecommendations(widget.bodyShape, isDo: false);
      final styleTip = _getRandomStyleTip(widget.bodyShape);
      final confidenceScore = '${(widget.confidence * 100).toStringAsFixed(0)}%';

      // Create history entry
      final entry = HistoryEntry(
        id: id,
        bodyShape: widget.bodyShape.displayName,
        shoulderHipRatio: widget.shoulderHipRatio,
        imagePath: localPath,
        thumbnailPath: localPath,
        doRecommendations: randomDoRecs,
        dontRecommendations: randomDontRecs,
        timestamp: DateTime.now(),
        styleTip: styleTip,
        confidenceScore: confidenceScore,
      );

      // Save to history
      final historyService = HistoryService();
      await historyService.saveEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${widget.bodyShape.displayName} saved to history!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
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
      }
    } catch (e) {
      print('Error saving to history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}