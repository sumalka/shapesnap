import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/body_shape.dart';
import '../services/occasion_image_service.dart';
import '../services/pollinations_service.dart';
import '../widgets/bottom_nav_bar.dart';

class OccasionScreen extends StatefulWidget {
  const OccasionScreen({super.key});

  @override
  State<OccasionScreen> createState() => _OccasionScreenState();
}

class _OccasionScreenState extends State<OccasionScreen> {
  BodyShape _selectedBodyShape = BodyShape.hourglass;
  int _hoveredIndex = -1;
  final PollinationsService _pollinationsService = PollinationsService();
  final Connectivity _connectivity = Connectivity();

  // Track generated images for each occasion + body shape combination
  Map<String, List<String>> _generatedImages = {};
  Map<String, bool> _isGenerating = {};
  Map<String, List<String>> _imageNames = {};

  // Body shape data
  final List<Map<String, dynamic>> _bodyShapeData = [
    {
      'shape': BodyShape.hourglass,
      'icon': Icons.hourglass_bottom,
      'color': Colors.pink,
      'label': 'Hourglass',
      'description': 'Balanced shoulders & hips',
    },
    {
      'shape': BodyShape.pear,
      'icon': Icons.water_drop,
      'color': Colors.pink,
      'label': 'Pear',
      'description': 'Hips wider than shoulders',
    },
    {
      'shape': BodyShape.rectangle,
      'icon': Icons.crop_square,
      'color': Colors.pink,
      'label': 'Rectangle',
      'description': 'Balanced proportions',
    },
    {
      'shape': BodyShape.invertedTriangle,
      'icon': Icons.change_history,
      'color': Colors.pink,
      'label': 'Inverted',
      'description': 'Shoulders wider than hips',
    },
    {
      'shape': BodyShape.apple,
      'icon': Icons.circle,
      'color': Colors.pink,
      'label': 'Apple',
      'description': 'Waist wider than shoulders',
    },
  ];

  // All occasions
  final List<Map<String, dynamic>> occasions = [
    {
      'name': 'Casual',
      'icon': Icons.style_outlined,
      'color': Colors.pink,
      'description': 'Everyday comfort style',
    },
    {
      'name': 'Party',
      'icon': Icons.celebration_outlined,
      'color': Colors.pink,
      'description': 'Night out and celebrations',
    },
    {
      'name': 'Office',
      'icon': Icons.work_outline,
      'color': Colors.pink,
      'description': 'Professional work attire',
    },
    {
      'name': 'Wedding',
      'icon': Icons.auto_awesome,
      'color': Colors.pink,
      'description': 'Special day elegance',
    },
    {
      'name': 'Gym',
      'icon': Icons.fitness_center,
      'color': Colors.pink,
      'description': 'Active workout wear',
    },
  ];

  // Women's clothing names
  final Map<String, List<String>> _clothingNames = {
    'Casual': ['Denim Jeans', 'Casual Dress', 'Knit Sweater', 'T-Shirt', 'Jumpsuit', 'Denim Jacket', 'Skirt', 'Cardigan'],
    'Party': ['Cocktail Dress', 'Sequin Dress', 'Mini Dress', 'Party Jumpsuit', 'Evening Gown', 'Bodycon Dress', 'Satin Dress', 'Sequined Top'],
    'Office': ['Blazer Set', 'Pencil Skirt', 'Business Suit', 'Shift Dress', 'Power Suit', 'Silk Blouse', 'Tailored Trousers', 'Blazer Dress'],
    'Wedding': ['Wedding Guest Dress', 'Evening Gown', 'Floral Dress', 'Formal Jumpsuit', 'Silk Dress', 'Lace Dress', 'Chiffon Gown', 'Satin Gown'],
    'Gym': ['Activewear Set', 'High-Waist Leggings', 'Sports Bra', 'Workout Gear', 'Yoga Wear', 'Sporty Outfit', 'Tank Top', 'Athletic Shorts'],
  };

  // STRICT CLOTHING-ONLY prompts - shortened versions
  final List<String> _strictPrompts = [
    'clothing item on white background, flat lay, product photography, fashion e-commerce, 4k',
    'fashion garment on white surface, product photography, clean white background, fashion catalog',
    'piece of clothing on white background, flat lay, product photography, fashion e-commerce',
    'fashion item on white background, product shot, clothing photography, 4k, clean background',
    'garment flat lay on white, product photography, fashion photography, 4k',
    'clothing item on white background, flat lay, professional product photography, fashion e-commerce, 4k',
  ];

  // Helper method to get unique key for occasion + body shape
  String _getStorageKey(String occasion, BodyShape bodyShape) {
    return '${occasion}_${bodyShape.toString().split('.').last}';
  }

  // ============================================
  // SHOW OFFLINE DIALOG
  // ============================================
  void _showOfflineDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade300, Colors.pink.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wifi_off,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Internet Connection',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2A4F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To generate AI outfit images, please connect to Wi-Fi or mobile data and try again.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.pink.shade200),
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
                        'Check your Wi-Fi settings or mobile data, then tap Retry.',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6186A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shadowColor: Colors.pink.withOpacity(0.3),
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER - Big Logo with spacing from corners
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
                  // "Occasions" text with margin from right corner
                  Positioned(
                    right: 15,
                    top: 20,
                    child: Text(
                      'Occasions',
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

            // Body Shape Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Choose Your Body Shape',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A2A4F),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _buildShapeButton(
                                shape: _bodyShapeData[0]['shape'] as BodyShape,
                                isSelected: _selectedBodyShape == _bodyShapeData[0]['shape'],
                                color: _bodyShapeData[0]['color'] as Color,
                                icon: _bodyShapeData[0]['icon'] as IconData,
                                label: _bodyShapeData[0]['label'] as String,
                                description: _bodyShapeData[0]['description'] as String,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildShapeButton(
                                shape: _bodyShapeData[1]['shape'] as BodyShape,
                                isSelected: _selectedBodyShape == _bodyShapeData[1]['shape'],
                                color: _bodyShapeData[1]['color'] as Color,
                                icon: _bodyShapeData[1]['icon'] as IconData,
                                label: _bodyShapeData[1]['label'] as String,
                                description: _bodyShapeData[1]['description'] as String,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildShapeButton(
                                shape: _bodyShapeData[2]['shape'] as BodyShape,
                                isSelected: _selectedBodyShape == _bodyShapeData[2]['shape'],
                                color: _bodyShapeData[2]['color'] as Color,
                                icon: _bodyShapeData[2]['icon'] as IconData,
                                label: _bodyShapeData[2]['label'] as String,
                                description: _bodyShapeData[2]['description'] as String,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(),
                            ),
                            Expanded(
                              flex: 2,
                              child: _buildShapeButton(
                                shape: _bodyShapeData[3]['shape'] as BodyShape,
                                isSelected: _selectedBodyShape == _bodyShapeData[3]['shape'],
                                color: _bodyShapeData[3]['color'] as Color,
                                icon: _bodyShapeData[3]['icon'] as IconData,
                                label: _bodyShapeData[3]['label'] as String,
                                description: _bodyShapeData[3]['description'] as String,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildShapeButton(
                                shape: _bodyShapeData[4]['shape'] as BodyShape,
                                isSelected: _selectedBodyShape == _bodyShapeData[4]['shape'],
                                color: _bodyShapeData[4]['color'] as Color,
                                icon: _bodyShapeData[4]['icon'] as IconData,
                                label: _bodyShapeData[4]['label'] as String,
                                description: _bodyShapeData[4]['description'] as String,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Selected Shape Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.pink.shade400,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Showing recommendations for ${_getDisplayName(_selectedBodyShape)} body shape',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.pink.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Occasion Cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: occasions.length,
                itemBuilder: (context, index) {
                  final occasion = occasions[index];
                  final name = occasion['name']?.toString() ?? 'Unknown';
                  final icon = occasion['icon'] as IconData? ?? Icons.event_note;
                  final description = occasion['description']?.toString() ?? '';
                  final isHovered = _hoveredIndex == index;
                  final storageKey = _getStorageKey(name, _selectedBodyShape);
                  final generatedImages = _generatedImages[storageKey] ?? [];

                  return MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _hoveredIndex = index;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _hoveredIndex = -1;
                      });
                    },
                    child: GestureDetector(
                      onTap: () {
                        _showOccasionDetails(context, name);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(bottom: 12),
                        transform: _getTransform(isHovered),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isHovered
                                ? [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.25),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.1),
                                blurRadius: 40,
                                spreadRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                                : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: isHovered ? Colors.pink : Colors.grey.shade100,
                              width: isHovered ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isHovered
                                      ? Colors.pink.withOpacity(0.2)
                                      : Colors.pink.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  icon,
                                  color: isHovered ? Colors.pink : Colors.pink,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.inter(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: isHovered ? Colors.pink : const Color(0xFF1A2A4F),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.pink.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'AI',
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.pink.shade700,
                                            ),
                                          ),
                                        ),
                                        if (generatedImages.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${generatedImages.length}',
                                              style: GoogleFonts.inter(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      description,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isHovered ? Colors.pink.shade700 : Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isHovered ? Colors.pink.shade100 : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: isHovered ? Colors.pink : Colors.grey.shade400,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Matrix4 _getTransform(bool isHovered) {
    if (isHovered) {
      return Matrix4.identity()
        ..translate(0.0, -8.0)
        ..scale(1.02);
    } else {
      return Matrix4.identity();
    }
  }

  String _getDisplayName(BodyShape shape) {
    if (shape == BodyShape.apple) {
      return 'Apple';
    }
    return shape.displayName;
  }

  Widget _buildShapeButton({
    required BodyShape shape,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required String label,
    required String description,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBodyShape = shape;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF1A2A4F),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 8,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SHOW OCCASION DETAILS
  // ============================================
  void _showOccasionDetails(BuildContext context, String occasion) {
    final imageService = OccasionImageService();
    final images = imageService.getOccasionImages(_selectedBodyShape, occasion);
    final doRecs = imageService.getDoRecommendations(_selectedBodyShape, occasion);

    final displayImages = images.take(10).toList();
    final storageKey = _getStorageKey(occasion, _selectedBodyShape);

    // Initialize if not exists
    if (!_generatedImages.containsKey(storageKey)) {
      _generatedImages[storageKey] = [];
      _imageNames[storageKey] = [];
    }
    _isGenerating[storageKey] = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                final storageKeyLocal = _getStorageKey(occasion, _selectedBodyShape);
                final generatedImages = _generatedImages[storageKeyLocal] ?? [];
                final imageNames = _imageNames[storageKeyLocal] ?? [];
                final isGenerating = _isGenerating[storageKeyLocal] ?? false;

                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            _getOccasionIcon(occasion),
                            color: Colors.pink,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$occasion Wear',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A2A4F),
                                  ),
                                ),
                                Text(
                                  'For ${_getDisplayName(_selectedBodyShape)} body shape',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.pink.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: isGenerating ? null : () {
                              _generateSingleAIImage(context, occasion, setState, scrollController);
                            },
                            icon: isGenerating
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Icon(Icons.auto_awesome, size: 16),
                            label: Text(
                              isGenerating ? 'Generating...' : 'Generate AI',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isGenerating ? Colors.grey : Colors.pink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${displayImages.length} recommended styles',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // IMAGES SECTION
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.pink.shade400,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recommended Styles',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.pink.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: displayImages.length,
                                itemBuilder: (context, index) {
                                  final imagePath = displayImages[index];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          color: Colors.white,
                                          child: Image.asset(
                                            imagePath,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade50,
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey.shade400,
                                                      size: 40,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Style ${index + 1}',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Style ${index + 1}',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // AI GENERATED IMAGES SECTION
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: Colors.pink.shade400,
                                      size: 20,
                                    ),
                                    Text(
                                      'AI-Generated Clothing',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.pink.shade700,
                                      ),
                                    ),
                                    if (generatedImages.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.pink.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${generatedImages.length}',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.pink.shade700,
                                          ),
                                        ),
                                      ),
                                    if (isGenerating)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Generating...',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              if (isGenerating)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 30),
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: CircularProgressIndicator(
                                          color: Colors.pink,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Generating your clothing image...',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'This may take 15-30 seconds',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (generatedImages.isNotEmpty)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.7,
                                  ),
                                  itemCount: generatedImages.length,
                                  itemBuilder: (context, index) {
                                    final imageUrl = generatedImages[index];
                                    final clothingName = imageNames.length > index ? imageNames[index] : 'Style ${index + 1}';

                                    return GestureDetector(
                                      onTap: () {
                                        _showFullScreenImage(context, imageUrl, occasion, clothingName);
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              color: Colors.white,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Stack(
                                                  children: [
                                                    Image.memory(
                                                      base64Decode(imageUrl.split(',').last),
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: Colors.white,
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(
                                                                Icons.image_not_supported,
                                                                color: Colors.grey.shade400,
                                                                size: 40,
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                'Failed to load',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.grey.shade600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: Colors.pink.withOpacity(0.85),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          'AI',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            clothingName,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.pink.shade700,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 16),

                              // STYLE TIPS
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.pink.shade50,
                                      Colors.pink.shade100.withOpacity(0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.pink.shade200,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pink.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.pink.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.style,
                                            color: Colors.pink.shade700,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Style Tips',
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.pink.shade800,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.pink.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${doRecs.length} tips',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.pink.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ...doRecs.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(top: 2),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.pink.shade400,
                                                    Colors.pink.shade600,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${index + 1}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
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
                                                  color: Colors.grey.shade800,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    const SizedBox(height: 8),
                                    Divider(
                                      color: Colors.pink.shade200,
                                      thickness: 1,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_outline,
                                          color: Colors.pink.shade400,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Style tips tailored for your body shape',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================
  // FULL SCREEN IMAGE VIEWER
  // ============================================
  void _showFullScreenImage(BuildContext context, String imageUrl, String occasion, String clothingName) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.memory(
                        base64Decode(imageUrl.split(',').last),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey.shade400,
                                  size: 60,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            clothingName,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A2A4F),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$occasion Wear',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.pink.shade600,
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
                              'AI-Generated',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.pink.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // ============================================
  // GENERATE SINGLE AI IMAGE
  // ============================================
  void _generateSingleAIImage(
      BuildContext context,
      String occasion,
      StateSetter setState,
      ScrollController scrollController
      ) async {

    // Check internet connection
    final bool hasConnection = await _pollinationsService.hasInternetConnection();

    if (!hasConnection) {
      _showOfflineDialog(context);
      return;
    }

    final storageKey = _getStorageKey(occasion, _selectedBodyShape);

    setState(() {
      _isGenerating[storageKey] = true;
    });

    // Scroll to bottom to show progress
    Future.delayed(const Duration(milliseconds: 150), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
        );
      }
    });

    final clothingName = _getRandomClothingName(occasion);
    final prompt = _generateStrictPrompt(occasion, clothingName, _selectedBodyShape);

    await _generateAndAddImage(context, occasion, storageKey, prompt, clothingName, setState, scrollController);
  }

  String _getRandomClothingName(String occasion) {
    final names = _clothingNames[occasion] ?? ['Stylish Outfit'];
    final randomIndex = DateTime.now().millisecondsSinceEpoch % names.length;
    return names[randomIndex];
  }

  String _generateStrictPrompt(String occasion, String clothingName, BodyShape bodyShape) {
    final randomIndex = DateTime.now().millisecondsSinceEpoch % _strictPrompts.length;
    final basePrompt = _strictPrompts[randomIndex];

    final styles = ['chic', 'elegant', 'trendy', 'classic', 'modern', 'stylish'];
    final colors = ['neutral', 'pastel', 'bold', 'monochrome', 'earth tone'];
    final fabrics = ['cotton', 'silk', 'linen', 'wool', 'denim'];

    final style = styles[DateTime.now().millisecondsSinceEpoch % styles.length];
    final color = colors[DateTime.now().millisecondsSinceEpoch % colors.length];
    final fabric = fabrics[DateTime.now().millisecondsSinceEpoch % fabrics.length];

    final shapeName = _getDisplayName(bodyShape);

    return '$style $color $fabric $clothingName for $shapeName body shape, $basePrompt';
  }

  Future<void> _generateAndAddImage(
      BuildContext context,
      String occasion,
      String storageKey,
      String prompt,
      String clothingName,
      StateSetter setState,
      ScrollController scrollController
      ) async {
    try {
      final imageUrl = await _pollinationsService.generateImage(
        prompt: prompt,
        width: 512,
        height: 512,
      );

      if (imageUrl.isNotEmpty) {
        setState(() {
          if (!_generatedImages.containsKey(storageKey)) {
            _generatedImages[storageKey] = [];
            _imageNames[storageKey] = [];
          }
          _generatedImages[storageKey]!.add(imageUrl);
          _imageNames[storageKey]!.add(clothingName);
          _isGenerating[storageKey] = false;
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$clothingName generated!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isGenerating[storageKey] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final errorMsg = e.toString();

      // Check if it's a no internet error
      if (errorMsg.contains('NO_INTERNET')) {
        setState(() {
          _isGenerating[storageKey] = false;
        });
        _showOfflineDialog(context);
        return;
      }

      setState(() {
        _isGenerating[storageKey] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${errorMsg.replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  IconData _getOccasionIcon(String occasion) {
    switch (occasion) {
      case 'Casual':
        return Icons.style_outlined;
      case 'Party':
        return Icons.celebration_outlined;
      case 'Office':
        return Icons.work_outline;
      case 'Wedding':
        return Icons.auto_awesome;
      case 'Gym':
        return Icons.fitness_center;
      default:
        return Icons.event_note;
    }
  }
}