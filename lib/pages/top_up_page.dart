import 'package:flutter/material.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/pages/top_up_receipt.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class TopUpPage extends StatelessWidget {
  final StaffListModel user;
  final String accountNo;
  final StaffListModel staff;
  final Map<String, dynamic> topUpData;
  final String refNumber; 
  final String termNumber;
  final double amount; 

  const TopUpPage({
    super.key,
    required this.user,
    required this.accountNo,
    required this.staff,
    required this.topUpData, 
    required this.refNumber, 
    required this.termNumber,
    required this.amount, 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up', style: TextStyle(color: Colors.white70)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white70),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage(user: user)),
              (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: TopUpReceipt(
            title: "Top Up",
            refNumber: refNumber,
            termNumber: termNumber,
            amount: amount,
            topUpData: topUpData,
            accountNo: accountNo,
            staffName: staff.staffName,
          ),
        ),
      ),
    );
  }
}
