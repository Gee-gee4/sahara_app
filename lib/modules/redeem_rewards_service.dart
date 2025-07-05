// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/redeem_rewards_model.dart';

class RedeemRewardsService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl();
    if (url == null) {
      return null;
    }
    return '$url/api';
  }
  static Future<List<RedeemRewardsModel>> fetchRedeemRewards() async {
     final url = Uri.parse('${await baseUrl}/RedeemRewards');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> jsonList = data['rewards'];
        final rewards = jsonList
            .map((json) => RedeemRewardsModel.fromJson(json))
            .toList();

        return rewards;
      } else {
        print('❌ Server error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception fetching redeem rewards: $e');
      return [];
    }
  }
}
