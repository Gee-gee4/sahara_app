import 'package:flutter/material.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      appBar: AppBar(
        title: Text('Janet', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.card_membership_sharp, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: ColorsUniversal.background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Center(child: Text('No Products'))]),
    );
  }
}
