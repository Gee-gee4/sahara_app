// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/response_model.dart';
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

  static Future<ResponseModel<InitializeCardsModel?>> fetchCardData({
    required String cardUID,
    required String imei,
    required int staffID,
  }) async {
    final root = await baseUrl;
    if (root == null) return ResponseModel(isSuccessfull: false, message: 'Base URl not configured', body: null);
    final url = Uri.parse('$root/InitializeCardWithNoCode/$cardUID/$imei/$staffID');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ResponseModel(isSuccessfull: true, message: '', body: InitializeCardsModel.fromJson(data));
      } else {
        print('❌ Failed to fetch card data: ${response.statusCode}');
        return ResponseModel(isSuccessfull: false, message: response.body, body: null);
      }
    } on SocketException catch (_) {
      print('❌ No Internet Connectivity for card data fetch');
      return ResponseModel(isSuccessfull: false, message: 'No Internet Connectivity', body: null);
    } catch (e) {
      print('❌ Error during fetch: $e');
      return ResponseModel(isSuccessfull: false, message: e.toString(), body: null);
    }
  }

  /// Format card via API using GET - removes assignment from portal
  static Future<ResponseModel<bool>> formatCardAPI({required String cardUID, required int staffId}) async {
    final base = await baseUrl;
    if (base == null) return ResponseModel(isSuccessfull: false, message: 'Base URL not configured', body: false);
    ;
    final url = Uri.parse('$base/CardFormat/$cardUID/$staffId'); // ✅ Use base instead

    try {
      print('📡 Formatting card via API: $url');
      final response = await http.get(url);

      print('📡 Format API response: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ Card unassigned from portal successfully');
        return ResponseModel(isSuccessfull: true, message: 'Card formatted successfully', body: true);
      } else {
        print('❌ API format failed: ${response.body}');
        return ResponseModel(
          isSuccessfull: false,
          message: 'Format failed: ${response.statusCode} - ${response.body}',
          body: false,
        );
      }
    } on SocketException catch (_) {
      print('❌ No Internet Connectivity for card format');
      return ResponseModel(isSuccessfull: false, message: 'No Internet Connectivity', body: false);
    } catch (e) {
      print('❌ Error calling format API: $e');
      return ResponseModel(isSuccessfull: false, message: e.toString(), body: false);
    }
  }
}
