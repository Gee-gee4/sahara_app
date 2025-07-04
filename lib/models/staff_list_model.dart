class StaffListModel {
  StaffListModel({
    required this.staffId,
    required this.staffName,
    required this.staffPin,
    required this.staffPassword,
    required this.roleId,
    required this.staffEmail,
  });
  final int staffId;
  final String staffName;
  final String staffPin;
  final String staffPassword;
  final int roleId;
  final String staffEmail;

  factory StaffListModel.fromJson(Map<String, dynamic> json) {
    return StaffListModel(
      staffId: json['staffId'],
      staffName: json['staffName'] ?? '',
      staffPin: json['staffPin'] ?? '',
      staffPassword: json['staffPassword'] ?? '',
      roleId: json['roleId'],
      staffEmail: json['staffEmail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'staffName': staffName,
    'staffPin': staffPin,
    'staffPassword': staffPassword,
    'roleId': roleId,
    'staffEmail': staffEmail,
  };
}
