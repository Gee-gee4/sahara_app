import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:sahara_app/pages/resource_page.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('payment_modes');
  await Hive.openBox('redeem_rewards');
  await Hive.openBox('staff_list');
  await Hive.openBox('products');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const ResourcePage(),
    );
  }
}
