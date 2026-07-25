enum BodyShape {
  pear,
  hourglass,
  rectangle,
  invertedTriangle,
  apple,
}

extension BodyShapeExtension on BodyShape {
  String get displayName {
    switch (this) {
      case BodyShape.pear:
        return 'Pear';
      case BodyShape.hourglass:
        return 'Hourglass';
      case BodyShape.rectangle:
        return 'Rectangle';
      case BodyShape.invertedTriangle:
        return 'Inverted Triangle';
      case BodyShape.apple:
        return 'Apple';
    }
  }

  String get description {
    switch (this) {
      case BodyShape.pear:
        return 'Hips are wider than shoulders. Add volume to your upper body.';
      case BodyShape.hourglass:
        return 'Balanced shoulders and hips with a defined waist.';
      case BodyShape.rectangle:
        return 'Similar measurements throughout. Create curves with clothing.';
      case BodyShape.invertedTriangle:
        return 'Shoulders are wider than hips. Add volume to your lower body.';
      case BodyShape.apple:
        return 'Waist is wider than shoulders and hips. Create vertical lines.';
    }
  }

  String get shoulderHipAdvice {
    switch (this) {
      case BodyShape.pear:
        return 'Your hips are wider than your shoulders. Balance by adding volume on top.';
      case BodyShape.hourglass:
        return 'Your shoulders and hips are balanced. Emphasize your waist.';
      case BodyShape.rectangle:
        return 'Your shoulders and hips are balanced. Create curves with belts and peplums.';
      case BodyShape.invertedTriangle:
        return 'Your shoulders are wider than your hips. Add volume to your lower body.';
      case BodyShape.apple:
        return 'Your waist is the widest part. Create vertical lines with open necklines.';
    }
  }

  List<String> getDoRecommendations(String occasion) {
    switch (this) {
      case BodyShape.pear:
        return ['A-line skirts', 'Empire waist tops', 'Dark bottoms', 'Statement necklaces'];
      case BodyShape.hourglass:
        return ['Wrap dresses', 'Belted coats', 'Pencil skirts', 'V-neck tops'];
      case BodyShape.rectangle:
        return ['Peplum tops', 'Belted dresses', 'Ruffle details', 'Color blocking'];
      case BodyShape.invertedTriangle:
        return ['A-line skirts', 'V-neck tops', 'Dark tops', 'Wide-leg pants'];
      case BodyShape.apple:
        return ['Empire waist', 'V-neck tops', 'Dark colors', 'Vertical lines'];
    }
  }

  List<String> getDontRecommendations(String occasion) {
    switch (this) {
      case BodyShape.pear:
        return ['Skinny jeans', 'Low-rise pants', 'Horizontal stripes', 'Cropped tops'];
      case BodyShape.hourglass:
        return ['Baggy clothes', 'Drop waist', 'Turtlenecks', 'Oversized blazers'];
      case BodyShape.rectangle:
        return ['Straight shift dress', 'Unstructured jackets', 'Low-rise pants', 'Monochrome'];
      case BodyShape.invertedTriangle:
        return ['Puff sleeves', 'Boat neck', 'Shoulder pads', 'Skinny pants'];
      case BodyShape.apple:
        return ['Crop tops', 'Belted waist', 'Horizontal stripes', 'Tight fabrics'];
    }
  }
}