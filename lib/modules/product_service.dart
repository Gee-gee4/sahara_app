// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/response_model.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';

import 'package:sahara_app/models/product_category_model.dart';

class ProductService {
   static Future<String?> get baseUrl async {
    final url = await apiUrl();
    if (url == null) {
      return null;
    }
    return '$url/api';
  }

  static Future<ResponseModel<List<ProductCategoryModel>>> fetchProductItems(String deviceId) async {
    final url = Uri.parse('${await baseUrl}/GetPOSProductItems/$deviceId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> productItems = data['productItems'];
        return ResponseModel(isSuccessfull: true, message: '', body: productItems
            .map((json) => ProductCategoryModel.fromJson(json))
            .toList());
      } else {
        print('❌ Failed to fetch products: ${response.statusCode}');
        return ResponseModel(isSuccessfull: false, message: response.body, body: []);
      }
    } 
    on SocketException catch (_){
      return ResponseModel(isSuccessfull: false, message: 'No Internet Connectivity', body:[]);
    } 
    catch (e) {
      print('❌ Exception fetching product items: $e');
      return ResponseModel(isSuccessfull: false, message: e.toString(), body: []);
    }
  }

  static Future<void> saveProductItemsToHive(String deviceId) async {
    final items = await fetchProductItems(deviceId);

    final hiveBox = Hive.box('products');
    final itemsAsMap = items.body.map((cat) => cat.toJson()).toList();
    await hiveBox.put('productItems', itemsAsMap);

    print('✅ Saved ${items.body.length} product categories to Hive');
  }
}
