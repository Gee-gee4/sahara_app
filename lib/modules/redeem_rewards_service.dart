// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/models/redeem_rewards_model.dart';

class RedeemRewardsService {
  static const String baseUrl = "https://cmb.saharafcs.com/api";

  static Future<List<RedeemRewardsModel>> fetchRedeemRewards() async {
    final url = Uri.parse('$baseUrl/RedeemRewards');

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
