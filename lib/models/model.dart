import 'package:hive/hive.dart';
// import 'package:hive_flutter/hive_flutter.dart';

class Model {
  Model(this.boxName);
  final String boxName;


  Future<void> save(Map<String, dynamic> value) async {
    var box = await Hive.openBox<Map>(boxName);
    await box.add(value);
    await box.close();
  }


  Future<void> saveMany(List<Map<String, dynamic>> values) async {
    var box = await Hive.openBox<Map>(boxName);
    await box.addAll(values);
    await box.close();
  }

  Future<void> put(String key, Map<String, dynamic> value) async {
    var box = await Hive.openBox<Map>(boxName);
    await box.put(key, value);
    await box.close();
  }

  Future<Map?> get(String key) async {
    var box = await Hive.openBox<Map>(boxName);
    final res = box.get(key);
    await box.close();
    return res;
  }

  Future<void> delete(String key) async {
    var box = await Hive.openBox<Map>(boxName);
    await box.delete(key);
    await box.close();
  }


  Future<List<Map>> fetch() async {
    List<Map> items = [];
    Box<Map> box = await Hive.openBox<Map>(boxName);
    
    items = box.values.toList();
    await box.close();
    return items;
  }

  Future<void> updateAt(int index, Map<String, dynamic> value) async {
    var box = await Hive.openBox<Map>(boxName);
    await box.putAt(index, value);
    await box.close();
  }

  Future<void> deleteAt(int index,) async {
    var box = await Hive.openBox<Map>(boxName);
    await box.deleteAt(index);
    await box.close();
  }

  Future<void> deleteAll() async {
    var box = await Hive.openBox<Map>(boxName);
    await box.clear();
    await box.close();
  }

}