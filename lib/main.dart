// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:sahara_app/modules/auth_module.dart';
import 'package:sahara_app/pages/resource_page.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/configs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('payment_modes');
  await Hive.openBox('redeem_rewards');
  await Hive.openBox('staff_list');
  await Hive.openBox('products');

  // Check if setup is complete
  final prefs = await SharedPreferences.getInstance();
  final isSetupComplete = prefs.getBool('isSetupComplete') ?? false;

  print('🔍 Setup status: $isSetupComplete');

  // ✅ CRITICAL: Update baseTatsUrl FIRST, before any auth operations
  final savedUrl = prefs.getString(urlKey);
  if (savedUrl != null && savedUrl.isNotEmpty) {
    baseTatsUrl = savedUrl;
    print('✅ Updated baseTatsUrl to: $baseTatsUrl');
  } else {
    print('⚠️ No saved URL found, using default: $baseTatsUrl');
  }

  // ✅ Now do the OAuth login with the correct URL
  final AuthModule authModule = AuthModule();
  authModule.login().then((response) {
    if (response.success) {
      print('✅ OAuth login successful in background');
    } else {
      print('❌ OAuth login failed: ${response.message}');
    }
  }).catchError((error) {
    print('💥 OAuth login error: $error');
  });

  runApp(MyApp(startOnUsersPage: isSetupComplete));
}

class MyApp extends StatelessWidget {
  final bool startOnUsersPage;

  const MyApp({super.key, required this.startOnUsersPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahara App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown)
      ),
      debugShowCheckedModeBanner: false,
      home: startOnUsersPage ? const UsersPage() : const ResourcePage(),
    );
  }
}