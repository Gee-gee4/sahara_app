import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/dummy_users.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class LoginPage extends StatelessWidget {
  final String username;
  const LoginPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
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
              final success = DummyUsers.login(username, enteredPin);

              if (success) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage(user: username)),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: ColorsUniversal.background,
                    title: Text('Login Failed'),
                    content: Text('Incorrect PIN. Try again.'),
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
