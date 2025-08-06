// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
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

  static Future<ChannelModel?> fetchChannelByDeviceId(String deviceId) async {
    final url = Uri.parse('${await baseUrl}/ChannelDetails/$deviceId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // print("📦 Raw JSON fetched: $json");
        // final channel = ChannelModel.fromJson(json);
        // print("✅ Channel fetched:");
        // print("  • Name: ${channel.channelName}");
        // print("  • Company: ${channel.companyName}");
        // print("  • Country: ${channel.country}");
        // print("  • Address: ${channel.address}");
        // print("  • City: ${channel.city}");
        // print("  • Channel ID: ${channel.channelId}");
        // print("  • Decimals: ${channel.noOfDecimalPlaces}");
        // print("  • Auto Logoff: ${channel.staffAutoLogOff}");

        return ChannelModel.fromJson(json);
      } else {
        print('❌ API returned status code ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching channel: $e');
      return null;
    }
  }
}
