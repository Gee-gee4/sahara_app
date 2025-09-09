// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/response_model.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/channel_model.dart';

class ChannelService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl();
    if (url == null) {
      return null;
    }
    return '$url/api';
  }

  static Future<ResponseModel<ChannelModel?>> fetchChannelByDeviceId(String deviceId) async {
    try {
      // 🔧 Fix: Check baseUrl for null before using it
      final base = await baseUrl;
      if (base == null) {
        return ResponseModel(
          isSuccessfull: false,
          message: 'Base URL not configured',
          body: null
        );
      }

      final url = Uri.parse('$base/ChannelDetails/$deviceId');
      print('🌐 Fetching channel for device: $deviceId');
      print('🌐 URL: $url');

      final response = await http.get(url);
      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        // Check if the API returned an error in the response
        if (json['error'] != null && json['error']['ErrorCode'] != 0) {
          final errorMsg = json['error']['ErrorMsg'] ?? 'Unknown error';
          return ResponseModel(
            isSuccessfull: false,
            message: errorMsg,
            body: null
          );
        }

        return ResponseModel(
          isSuccessfull: true, 
          message: 'Channel fetched successfully', 
          body: ChannelModel.fromJson(json)
        );
      } else if (response.statusCode == 404) {
        return ResponseModel(
          isSuccessfull: false,
          message: 'Device not registered in system',
          body: null
        );
      } else {
        print('❌ API returned status code ${response.statusCode}');
        return ResponseModel(
          isSuccessfull: false, 
          message: 'Failed to fetch channel: ${response.statusCode}', 
          body: null
        );
      }
    } on SocketException catch (_) {
      print('❌ No Internet Connectivity for channel fetch');
      return ResponseModel(
        isSuccessfull: false, 
        message: 'No Internet Connectivity', 
        body: null
      );
    } catch (e) {
      print('❌ Error fetching channel: $e');
      return ResponseModel(
        isSuccessfull: false, 
        message: e.toString(), 
        body: null
      );
    }
  }
}
