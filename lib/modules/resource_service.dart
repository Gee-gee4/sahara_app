import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/resource_model.dart';

class ResourceService {
  static Future<bool> fetchAndSaveConfig(String resourceName) async {
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
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}