import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/login_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('staff_list');
    final storedList = box.get('staffList', defaultValue: []) as List;

    final List<StaffListModel> staffList = storedList
        .map((e) => StaffListModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

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
                itemCount: staffList.length,
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: Text(staff.staffName, style: TextStyle(fontSize: 16)),
                      tileColor: Colors.brown[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginPage(username: staff.staffName),
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
