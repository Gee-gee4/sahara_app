import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  static Future<void> syncAll() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('webApiServiceUrl');

    if (baseUrl == null) throw Exception("No base URL found");

    await _syncList('$baseUrl/products', 'products');
    await _syncList('$baseUrl/staff', 'staff');
    await _syncList('$baseUrl/channels', 'channels');
    await _syncList('$baseUrl/payment_modes', 'paymentModes');
    await _syncList('$baseUrl/redeem_items', 'redeemItems');
  }

  static Future<void> _syncList(String url, String storageKey) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        storageKey,
        data.map((e) => json.encode(e)).toList(),
      );
    } else {
      throw Exception("Failed to fetch $storageKey");
    }
  }
}
