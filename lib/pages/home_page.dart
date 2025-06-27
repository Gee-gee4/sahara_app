import 'package:flutter/material.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user});
  final String user;
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
        title: Text(user, style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.card_membership_sharp, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: ColorsUniversal.background,
                    title: Text('LOG OUT'),
                    content: Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.brown[800],fontSize: 17),
                        ),
                      ),
                      TextButton(
                        child: Text(
                          'OK',
                          style: TextStyle(color: Colors.brown[800], fontSize: 17),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UsersPage()),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: ColorsUniversal.background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Center(child: Text('No Products'))],
      ),
    );
  }
}
