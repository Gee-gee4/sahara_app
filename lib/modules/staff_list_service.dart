// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/response_model.dart';
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

  static Future<ResponseModel<List<StaffListModel>>> fetchStaffList(String deviceId) async {
    try {
      // Check baseUrl for null before using it
      final base = await baseUrl;
      if (base == null) {
        return ResponseModel(
          isSuccessfull: false,
          message: 'Base URL not configured',
          body: <StaffListModel>[],
        );
      }

      final url = Uri.parse('$base/ChannelStaff/$deviceId');
      print('🔄 Fetching staff list for device: $deviceId');
      print('🌐 URL: $url');

      final response = await http.get(url);
      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for API errors in the response
        if (data['error'] != null && data['error']['ErrorCode'] != 0) {
          final errorMsg = data['error']['ErrorMsg'] ?? 'Unknown error occurred';
          return ResponseModel(
            isSuccessfull: false,
            message: errorMsg,
            body: <StaffListModel>[],
          );
        }

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

        print('✅ Successfully fetched ${staffs.length} staff members');
        return ResponseModel(isSuccessfull: true, message: 'Staff list fetched successfully', body: staffs);
        
      } else if (response.statusCode == 404) {
        return ResponseModel(
          isSuccessfull: false,
          message: 'Staff list not found for this device',
          body: <StaffListModel>[],
        );
      } else {
        print('❌ Server error: ${response.statusCode}');
        return ResponseModel(
          isSuccessfull: false,
          message: 'Server error: ${response.statusCode}',
          body: <StaffListModel>[],
        );
      }
    } on SocketException catch (_) {
      print('❌ No Internet Connectivity for staff list fetch');
      return ResponseModel(
        isSuccessfull: false,
        message: 'No Internet Connectivity',
        body: <StaffListModel>[],
      );
    } catch (e) {
      print('❌ Exception fetching staff list: $e');
      return ResponseModel(
        isSuccessfull: false,
        message: e.toString(),
        body: <StaffListModel>[],
      );
    }
  }
}