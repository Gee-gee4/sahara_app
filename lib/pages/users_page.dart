import 'package:flutter/material.dart';
import 'package:sahara_app/pages/login_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: AppBar(
        title: Text('Terminal Users', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.people, size: 35, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select User',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Text('Janet', style: TextStyle(fontSize: 16)),
              tileColor: ColorsUniversal.fillWids,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(12),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
