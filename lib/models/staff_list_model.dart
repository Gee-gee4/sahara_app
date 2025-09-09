import 'package:sahara_app/models/permissions_model.dart';

class StaffListModel {
  StaffListModel({
    required this.staffId,
    required this.staffName,
    required this.staffPin,
    required this.staffPassword,
    required this.roleId,
    required this.staffEmail,
    required this.permissions,
  });
  final int staffId;
  final String staffName;
  final String staffPin;
  final String staffPassword;
  final int roleId;
  final String staffEmail;
  final List<PermissionsModel> permissions;

  bool hasPermission(PermissionsEnum permission) {
    // return false;
    return permissions.where((item) => item.permissionName == permission).isNotEmpty;
  }

  factory StaffListModel.fromJson(
    Map<String, dynamic> json, {
    List<PermissionsModel>? allPermission,
    Map<int, List<int>>? rolePermisionsMap,
  }) {
    int roleId = json['roleId'];
    late final List<PermissionsModel> userPermissions;
    if (allPermission != null && rolePermisionsMap != null) {
      final List<int> userPermissionIds = rolePermisionsMap[roleId] ?? [];
      userPermissions = allPermission.where((perm) => userPermissionIds.contains(perm.id)).toList();
    } else {
      userPermissions = List<Map>.from(json['permissions'] ?? []).map((p) => PermissionsModel.fromJson(p)).toList();
    }

    return StaffListModel(
      staffId: json['staffId'],
      staffName: json['staffName'] ?? '',
      staffPin: json['staffPin'] ?? '',
      staffPassword: json['staffPassword'] ?? '',
      roleId: roleId,
      staffEmail: json['staffEmail'] ?? '',
      permissions: userPermissions,
    );
  }

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'staffName': staffName,
    'staffPin': staffPin,
    'staffPassword': staffPassword,
    'roleId': roleId,
    'staffEmail': staffEmail,
    'permissions': permissions.map((p) => p.toJson()).toList(),
  };
}

StaffListModel? globalCurrentUser;
