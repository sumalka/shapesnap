import 'package:hive_flutter/hive_flutter.dart';
import '../models/history_entry.dart';

class HistoryService {
  static const String _boxName = 'history';

  Future<Box<HistoryEntry>> _getBox() async {
    try {
      return await Hive.openBox<HistoryEntry>(_boxName);
    } catch (e) {
      print('Error opening box: $e');
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        print('Deleted and recreating history box');
        return await Hive.openBox<HistoryEntry>(_boxName);
      } catch (e2) {
        print('Error recreating box: $e2');
        rethrow;
      }
    }
  }

  Future<void> saveEntry(HistoryEntry entry) async {
    final box = await _getBox();
    await box.put(entry.id, entry);
    print('Saved history entry: ${entry.bodyShape}');
  }

  Future<List<HistoryEntry>> getAllHistory() async {
    final box = await _getBox();
    final entries = box.values.toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  Future<void> deleteEntry(String id) async {
    final box = await _getBox();
    await box.delete(id);
    print('Deleted history entry: $id');
  }

  Future<void> clearAllHistory() async {
    final box = await _getBox();
    await box.clear();
    print('Cleared all history');
  }

  Future<HistoryEntry?> getEntry(String id) async {
    final box = await _getBox();
    return box.get(id);
  }
}