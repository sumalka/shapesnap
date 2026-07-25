import '../models/body_shape.dart';

class ImageRecommendationService {
  // Get DO images for a specific body shape
  List<String> getDoImages(
      BodyShape shape, {
        String occasion = 'casual',
        int maxImages = 3,
      }) {
    String shapeFolder = _getShapeFolderName(shape);
    String basePath = 'assets/recommendations/do/$shapeFolder/';

    // All shapes now use 1.png, 2.png, 3.png
    return _getImagePaths(basePath, maxImages);
  }

  // Get DON'T images for a specific body shape
  List<String> getDontImages(
      BodyShape shape, {
        String occasion = 'casual',
        int maxImages = 3,
      }) {
    String shapeFolder = _getShapeFolderName(shape);
    String basePath = 'assets/recommendations/dont/$shapeFolder/';

    // All shapes now use 1.png, 2.png, 3.png
    return _getImagePaths(basePath, maxImages);
  }

  List<String> getOccasions() {
    return ['Casual', 'Party', 'Office', 'Wedding', 'Gym'];
  }

  String getOccasionDisplayName(String occasion) {
    return occasion;
  }

  List<String> _getImagePaths(String basePath, int maxImages) {
    List<String> paths = [];
    for (int i = 1; i <= maxImages; i++) {
      paths.add('$basePath$i.png');
    }
    return paths;
  }

  String _getShapeFolderName(BodyShape shape) {
    switch (shape) {
      case BodyShape.pear:
        return 'pear';
      case BodyShape.hourglass:
        return 'hourglass';
      case BodyShape.rectangle:
        return 'rectangle';
      case BodyShape.invertedTriangle:
        return 'inverted_triangle';
      case BodyShape.apple:
        return 'apple';
    }
  }
}