import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sahara_app/models/account_model.dart';
import 'package:sahara_app/modules/auth_module.dart';
import 'package:sahara_app/utils/configs.dart';

class AccountModule {

  // get account
  Future<AccountModel> getUser()async{
    AccountModel accountModel = AccountModel();
    return AccountModel.fromMap((await accountModel.get(AccountModel.key)) ?? {});
  }
  

  // fetch account from server
  Future<AccountModel?> fetchfromServer()async{
    try {
      // fetch token
      AuthModule authModule = AuthModule();
      final token = await authModule.fetchToken();
      Map<String, String> headers = {
        'Content-type' : 'application/json', 
        'authorization': 'Bearer $token'
      };

      final res = await http.get(Uri.parse(userInfoUrl), headers: headers);
      if(res.statusCode == 200){
        final body = json.decode(res.body);
        AccountType accountType = AccountType.normal;
        try {
          accountType = AccountType.values.byName(body['userType']);
        } catch (_) {}

        AccountModel accountModel = AccountModel(accountType: accountType, emailAddress: body['email']);

        // save the account
        await accountModel.put(AccountModel.key, accountModel.asMap());


        return accountModel;
      }

      
    } catch (_) {}
    return null;
  }
}