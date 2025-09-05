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
    final url = Uri.parse('${await baseUrl}/ChannelDetails/$deviceId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ResponseModel(
          isSuccessfull: true, 
          message: '', 
          body: ChannelModel.fromJson(json) // This should be ChannelModel, not ChannelModel?
        );
      } else {
        print('❌ API returned status code ${response.statusCode}');
        return ResponseModel(
          isSuccessfull: false, 
          message: response.body, 
          body: null
        );
      }
    } 
    on SocketException catch (_){
      return ResponseModel(
        isSuccessfull: false, 
        message: 'No Internet Connectivity', 
        body: null
      );
    }
    catch (e) {
      print('❌ Error fetching channel: $e');
      return ResponseModel(
        isSuccessfull: false, 
        message: e.toString(), 
        body: null
      );
    }
  }
}
