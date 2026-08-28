import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class PollinationsService {
  static const String _baseUrl = 'https://image.pollinations.ai/prompt';
  final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult =
      await _connectivity.checkConnectivity();

      return connectivityResult.any(
            (result) => result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile,
      );
    } catch (e) {
      return false;
    }
  }

  /// Generate a single image and return base64 encoded image
  Future<String> generateImage({
    required String prompt,
    int width = 512,
    int height = 512,
    String model = 'flux',
  }) async {
    // Check internet connection first
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      throw Exception('NO_INTERNET');
    }

    try {
      final encodedPrompt = Uri.encodeComponent(prompt);
      // Use a smaller seed value (max 2147483647)
      final seed = DateTime.now().millisecondsSinceEpoch % 2147483647;
      final url = '$_baseUrl/$encodedPrompt'
          '?width=$width&height=$height'
          '&model=$model'
          '&nologo=true'
          '&seed=$seed';

      print('Generating clothing image...');
      print('URL: $url');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('image') || response.bodyBytes.isNotEmpty) {
          try {
            final base64Image = base64Encode(response.bodyBytes);
            print('Image generated successfully! Size: ${response.bodyBytes.length} bytes');
            return 'data:image/png;base64,$base64Image';
          } catch (e) {
            print('Error: Response is not a valid image: $e');
            final responseText = utf8.decode(response.bodyBytes);
            print('Response text: $responseText');

            if (responseText.contains('error') || responseText.contains('Error')) {
              throw Exception('API Error: $responseText');
            }
            throw Exception('Invalid image response from server');
          }
        } else {
          final responseText = utf8.decode(response.bodyBytes);
          print('Unexpected response: $responseText');
          throw Exception('Server returned unexpected response');
        }
      } else {
        final errorText = utf8.decode(response.bodyBytes);
        print('Error response: $errorText');
        throw Exception('Failed to generate image: ${response.statusCode} - $errorText');
      }
    } catch (e) {
      print('Error generating image: $e');
      rethrow;
    }
  }

  /// Generate multiple images and return base64 encoded images
  Future<List<String>> generateMultipleImages({
    required List<String> prompts,
    int width = 512,
    int height = 512,
  }) async {
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      throw Exception('NO_INTERNET');
    }

    List<String> results = [];

    for (int i = 0; i < prompts.length; i++) {
      try {
        final imageUrl = await generateImage(
          prompt: prompts[i],
          width: width,
          height: height,
        );
        results.add(imageUrl);
        print('Generated image ${i + 1}/${prompts.length}');
      } catch (e) {
        print('Failed to generate image ${i + 1}: $e');
        results.add('');
      }
    }

    return results;
  }
}