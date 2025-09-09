import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/response_model.dart';
import 'package:sahara_app/models/pump_model.dart';
import 'package:sahara_app/modules/auth_module.dart';
import 'package:sahara_app/utils/configs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PumpsModule {
  final AuthModule _authModule = AuthModule();

  Future<ResponseModel<List<PumpModel>>> fetchPumps() async {
    List<PumpModel> items = [];

    try {
      final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

      // ✅ Force update baseTatsUrl before making API calls
      final savedUrl = sharedPreferences.getString(urlKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        baseTatsUrl = savedUrl;
        print('🔄 Force updated baseTatsUrl to: $baseTatsUrl');
      }

      // ✅ CRITICAL: Trim the station name to remove any spaces
      String stationName = (sharedPreferences.getString(stationNameKey) ?? '').trim();

      print('🔍 Debug PumpsModule:');
      print('  Station Name: "$stationName" (length: ${stationName.length})');
      print('  baseTatsUrl: "$baseTatsUrl"');

      // Check if station name is configured
      if (stationName.isEmpty) {
        return ResponseModel(
          isSuccessfull: false, 
          message: 'Station name not configured. Please check your settings.', 
          body: []
        );
      }

      // fetch token
      String token = await _authModule.fetchToken();
      Map<String, String> headers = {'Content-type': 'application/json', 'authorization': 'Bearer $token'};

      final url = fetchPumpsUrl(stationName);
      print('  API URL: $url');
      print('  URL Length: ${url.length}');

      final res = await http.get(Uri.parse(url), headers: headers);

      print('  Response Status: ${res.statusCode}');
      print('  Response Body: ${res.body}');

      if (res.statusCode == 200) {
        Map body = Map.from(json.decode(res.body));
        print('  Parsed Body Keys: ${body.keys.toList()}');

        List<Map> rawPumps = List<Map>.from(body['pumps'] ?? []);
        print('  Raw Pumps Count: ${rawPumps.length}');

        items = rawPumps.map((pump) {
          final pumpModel = PumpModel(pumpName: pump['label'], pumpId: pump['rdgIndex']);
          print('  Created PumpModel: $pumpModel');
          return pumpModel;
        }).toList();

        print('  Final Items Count: ${items.length}');
        return ResponseModel(isSuccessfull: true, message: '', body: items);
      } else {
        print('  ❌ HTTP Error ${res.statusCode}: ${res.body}');

        // ✅ Handle specific HTTP errors with user-friendly messages
        String errorMessage;
        if (res.statusCode == 404) {
          errorMessage = 'Station "$stationName" not found. Please check your station name in settings.';
        } else if (res.statusCode == 401) {
          errorMessage = 'Authentication failed. Please check your login credentials.';
        } else if (res.statusCode == 403) {
          errorMessage = 'Access denied. You don\'t have permission to view pumps for this station.';
        } else if (res.statusCode == 500) {
          errorMessage = 'Server is experiencing issues. Please try again in a few minutes.';
        } else if (res.statusCode == 502 || res.statusCode == 503) {
          errorMessage = 'Server is temporarily unavailable. Please try again later.';
        } else if (res.statusCode == 504) {
          errorMessage = 'Request timed out. Please check your connection and try again.';
        } else if (res.statusCode >= 500) {
          errorMessage = 'Server error. Please try again later.';
        } else {
          errorMessage = 'Unable to load pumps. Please try again.';
        }
        return ResponseModel(isSuccessfull: false, message: errorMessage, body: []);
      }
    } on SocketException catch (_) {
      print('  ❌ No Internet Connectivity');
      return ResponseModel(isSuccessfull: false, message: 'No Internet Connection', body: []);
    } on http.ClientException catch (e) {
      print('  ❌ Connection error: $e');
      // Handle specific connection errors
      if (e.message.contains('Connection reset') || e.message.contains('reset by peer')) {
        return ResponseModel(
          isSuccessfull: false, 
          message: 'Connection was interrupted. Please check your internet and try again.', 
          body: []
        );
      } else if (e.message.contains('Connection refused')) {
        return ResponseModel(
          isSuccessfull: false, 
          message: 'Unable to connect to server. Please check your settings.', 
          body: []
        );
      } else if (e.message.contains('timeout')) {
        return ResponseModel(
          isSuccessfull: false, 
          message: 'Connection timed out. Please try again.', 
          body: []
        );
      } else {
        return ResponseModel(
          isSuccessfull: false, 
          message: 'Connection problem. Please check your internet and try again.', 
          body: []
        );
      }
    } on TimeoutException catch (_) {
      print('  ❌ Request timeout');
      return ResponseModel(
        isSuccessfull: false, 
        message: 'Request timed out. Please try again.', 
        body: []
      );
    } on FormatException catch (_) {
      print('  ❌ Invalid response format');
      return ResponseModel(
        isSuccessfull: false, 
        message: 'Received invalid data from server. Please try again.', 
        body: []
      );
    } catch (e, stackTrace) {
      print('  💥 Exception in fetchPumps: $e');
      print('  Stack Trace: $stackTrace');
      
      // Provide user-friendly message for any other errors
      return ResponseModel(
        isSuccessfull: false, 
        message: 'Something went wrong. Please try again.', 
        body: []
      );
    }
  }
}
