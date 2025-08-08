import 'package:sahara_app/models/model.dart';
// import 'package:pie_tats_app/src/models/model.dart';

class TokenModel extends Model{
  TokenModel({
    this.token, this.refreshToken, this.expiry
  }): super('token');
  TokenModel.fromMap(Map map): super('token'){
    token = map['token']?.toString();
    refreshToken = map['refreshToken']?.toString();
    
    if(map['expiry'] != null){
      expiry = DateTime.tryParse(map['expiry'].toString());
    }
  }
  static String key = 'token';
  static String isLoggedIn = 'isLoggedIn';


  String? token;
  String? refreshToken;
  DateTime? expiry;

  bool get isNotExpired{
    return expiry?.isAfter(DateTime.now()) ?? false;
  }

  Map<String, dynamic> asMap()=>{
    'token': token,
    'refreshToken': refreshToken,
    'expiry': expiry?.toIso8601String(),
  };


}