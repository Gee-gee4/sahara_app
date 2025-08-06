// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/permissions_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class StaffListService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl();
    if (url == null) {
      return null;
    }
    return '$url/api';
  }

  static Future<List<StaffListModel>> fetchStaffList(String deviceId) async {
     final url = Uri.parse('${await baseUrl}/ChannelStaff/$deviceId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> jsonList = data['staffList'] ?? [];
        List<Map> permissionsList = List<Map>.from(data['permissionsList'] ?? []);
        final List<Map> rolePermisionsList = List<Map>.from(
          data['rolePermisionsList'] ?? [],
        );

        permissionsList = permissionsList.where((permMap) {
          String permissionName = permMap['name'].toString();
          return PermissionsEnum.values
              .map((p) => p.name.toLowerCase())
              .contains(permissionName.replaceAll('_', '').toLowerCase());
        }).toList();

        final List<PermissionsModel> permissionModels = permissionsList.map((perm) {
          String permissionName = perm['name'].toString();
          return PermissionsModel(
            id: perm['id'],
            permissionName: PermissionsEnum.values.firstWhere(
              (p) =>
                  p.name.toLowerCase() ==
                  permissionName.replaceAll('_', '').toLowerCase(),
            ),
          );
        }).toList();

        final Map<int, List<int>> rolePermisionsMap = {};
        for (Map rolePerm in rolePermisionsList) {
          rolePermisionsMap[rolePerm['roleId']] = [...(rolePermisionsMap[rolePerm['roleId']] ?? []), rolePerm['permissionId']];
        }

        final staffs = jsonList
            .map((json) => StaffListModel.fromJson(json, allPermission: permissionModels, rolePermisionsMap: rolePermisionsMap))
            .toList();

        return staffs;
      } else {
        print('❌ Server error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception fetching staff list: $e');
      return [];
    }
  }
}
