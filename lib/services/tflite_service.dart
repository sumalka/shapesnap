import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteService {
  Interpreter? _interpreter;
  List<String>? _labels;
  double? _lastConfidence;

  double? get lastConfidence => _lastConfidence;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model/shapesnap_model.tflite');

      final labelString = await _loadLabels();
      _labels = labelString.split('\n').where((l) => l.isNotEmpty).toList();

      print('Model loaded successfully!');
      print('Labels: $_labels');
    } catch (e) {
      print('Error loading model: $e');
      throw Exception('Failed to load model: $e');
    }
  }

  Future<String> classifyImage(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }
    // 1. Load and preprocess image
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }
    // VGG16 uses 224x224 input
    final resized = img.copyResize(image, width: 224, height: 224);
    // For float model: use float input (normalized 0-1)
    final input = _imageToFloatList(resized, 224, 224);
    // 2. Run inference
    final output = List.filled(1 * 5, 0.0).reshape([1, 5]);
    _interpreter!.run(input, output);
    // 3. Get prediction
    final predictions = output[0] as List<double>;
    final maxIndex = predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));
    final confidence = predictions[maxIndex];
    _lastConfidence = confidence;

    print('Predictions: $predictions');
    print('Predicted class: ${_labels![maxIndex]} with confidence: ${(confidence * 100).toStringAsFixed(1)}%');

    // Only return result if confidence is above 50%
    if (confidence < 0.50) {
      throw Exception('Confidence too low (${(confidence * 100).toStringAsFixed(1)}%). Please take a better photo.');
    }
    return _labels![maxIndex];
  }

  // For consistent prediction - takes 3 tries and returns the most common
  Future<String> getConsistentPrediction(File imageFile, {int attempts = 3}) async {
    List<String> results = [];
    List<double> confidences = [];

    for (int i = 0; i < attempts; i++) {
      try {
        final result = await classifyImage(imageFile);
        results.add(result);
        confidences.add(_lastConfidence ?? 0.0);
        print('Attempt ${i+1}: $result (${((_lastConfidence ?? 0) * 100).toStringAsFixed(1)}%)');
      } catch (e) {
        print('Attempt ${i+1} failed: $e');
      }
    }

    if (results.isEmpty) {
      throw Exception('Could not get a consistent prediction');
    }
    // Find the most common prediction
    var counts = <String, int>{};
    for (var item in results) {
      counts[item] = (counts[item] ?? 0) + 1;
    }
    // Get the most frequent prediction
    String bestResult = counts.keys.firstWhere(
          (k) => counts[k] == counts.values.reduce((a, b) => a > b ? a : b),
    );

    int maxCount = counts[bestResult] ?? 0;
    // If no clear majority (1,1,1), use the one with highest confidence
    if (maxCount == 1) {
      print('No clear majority, using highest confidence result');
      int bestIndex = confidences.indexOf(confidences.reduce((a, b) => a > b ? a : b));
      return results[bestIndex];
    }

    print('Consistent prediction: $bestResult ($maxCount/$attempts attempts)');
    return bestResult;
  }

  List<List<List<List<double>>>> _imageToFloatList(img.Image image, int width, int height) {
    final input = List.generate(
      1,
          (_) => List.generate(
        height,
            (y) => List.generate(
          width,
              (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    return input;
  }

  Future<String> _loadLabels() async {
    return await rootBundle.loadString('assets/model/labels.txt');
  }

  void dispose() {
    _interpreter?.close();
  }
}