import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:sahara_app/pages/products_page.dart';
import 'package:sahara_app/pages/settings_page.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});
  final String user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    Column(
      children: [
        Center(child: Text('No Products')),
        ElevatedButton(onPressed: () {}, child: Text('data'))
      ],
    ),
    ProductsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: AppBar(
        title: Text(widget.user, style: TextStyle(color: Colors.white70)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        iconTheme: IconThemeData(color: Colors.white70),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.card_membership_sharp)),
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
                          style: TextStyle(color: Colors.brown[800], fontSize: 17),
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
            icon: Icon(Icons.logout, color: Colors.white70),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: ColorsUniversal.fillWids,
        activeColor: ColorsUniversal.buttonsColor,
        color: Colors.white70,
        style: TabStyle.react, // or `fixed`, `flip`, etc.
        curveSize: 70,
        items: const [
          TabItem(icon: Icons.home, title: 'Home',),
          TabItem(icon: Icons.list_alt, title: 'Products'),
          TabItem(icon: Icons.settings, title: 'Settings'),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
