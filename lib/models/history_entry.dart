import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 0)
class HistoryEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String bodyShape;

  @HiveField(2)
  final double shoulderHipRatio;

  @HiveField(3)
  final String imagePath;

  @HiveField(4)
  final String thumbnailPath;

  @HiveField(5)
  final List<String> doRecommendations;

  @HiveField(6)
  final List<String> dontRecommendations;

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  final String styleTip;

  @HiveField(9)
  final String confidenceScore;

  HistoryEntry({
    required this.id,
    required this.bodyShape,
    required this.shoulderHipRatio,
    required this.imagePath,
    required this.thumbnailPath,
    required this.doRecommendations,
    required this.dontRecommendations,
    required this.timestamp,
    this.styleTip = '',
    this.confidenceScore = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bodyShape': bodyShape,
      'shoulderHipRatio': shoulderHipRatio,
      'imagePath': imagePath,
      'thumbnailPath': thumbnailPath,
      'doRecommendations': doRecommendations,
      'dontRecommendations': dontRecommendations,
      'timestamp': timestamp.toIso8601String(),
      'styleTip': styleTip,
      'confidenceScore': confidenceScore,
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'],
      bodyShape: json['bodyShape'],
      shoulderHipRatio: json['shoulderHipRatio'],
      imagePath: json['imagePath'],
      thumbnailPath: json['thumbnailPath'],
      doRecommendations: List<String>.from(json['doRecommendations']),
      dontRecommendations: List<String>.from(json['dontRecommendations']),
      timestamp: DateTime.parse(json['timestamp']),
      styleTip: json['styleTip'] ?? '',
      confidenceScore: json['confidenceScore'] ?? '',
    );
  }
}

// Hive Adapter for HistoryEntry
class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 0;

  @override
  HistoryEntry read(BinaryReader reader) {
    final id = reader.readString();
    final bodyShape = reader.readString();
    final shoulderHipRatio = reader.readDouble();
    final imagePath = reader.readString();
    final thumbnailPath = reader.readString();
    final doRecommendations = reader.readList().cast<String>();
    final dontRecommendations = reader.readList().cast<String>();
    final timestamp = DateTime.parse(reader.readString());

    // Handle new fields with try-catch for backward compatibility
    String styleTip = '';
    String confidenceScore = '';
    try {
      styleTip = reader.readString();
    } catch (e) {
      // Field doesn't exist, use default
      styleTip = '';
    }
    try {
      confidenceScore = reader.readString();
    } catch (e) {
      // Field doesn't exist, use default
      confidenceScore = '';
    }

    return HistoryEntry(
      id: id,
      bodyShape: bodyShape,
      shoulderHipRatio: shoulderHipRatio,
      imagePath: imagePath,
      thumbnailPath: thumbnailPath,
      doRecommendations: doRecommendations,
      dontRecommendations: dontRecommendations,
      timestamp: timestamp,
      styleTip: styleTip,
      confidenceScore: confidenceScore,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.bodyShape);
    writer.writeDouble(obj.shoulderHipRatio);
    writer.writeString(obj.imagePath);
    writer.writeString(obj.thumbnailPath);
    writer.writeList(obj.doRecommendations);
    writer.writeList(obj.dontRecommendations);
    writer.writeString(obj.timestamp.toIso8601String());
    writer.writeString(obj.styleTip);
    writer.writeString(obj.confidenceScore);
  }
}