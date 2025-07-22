// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/initialize_cards_model.dart';

class InitializeCardService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl();
    if (url == null) {
      return null;
    }
    return '$url/api';
  }

  static Future<InitializeCardsModel?> fetchCardData({
    required String cardUID,
    required String imei,
    required int staffID,
  }) async {
    final root = await baseUrl;
    if (root == null) return null;
    final url = Uri.parse('$root/InitializeCardWithNoCode/$cardUID/$imei/$staffID');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return InitializeCardsModel.fromJson(data);
      } else {
        print('❌ Failed to fetch card data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error during fetch: $e');
      return null;
    }
  }

/// Format card via API using GET - removes assignment from portal
static Future<bool> formatCardAPI({
  required String cardUID,
  required int staffId,
}) async {
   final base = await baseUrl;
   if (base == null) return false;
  final url = Uri.parse('$base/CardFormat/$cardUID/$staffId'); // ✅ Use base instead
  
  try {
    print('📡 Formatting card via API: $url');
    final response = await http.get(url); 
    
    print('📡 Format API response: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('✅ Card unassigned from portal successfully');
      return true;
    } else {
      print('❌ API format failed: ${response.body}');
      return false;
    }
  } catch (e) {
    print('❌ Error calling format API: $e');
    return false;
  }
}
}
