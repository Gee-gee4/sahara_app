import 'package:flutter/material.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/pages/top_up_page.dart';
import 'package:sahara_app/pages/top_up_receipt.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class ReverseTopUpPage extends TopUpPage {
  const ReverseTopUpPage({
    super.key,
    required super.user,
    required super.accountNo,
    required super.staff,
    required super.topUpData,
    required super.refNumber,
    required super.termNumber,
    required super.amount,
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
            title: "Reverse Top Up",
            refNumber: refNumber,
            termNumber: termNumber,
            amount: amount,
            topUpData: topUpData,
            accountNo: accountNo,
            staffName: staff.staffName,
            isReversal: true,
          ),
        ),
      ),
    );
  }
}
