import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/response_model.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/resource_model.dart';

class ResourceService {
  static Future<ResponseModel<ResourceModel?>> fetchAndSaveConfig(String resourceName) async {
    final url = 'https://blob.storage.saharafcs.com/$resourceName/$resourceName.txt';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final config = ResourceModel.fromJson(jsonData);

        await SharedPrefsHelper.saveResourceModel(
          channel: config.channel,
          colorResource: config.colorResource,
          drawableResource: config.drawableResource,
          webApiServiceUrl: config.webApiServiceUrl,
          resourceName: resourceName,
        );
        return ResponseModel(isSuccessfull: true, message: 'Configuration loaded successfully', body: config);
      } else {
        print('❌ Server error: ${response.statusCode}');
        return ResponseModel(
          isSuccessfull: false,
          message: 'Server returned error: ${response.statusCode}',
          body: null,
        );
      }
    } on SocketException catch (_) {
      return ResponseModel(isSuccessfull: false, message: 'No Internet Connectivity', body: null);
    } catch (e) {
      print('❌ Exception fetching resource config: $e');
      return ResponseModel(
        isSuccessfull: false,
        message: 'Failed to load configuration: ${e.toString()}',
        body: null,
      );
    }
  }
}
