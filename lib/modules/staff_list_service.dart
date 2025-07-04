// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sahara_app/models/staff_list_model.dart';

class StaffListService {
  static const baseUrl = "https://cmb.saharafcs.com/api";

  static Future<List<StaffListModel>> fetchStaffList(String deviceId) async {
    final url = Uri.parse('$baseUrl/ChannelStaff/$deviceId');

    try{
      final response = await http.get(url);

      if(response.statusCode == 200){
        final data = jsonDecode(response.body);

        final List<dynamic> jsonList = data['staffList'];
        final staffs = jsonList.map((json) => StaffListModel.fromJson(json)).toList();

        return staffs;
      } else{
        print('❌ Server error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception fetching staff list: $e');
      return [];
    }
  }
}
