import '../models/body_shape.dart';

class RecommendationService {

  List<String> getDoRecommendations(BodyShape shape, String occasion) {
    // Only return casual recommendations
    final Map<BodyShape, List<String>> casualRecommendations = {
      BodyShape.pear: ['A-line skirt', 'Dark wash jeans', 'Off-shoulder top', 'Flowy blouse'],
      BodyShape.hourglass: ['Wrap dress', 'Belted jeans', 'V-neck t-shirt', 'High-waisted shorts'],
      BodyShape.rectangle: ['Peplum top', 'Belted dress', 'Ruffle blouse', 'High-waisted jeans'],
      BodyShape.invertedTriangle: ['A-line skirt', 'Dark top', 'Wide-leg pants', 'V-neck shirt'],
      BodyShape.apple: ['Empire waist top', 'Dark jeans', 'V-neck shirt', 'Long cardigan'],
    };

    return casualRecommendations[shape] ?? ['A-line dress', 'V-neck top', 'Dark bottoms'];
  }

  List<String> getDontRecommendations(BodyShape shape, String occasion) {
    // Only return casual recommendations
    final Map<BodyShape, List<String>> casualRecommendations = {
      BodyShape.pear: ['Skinny jeans', 'Cropped tops', 'Horizontal stripes', 'Low-rise pants'],
      BodyShape.hourglass: ['Baggy clothes', 'Drop waist', 'Oversized tops', 'Boxy cuts'],
      BodyShape.rectangle: ['Straight shift dress', 'Unstructured top', 'Low-rise pants', 'Monochrome'],
      BodyShape.invertedTriangle: ['Puff sleeves', 'Boat neck', 'Shoulder pads', 'Skinny pants'],
      BodyShape.apple: ['Crop tops', 'Belted waist', 'Horizontal stripes', 'Tight fabrics'],
    };

    return casualRecommendations[shape] ?? ['Skinny jeans', 'Cropped tops', 'Horizontal stripes'];
  }

  List<String> getOccasions() {
    // Only return Casual
    return ['Casual'];
  }
}