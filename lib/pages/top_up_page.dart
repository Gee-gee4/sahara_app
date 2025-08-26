import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/printer/topup_printer_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/pages/top_up_receipt.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class TopUpPage extends StatefulWidget {
  final StaffListModel user;
  final String accountNo;
  final StaffListModel staff;
  final Map<String, dynamic> topUpData;
  final String refNumber; 
  final String termNumber;
  final double amount; 
  final String? companyName;
  final String? channelName;

  const TopUpPage({
    super.key,
    required this.user,
    required this.accountNo,
    required this.staff,
    required this.topUpData, 
    required this.refNumber, 
    required this.termNumber,
    required this.amount,
    this.companyName,
    this.channelName,
  });

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  
  Future<void> _printTopUpReceipt() async {
    await TopUpPrinterHelper.printTopUpReceipt(
      context: context,
      user: widget.user,
      title: "Top Up",
      refNumber: widget.refNumber,
      termNumber: widget.termNumber,
      amount: widget.amount,
      topUpData: widget.topUpData,
      accountNo: widget.accountNo,
      staffName: widget.staff.staffName,
      isReversal: false,
      companyName: widget.companyName,
      channelName: widget.channelName,
    );
  }

  void _showEndTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Exit Page'),
        content: const Text(
          'You will lose all progress if you exit from this page',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
                (route) => false,
              );
            },
            child: Text(
              'OK',
              style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          _showEndTransactionDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Top Up', style: TextStyle(color: Colors.white70)),
          centerTitle: true,
          backgroundColor: ColorsUniversal.appBarColor,
          leading: IconButton(
            icon: const Icon(Icons.home, color: Colors.white70),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage(user: widget.user)),
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
              refNumber: widget.refNumber,
              termNumber: widget.termNumber,
              amount: widget.amount,
              topUpData: widget.topUpData,
              accountNo: widget.accountNo,
              staffName: widget.staff.staffName,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _printTopUpReceipt,
          backgroundColor: ColorsUniversal.buttonsColor,
          child: const Icon(Icons.print, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
