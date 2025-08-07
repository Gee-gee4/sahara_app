// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:sahara_app/pages/resource_page.dart';
import 'package:sahara_app/pages/users_page.dart';
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

  runApp(MyApp(startOnUsersPage: isSetupComplete));
}

class MyApp extends StatelessWidget {
  final bool startOnUsersPage;

  const MyApp({super.key, required this.startOnUsersPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      debugShowCheckedModeBanner: false,
      home: startOnUsersPage ? const UsersPage() : const ResourcePage(),
    );
  }
}
