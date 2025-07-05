// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/payment_mode_model.dart';

class PaymentModeService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl();
    if (url == null) {
      return null;
    }
    return '$url/api';
  }

  static Future<List<PaymentModeModel>> fetchPosAcceptedModesByDevice(
    String deviceId,
  ) async {
     final url = Uri.parse('${await baseUrl}/ChannelProductPayModes/$deviceId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> jsonList = data['paymentModes']; 


        final allModes = jsonList
            .map((json) => PaymentModeModel.fromJson(json))
            .toList();
        final acceptedModes = allModes.where((mode) => mode.isPosAccepted).toList();

        return acceptedModes;
      } else {
        print('❌ Server error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception fetching product payment modes: $e');
      return [];
    }
  }
}
