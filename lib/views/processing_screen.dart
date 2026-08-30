import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tflite_service.dart';
import '../services/recommendation_service.dart';
import '../models/body_shape.dart';
import 'result_screen.dart';
import 'camera_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final File? imageFile;

  const ProcessingScreen({super.key, this.imageFile});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final TfliteService _tfliteService = TfliteService();
  final RecommendationService _recService = RecommendationService();

  String _statusMessage = "Loading AI model...";
  bool _isProcessing = false;
  bool _isComplete = false;
  String _confidenceMessage = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    print('ProcessingScreen loaded - starting processing');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processImage();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      _tfliteService.dispose();
    } catch (e) {
      print('Error during dispose: $e');
    }
    super.dispose();
  }

  Future<void> _processImage() async {
    if (_isProcessing || _isDisposed) return;
    _isProcessing = true;

    print('Starting image processing with custom CNN model...');

    try {
      // Step 1: Load the TFLite model
      if (mounted && !_isDisposed) {
        setState(() {
          _statusMessage = "Loading AI model...";
        });
      }

      await _tfliteService.loadModel();
      print('Step 1: Custom CNN model loaded successfully');

      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Check if image exists
      if (widget.imageFile == null) {
        print('No image file provided');
        if (mounted && !_isDisposed) {
          _showError('No image selected. Please try again.');
        }
        return;
      }

      // Step 3: Get consistent prediction (3 tries)
      if (mounted && !_isDisposed) {
        setState(() {
          _statusMessage = "Analyzing your body shape (3 attempts)...";
        });
      }

      final predictedLabel = await _tfliteService.getConsistentPrediction(
        widget.imageFile!,
        attempts: 3,
      );
      print('Step 2: Consistent prediction: $predictedLabel');

      // Get confidence
      final confidence = _tfliteService.lastConfidence ?? 0.0;
      _confidenceMessage = 'Confidence: ${(confidence * 100).toStringAsFixed(1)}%';

      // Step 4: Map string to BodyShape enum
      final bodyShape = _mapToBodyShape(predictedLabel);

      // Step 5: Get recommendations
      if (mounted && !_isDisposed) {
        setState(() {
          _statusMessage = "Getting style recommendations...";
        });
      }

      final doRecs = _recService.getDoRecommendations(bodyShape, 'Casual');
      final dontRecs = _recService.getDontRecommendations(bodyShape, 'Casual');
      final occasions = _recService.getOccasions();

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && !_isDisposed) {
        setState(() {
          _statusMessage = "Analysis Complete!";
          _isComplete = true;
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Step 6: Navigate to result screen
      if (mounted && !_isDisposed) {
        print('🔵 Navigating to ResultScreen with shape: ${bodyShape.displayName}');

        try {
          _tfliteService.dispose();
        } catch (e) {
          print('Error disposing service: $e');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              imageFile: widget.imageFile!,
              bodyShape: bodyShape,
              shoulderHipRatio: 0.0,
              shoulderWidth: 0.0,
              hipWidth: 0.0,
              doRecommendations: doRecs,
              dontRecommendations: dontRecs,
              occasions: occasions,
              confidence: confidence,
            ),
          ),
        );
      }

    } catch (e) {
      print('Processing error: $e');
      if (mounted && !_isDisposed) {
        _showError('Could not detect your body shape. Please try again with a better photo.');
      }
    } finally {
      _isProcessing = false;
    }
  }

  BodyShape _mapToBodyShape(String label) {
    switch (label.toLowerCase().trim()) {
      case 'apple':
        return BodyShape.apple;
      case 'hourglass':
        return BodyShape.hourglass;
      case 'inverted_triangle':
        return BodyShape.invertedTriangle;
      case 'pear':
        return BodyShape.pear;
      case 'rectangle':
        return BodyShape.rectangle;
      default:
        print('Unknown label: $label, defaulting to Rectangle');
        return BodyShape.rectangle;
    }
  }


  // iOS-STYLE ERROR DIALOG - NO ICON

  void _showError(String message) {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: Text(
          'Analysis Failed',
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
              'Could not detect your body shape.\nPlease try again with a better photo.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            // Tips section
            Text(
              'Tips for better results:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2A4F),
              ),
            ),
            const SizedBox(height: 10),
            _buildTipItem('Stand facing the camera directly'),
            _buildTipItem('Wear fitted clothing'),
            _buildTipItem('Ensure good lighting'),
            _buildTipItem('Keep a neutral posture'),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                try {
                  _tfliteService.dispose();
                } catch (e) {
                  print('Error disposing service: $e');
                }
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const CameraScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE6186A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.pink.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isComplete)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            if (_isComplete)
              const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green,
              ),
            const SizedBox(height: 32),
            Text(
              _statusMessage,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: _isComplete ? Colors.green.shade700 : Colors.grey.shade700,
                fontWeight: _isComplete ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isComplete) ...[
              const SizedBox(height: 8),
              Text(
                _confidenceMessage,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              _isComplete ? 'Loading your results...' : 'This may take a few seconds',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}