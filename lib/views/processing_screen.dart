import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tflite_service.dart';
import '../services/recommendation_service.dart';
import '../models/body_shape.dart';
import 'result_screen.dart';

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

  @override
  void initState() {
    super.initState();
    print('🟢 ProcessingScreen loaded - starting processing');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processImage();
    });
  }

  Future<void> _processImage() async {
    if (_isProcessing) return;
    _isProcessing = true;

    print('🟡 Starting image processing with custom CNN model...');

    try {
      // Step 1: Load the TFLite model
      if (mounted) {
        setState(() {
          _statusMessage = "Loading AI model...";
        });
      }

      await _tfliteService.loadModel();
      print('✅ Step 1: Custom CNN model loaded successfully');

      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Check if image exists
      if (widget.imageFile == null) {
        print('⚠️ No image file provided');
        if (mounted) {
          _showError('No image selected. Please try again.');
        }
        return;
      }

      // Step 3: Get consistent prediction (3 tries)
      if (mounted) {
        setState(() {
          _statusMessage = "Analyzing your body shape (3 attempts)...";
        });
      }

      final predictedLabel = await _tfliteService.getConsistentPrediction(
        widget.imageFile!,
        attempts: 3,
      );
      print('✅ Step 2: Consistent prediction: $predictedLabel');

      // Get confidence
      final confidence = _tfliteService.lastConfidence ?? 0.0;
      _confidenceMessage = 'Confidence: ${(confidence * 100).toStringAsFixed(1)}%';

      // Step 4: Map string to BodyShape enum
      final bodyShape = _mapToBodyShape(predictedLabel);

      // Step 5: Get recommendations
      if (mounted) {
        setState(() {
          _statusMessage = "Getting style recommendations...";
        });
      }

      final doRecs = _recService.getDoRecommendations(bodyShape, 'Casual');
      final dontRecs = _recService.getDontRecommendations(bodyShape, 'Casual');
      final occasions = _recService.getOccasions();

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _statusMessage = "Analysis Complete!";
          _isComplete = true;
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Step 6: Navigate to result screen
      if (mounted) {
        print('🔵 Navigating to ResultScreen with shape: ${bodyShape.displayName}');
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
      print('❌ Processing error: $e');
      if (mounted) {
        _showError('Analysis failed: $e\n\nPlease try again with a better photo.');
      }
    } finally {
      _tfliteService.dispose();
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
        print('⚠️ Unknown label: $label, defaulting to Rectangle');
        return BodyShape.rectangle;
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
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