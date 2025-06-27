import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/dummy_users.dart';
import 'package:sahara_app/pages/login_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final users = DummyUsers.getUsernames();

    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: AppBar(
        title: const Text('Terminal Users', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.people, color: Colors.white, size: 30),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select User', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: Text(users[index], style: TextStyle(fontSize: 16)),
                      tileColor: ColorsUniversal.fillWids,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginPage(username: users[index]),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
