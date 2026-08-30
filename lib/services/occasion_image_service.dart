import '../models/body_shape.dart';

class OccasionImageService {
  // Get occasion images for any occasion
  List<String> getOccasionImages(BodyShape shape, String occasion) {
    String shapeName = _getShapeFolderName(shape);
    String occasionName = _getOccasionFolderName(occasion);
    List<String> imageNames = _getImageNames();

    return imageNames.map((filename) {
      return 'assets/recommendations/$occasionName/$shapeName/$filename';
    }).toList();
  }

  // Get DO recommendations for any occasion
  List<String> getDoRecommendations(BodyShape shape, String occasion) {
    switch (shape) {
      case BodyShape.hourglass:
        return _getHourglassRecommendations(occasion);
      case BodyShape.pear:
        return _getPearRecommendations(occasion);
      case BodyShape.rectangle:
        return _getRectangleRecommendations(occasion);
      case BodyShape.invertedTriangle:
        return _getInvertedTriangleRecommendations(occasion);
      case BodyShape.apple:
        return _getAppleRecommendations(occasion);
    }
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

  String _getOccasionFolderName(String occasion) {
    switch (occasion) {
      case 'Casual':
        return 'casual';
      case 'Party':
        return 'party';
      case 'Office':
        return 'office';
      case 'Wedding':
        return 'wedding';
      case 'Gym':
        return 'gym';
      default:
        return 'casual';
    }
  }

  // All images are PNG now
  List<String> _getImageNames() {
    return [
      '1.png', '2.png', '3.png', '4.png', '5.png',
      '6.png', '7.png', '8.png', '9.png', '10.png'
    ];
  }


  // HOURGLASS RECOMMENDATIONS

  List<String> _getHourglassRecommendations(String occasion) {
    switch (occasion) {
      case 'Casual':
        return ['Wrap Dresses', 'Belted Jeans', 'V-Neck Tops', 'High-Waisted Shorts', 'Fitted Tops'];
      case 'Party':
        return ['Bodycon Dresses', 'Belted Blazers', 'Pencil Skirts', 'Deep V-Neck Tops', 'Sequined Dresses'];
      case 'Office':
        return ['Wrap Blouses', 'Pencil Skirts', 'Belted Trousers', 'Fitted Blazers', 'Sheath Dresses'];
      case 'Wedding':
        return ['Mermaid Gowns', 'Belted Dresses', 'Fit and Flare Dresses', 'Sweetheart Necklines', 'Lace Details'];
      case 'Gym':
        return ['High-Waisted Leggings', 'Fitted Tanks', 'Sports Bras', 'Cropped Hoodies', 'Compression Wear'];
      default:
        return ['Fitted Clothing', 'Waist-Cinching Styles'];
    }
  }


  // PEAR RECOMMENDATIONS

  List<String> _getPearRecommendations(String occasion) {
    switch (occasion) {
      case 'Casual':
        return ['A-Line Skirts', 'Dark Wash Jeans', 'Off-Shoulder Tops', 'Flowy Blouses', 'Wide-Leg Pants'];
      case 'Party':
        return ['Sequined Tops', 'Dark Fitted Bottoms', 'Statement Necklaces', 'Wrap Tops', 'A-Line Mini Skirts'];
      case 'Office':
        return ['Dark Trousers', 'Light Blouses', 'Structured Blazers', 'A-Line Skirts', 'Wrap Dresses'];
      case 'Wedding':
        return ['A-Line Gowns', 'Empire Waist Dresses', 'Dark Colored Dresses', 'V-Neck Chiffon', 'Flared Skirts'];
      case 'Gym':
        return ['Dark Leggings', 'Bright Tank Tops', 'High-Waisted Shorts', 'Sports Bras', 'Patterned Tops'];
      default:
        return ['Balance Upper Body', 'Dark Bottoms'];
    }
  }


  // RECTANGLE RECOMMENDATIONS

  List<String> _getRectangleRecommendations(String occasion) {
    switch (occasion) {
      case 'Casual':
        return ['Peplum Tops', 'Belted Dresses', 'Ruffle Blouses', 'High-Waisted Jeans', 'A-Line Skirts'];
      case 'Party':
        return ['Bodycon with Belts', 'Peplum Dresses', 'Ruffle Hem Skirts', 'Statement Belts', 'Tiered Dresses'];
      case 'Office':
        return ['Peplum Blazers', 'Belted Dresses', 'Ruffle Blouses', 'Wide-Leg Pants', 'Structured Suits'];
      case 'Wedding':
        return ['A-Line with Belts', 'Peplum Gowns', 'Fit and Flare', 'Waist-Cinching Dresses', 'Ruffled Details'];
      case 'Gym':
        return ['Color Block Leggings', 'Cropped Tops', 'Belted Sweatshirts', 'High-Waisted Shorts', 'Patterned Wear'];
      default:
        return ['Create Curves', 'Define Waist'];
    }
  }


  // INVERTED TRIANGLE RECOMMENDATIONS

  List<String> _getInvertedTriangleRecommendations(String occasion) {
    switch (occasion) {
      case 'Casual':
        return ['A-Line Skirts', 'Dark Tops', 'Wide-Leg Pants', 'V-Neck Shirts', 'Flared Bottoms'];
      case 'Party':
        return ['Dark Sequin Tops', 'A-Line Mini Skirts', 'Statement Bottoms', 'Deep V-Necks', 'Wide-Leg Pants'];
      case 'Office':
        return ['Dark Blazers', 'A-Line Skirts', 'Wide-Leg Trousers', 'V-Neck Blouses', 'Structured Bottoms'];
      case 'Wedding':
        return ['A-Line Gowns', 'V-Neck Dresses', 'Dark Colored Tops', 'Full Skirts', 'Empire Waist Styles'];
      case 'Gym':
        return ['Dark Tank Tops', 'Bright Leggings', 'High-Waisted Shorts', 'Racerback Bras', 'Patterned Bottoms'];
      default:
        return ['Balance Shoulders', 'Add Volume to Hips'];
    }
  }


  // APPLE RECOMMENDATIONS (was Round)

  List<String> _getAppleRecommendations(String occasion) {
    switch (occasion) {
      case 'Casual':
        return ['Empire Waist Tops', 'Dark Jeans', 'V-Neck Shirts', 'Long Cardigans', 'A-Line Skirts'];
      case 'Party':
        return ['Empire Waist Dresses', 'Dark Flowy Tops', 'Statement Necklaces', 'A-Line Skirts', 'Wrap Dresses'];
      case 'Office':
        return ['Empire Waist Blouses', 'Dark Trousers', 'Long Blazers', 'V-Neck Shells', 'A-Line Skirts'];
      case 'Wedding':
        return ['Empire Waist Gowns', 'A-Line Dresses', 'V-Neck Chiffon', 'Dark Colored Dresses', 'Flowing Styles'];
      case 'Gym':
        return ['Dark Leggings', 'Long Tank Tops', 'V-Neck Sports Bras', 'Dark Shorts', 'Flowy Tops'];
      default:
        return ['Create Vertical Lines', 'V-Necks'];
    }
  }
}