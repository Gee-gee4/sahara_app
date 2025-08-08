import 'package:sahara_app/models/model.dart';

class AccountModel extends Model {
  AccountModel({
    this.emailAddress, this.accountType
  }):super('accountBox');

  AccountModel.fromMap(Map map):super('accountBox'){
    emailAddress = map['emailAddress']?.toString();

    try {
      if(map['accountType'] != null){
        accountType = AccountType.values.byName(map['accountType'].toString());
      }
    } catch (_) {}
  }

  static String key = 'account';


  String? emailAddress;
  AccountType? accountType;

  Map<String, dynamic> asMap()=>{
    'emailAddress': emailAddress,
    'accountType': accountType?.name,
  };
}

enum AccountType{
  admin, manager, normal
}