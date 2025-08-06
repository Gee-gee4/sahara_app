class CompleteCardInitModel {
  final String uid;
  final int accountNo;
  final int staffId;
  final String createdOn;

  CompleteCardInitModel({
    required this.uid,
    required this.accountNo,
    required this.staffId,
    required this.createdOn,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'accountNo': accountNo,
    'staffId': staffId,
    'createdOn': createdOn,
  };
}
