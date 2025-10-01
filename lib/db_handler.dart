import 'package:hive_flutter/hive_flutter.dart';

class DatabaseHelper {
  static const String _boxName = "storageBox";

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_boxName);
  }

  static Box<Map> get _box => Hive.box<Map>(_boxName);

  // Create
  static Future<void> insertItem(
    String name,
    int qty,
    String location,
    String category,
  ) async {
    await _box.add({
      'name': name,
      'quantity': qty,
      'location': location,
      'category': category,
    });
  }

  // Read
  static List<Map> getItems() {
    return _box.values.toList();
  }

  // Update
  static Future<void> updateItem(
    int index,
    String name,
    int qty,
    String location,
    String category,
  ) async {
    await _box.putAt(index, {
      'name': name,
      'quantity': qty,
      'location': location,
      'category': category,
    });
  }

  // Delete
  static Future<void> deleteItem(int index) async {
    await _box.deleteAt(index);
  }
}
