import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class LoginPage extends StatelessWidget {
  final String username;
  const LoginPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final TextEditingController _pinController = TextEditingController();

    return Scaffold(
      appBar: myAppBar('User'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            reusableTextField(
              'Enter Pin',
              null,
              true,
              _pinController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            myButton(context, () {
              final enteredPin = _pinController.text.trim();

              // ✅ Get stored staff list from Hive
              final box = Hive.box('staff_list');
              final storedList = box.get('staffList', defaultValue: []) as List;
              final List<StaffListModel> staffList = storedList
                  .map((e) => StaffListModel.fromJson(Map<String, dynamic>.from(e)))
                  .toList();

              // ✅ Find the staff by username and validate pin
              final matchedUser = staffList.firstWhere(
                (staff) =>
                    staff.staffName == username && staff.staffPin == enteredPin,
                orElse: () => StaffListModel(
                  // Provide a default invalid model
                  staffId: -1,
                  staffName: '',
                  staffPin: '',
                  staffPassword: '',
                  roleId: -1,
                  staffEmail: '',
                ),
              );

              // Check against the invalid model instead of null
              if (matchedUser.staffId != -1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage(user: username)),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: ColorsUniversal.background,
                    title: const Text('Login Failed'),
                    content: const Text('Incorrect PIN. Try again.'),
                    actions: [
                      TextButton(
                        child: Text(
                          'OK',
                          style: TextStyle(color: Colors.brown[800], fontSize: 17),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }
            }, 'LOGIN'),
          ],
        ),
      ),
    );
  }
}
