import 'dart:convert';
import 'package:http/http.dart' as http;

class PollinationsService {
  static const String _baseUrl = 'https://image.pollinations.ai/prompt';

  /// Generate a single image and return base64 encoded image
  Future<String> generateImage({
    required String prompt,
    int width = 512,
    int height = 512,
    String model = 'flux',
  }) async {
    try {
      final encodedPrompt = Uri.encodeComponent(prompt);
      // Add seed for variety and strict no-human prompt
      final seed = DateTime.now().millisecondsSinceEpoch;
      final url = '$_baseUrl/$encodedPrompt'
          '?width=$width&height=$height'
          '&model=$model'
          '&nologo=true'
          '&seed=$seed';

      print('🎨 Generating clothing image...');
      print('📝 Prompt: $prompt');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final base64Image = base64Encode(response.bodyBytes);
        return 'data:image/png;base64,$base64Image';
      } else {
        throw Exception('Failed to generate image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error generating image: $e');
      throw Exception('Failed to generate image: $e');
    }
  }

  /// Generate multiple images and return base64 encoded images
  Future<List<String>> generateMultipleImages({
    required List<String> prompts,
    int width = 512,
    int height = 512,
  }) async {
    List<String> results = [];

    for (int i = 0; i < prompts.length; i++) {
      try {
        final imageUrl = await generateImage(
          prompt: prompts[i],
          width: width,
          height: height,
        );
        results.add(imageUrl);
        print('✅ Generated image ${i + 1}/${prompts.length}');
      } catch (e) {
        print('❌ Failed to generate image ${i + 1}: $e');
        results.add('');
      }
    }

    return results;
  }
}