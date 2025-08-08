import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/models/pump_model.dart';
import 'package:sahara_app/modules/auth_module.dart';
import 'package:sahara_app/utils/configs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PumpsModule {
  final AuthModule _authModule = AuthModule();
  
  Future<List<PumpModel>> fetchPumps() async {
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

      // fetch token
      String token = await _authModule.fetchToken();
      Map<String, String> headers = {
        'Content-type': 'application/json', 
        'authorization': 'Bearer $token'
      };

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
          final pumpModel = PumpModel(
            pumpName: pump['label'], 
            pumpId: pump['rdgIndex']
          );
          print('  Created PumpModel: $pumpModel');
          return pumpModel;
        }).toList();
        
        print('  Final Items Count: ${items.length}');
      } else {
        print('  ❌ HTTP Error ${res.statusCode}: ${res.body}');
      }
    } catch (e, stackTrace) {
      print('  💥 Exception in fetchPumps: $e');
      print('  Stack Trace: $stackTrace');
    }
    
    print('  Returning ${items.length} pumps');
    return items;
  }
}