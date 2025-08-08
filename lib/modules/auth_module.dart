import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sahara_app/models/token_model.dart';
import 'package:sahara_app/modules/account_module.dart';
import 'package:sahara_app/utils/configs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthModule {
  
  // 🆕 Add this method - check if user is logged in
  Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(TokenModel.isLoggedIn) ?? false;
  }

  // 🆕 Add this method - get token for API calls (doesn't require credentials)
  Future<String> getTokenForApiCall() async {
    TokenModel tokenModel = TokenModel();
    tokenModel = TokenModel.fromMap((await tokenModel.get(TokenModel.key)) ?? {});

    // Check if we have a valid token
    if (tokenModel.token != null && tokenModel.isNotExpired) {
      return tokenModel.token!;
    }

    // Check if we can refresh
    if (tokenModel.refreshToken != null) {
      return await fetchToken(grantType: GrantType.refresh_token);
    }

    // No valid token or refresh token available
    throw Exception('Authentication required - please login again');
  }

  // login (your existing method)
  Future<LoginResponse> login({
    String email = 'gladysmbuthia324@gmail.com',
    String password = 'pass1234',
  }) async {
    try {
      await fetchToken(
        grantType: GrantType.password,
        username: email,
        password: password,
      );
      return LoginResponse(message: "Welcome", success: true);
    } on BadRequest catch (_) {
      return LoginResponse(message: "Wrong credentials", success: false);
    } on InternalServerError catch (e) {
      return LoginResponse(
        message: e.message ?? 'Server Error',
        success: false,
      );
    } on TokenRequestError catch (e) {
      return LoginResponse(message: e.toString(), success: false);
    } catch (e) {
      return LoginResponse(message: 'Check your internet', success: false);
    }
  }

  // logout (your existing method)
  Future<void> logout() async {
    TokenModel tokenModel = TokenModel();
    await tokenModel.delete(TokenModel.key);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TokenModel.isLoggedIn, false);
  }

  Future<String> fetchToken({
    GrantType grantType = GrantType.refresh_token,
    String? username,
    String? password,
  }) async {
    // Debug the URL construction
    print('🔍 URL Debug:');
    print('  baseTatsUrl: "$baseTatsUrl"');
    print('  authUrl: "$authUrl"');

    // get token
    TokenModel tokenModel = TokenModel();
    tokenModel = TokenModel.fromMap(
      (await tokenModel.get(TokenModel.key)) ?? {},
    );

    print('🔍 Token Debug:');
    print(
      '  Current token: ${tokenModel.token?.substring(0, 10) ?? 'null'}...',
    );
    print(
      '  Refresh token: ${tokenModel.refreshToken?.substring(0, 10) ?? 'null'}...',
    );
    print('  Expiry: ${tokenModel.expiry}');
    print('  Is not expired: ${tokenModel.isNotExpired}');

    // check if token exists and is not expired
    if (tokenModel.token != null && tokenModel.isNotExpired) {
      print('✅ Using existing valid token');
      return tokenModel.token!;
    }

    // Determine grant type based on available data
    if (tokenModel.refreshToken != null) {
      print('🔄 Attempting token refresh');
      grantType = GrantType.refresh_token;
    } else {
      if (username != null && password != null) {
        print('🔑 Using password grant');
        grantType = GrantType.password;
      } else {
        print('❌ No refresh token and no credentials provided');
        throw Exception('No refresh token available - please login again');
      }
    }

    final Map<String, String> headers = {
      'Content-type': 'application/x-www-form-urlencoded',
      'authorization': basicAuthorization,
    };

    final String grantTypeName = grantType.name;

    final Map<String, dynamic> body = {
      'grant_type': grantTypeName,
      'scope': 'transactions',
    };

    final Encoding? encoding = Encoding.getByName('utf-8');

    // dynamic body
    switch (grantType) {
      case GrantType.password:
        body.addAll({'username': username, 'password': password});
        break;
      case GrantType.refresh_token:
        body.addAll({'refresh_token': tokenModel.refreshToken});
        break;
    }

    print('🌐 Making OAuth request with grant type: $grantTypeName');

    // send request
    try {
      final http.Response res = await oauth2Request(
        authUrl,
        headers,
        body,
        encoding,
      );

      print('📡 OAuth Response: ${res.statusCode}');

      switch (res.statusCode) {
        // sucess
        case 200:
        case 201:
          var responseBody = json.decode(res.body);
          tokenModel.token = responseBody['access_token'];
          tokenModel.refreshToken = responseBody['refresh_token'];
          tokenModel.expiry = DateTime.now().add(
            Duration(
              seconds:
                  int.tryParse(responseBody['expires_in'].toString()) ?? 0,
            ),
          );

          print('✅ Token obtained successfully');
          print('  New expiry: ${tokenModel.expiry}');

          // save token model
          await tokenModel.put(TokenModel.key, tokenModel.asMap());
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool(TokenModel.isLoggedIn, true);

          final AccountModule accountModule = AccountModule();
          accountModule.fetchfromServer();

          return tokenModel.token ?? '';

        case 400:
          print('❌ Bad Request: ${res.body}');
          throw BadRequest(res.body);

        case 401:
          print('❌ Unauthorized - clearing tokens');
          // Clear invalid tokens
          await logout();
          throw Unauthorized();

        case 500:
          print('❌ Server Error: ${res.body}');
          throw InternalServerError(res.body);

        default:
          print('❌ Unexpected status: ${res.statusCode} - ${res.body}');
          throw TokenRequestError(res.statusCode, res.body);
      }
    } catch (e) {
      print('💥 OAuth request failed: $e');
      rethrow;
    }
  }

  String get basicAuthorization {
    final base64E = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
    return 'Basic $base64E';
  }

  Future<http.Response> oauth2Request(
    String url,
    Map<String, String> headers,
    Map<String, dynamic> body,
    Encoding? encoding,
  ) async {
    try {
      return await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
        encoding: encoding,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class LoginResponse {
  LoginResponse({required this.message, required this.success});
  String message;
  bool success;
}

enum GrantType {
  // client_credentials,
  // code,
  password,
  // ignore: constant_identifier_names
  refresh_token,
}

// exceptions
class Unauthorized implements Exception {
  @override
  String toString() => 'Unauthorized';
}

class InternalServerError implements Exception {
  InternalServerError([this.message]);
  String? message;
  @override
  String toString() => 'Internal Server Error: ${message ?? ""}';
}

class BadRequest implements Exception {
  BadRequest([this.message]);
  String? message;
  @override
  String toString() => 'Bad Request: ${message ?? ""}';
}

class TokenRequestError implements Exception {
  TokenRequestError(this.statuscode, [this.message]);
  String? message;
  int statuscode;
  @override
  String toString() => 'StatusCode: $statuscode, Message: ${message ?? ""}';
}