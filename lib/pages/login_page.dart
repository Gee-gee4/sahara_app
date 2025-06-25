import 'package:flutter/material.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final TextEditingController _pinEditingController = TextEditingController();

    return Scaffold(
      appBar: myAppBar('User'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Janet',style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),),
            reusableTextField('Enter Pin', null, true, _pinEditingController),
            SizedBox(height: 12,),
            myButton(context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage())), 'LOGIN')
          ],
        ),
      ),
    );
  }
}
