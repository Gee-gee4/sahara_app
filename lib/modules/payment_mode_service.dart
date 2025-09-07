// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/response_model.dart';
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

  static Future<ResponseModel<List<PaymentModeModel>>> fetchPosAcceptedModesByDevice(
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

        return ResponseModel(isSuccessfull: true, message: '', body: acceptedModes);
      } else {
        print('❌ Server error: ${response.statusCode}');
        return ResponseModel(isSuccessfull: false, message: response.body, body: []);
      }
    } 
    on SocketException catch (_){
      return ResponseModel(isSuccessfull: false, message: 'No Internet Connectivity', body:[]);
    } 
    catch (e) {
      print('❌ Exception fetching product payment modes: $e');
      return ResponseModel(isSuccessfull: false, message: e.toString(), body: []);
    }
  }
}
