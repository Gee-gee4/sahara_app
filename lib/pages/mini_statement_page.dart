// lib/pages/mini_statement_page.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/printer/ministatement_printer_helper.dart';
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/ministatment_transaction_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class MiniStatementPage extends StatefulWidget {
  final StaffListModel user;
  final String? companyName;
  final String? channelName;
  final String refNumber;
  final String termNumber;
  final CustomerAccountDetailsModel accountDetails;
  final List<MinistatmentTransactionModel> transactions;

  const MiniStatementPage({
    super.key,
    required this.user,
    required this.accountDetails,
    required this.transactions,
    this.companyName,
    this.channelName,
    required this.refNumber,
    required this.termNumber,
  });

  @override
  State<MiniStatementPage> createState() => _MiniStatementPageState();
}

class _MiniStatementPageState extends State<MiniStatementPage> {
  Future<void> _printMiniStatement() async {
    await MiniStatementPrinterHelper.printMiniStatement(
      context: context,
      user: widget.user,
      accountDetails: widget.accountDetails,
      transactions: widget.transactions,
      refNumber: widget.refNumber,
      termNumber: widget.termNumber,
      companyName: widget.companyName,
      channelName: widget.channelName,
    );
   
  }

  void _showEndTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Exit Page'),
        content: const Text('You will lose all progress if you exit from this page', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
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
            child: Text('OK', style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor)),
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
          title: const Text('Mini Statement', style: TextStyle(color: Colors.white70)),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(widget.companyName ?? 'SAHARA FCS', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Center(child: Text(widget.channelName ?? 'Station')),
              SizedBox(height: 10),
              Center(child: Text('MINI STATEMENT')),
              Text('TERM# ${widget.termNumber}'),
              Text('REF# ${widget.refNumber}'),

              // Customer Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.accountDetails.customerName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorsUniversal.buttonsColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      _infoRow('Card:', widget.accountDetails.cardMask ?? 'N/A'),
                      _infoRow('Balance:', 'Ksh ${widget.accountDetails.customerAccountBalance.toStringAsFixed(2)}'),
                      _infoRow('Account Type:', widget.accountDetails.accountCreditTypeName),
                      if (widget.accountDetails.products.isNotEmpty) _infoRow('Discount Voucher:', 'Available'),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Transactions Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorsUniversal.buttonsColor),
                ),
              ),

              SizedBox(height: 8),

              // Transactions List
              if (widget.transactions.isEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('No transactions found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ),
                  ),
                ),
              ] else ...[
                ...widget.transactions
                    .map(
                      (transaction) => Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Transaction Icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: transaction.transactionType == 'Topup'
                                      ? ColorsUniversal.fillWids
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  transaction.transactionType == 'Topup' ? Icons.add : Icons.remove,
                                  color: transaction.transactionType == 'Topup'
                                      ? ColorsUniversal.buttonsColor
                                      : ColorsUniversal.background,
                                ),
                              ),

                              SizedBox(width: 12),

                              // Transaction Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transaction.transactionType,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      transaction.channelName,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                    Text(
                                      _formatDate(transaction.transactionDateCreated),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),

                              // Amount
                              Text(
                                '${transaction.transactionTotal >= 0 ? '+' : ''}${transaction.transactionTotal.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: transaction.transactionTotal >= 0 ? hexToColor('8f9c68') : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ],
              SizedBox(height: 10),
              Center(child: Text('APPROVAL')),
              Center(child: Text('Please confirm the accuracy of the')),
              Center(child: Text('statement and report any discrepancies')),
              Center(child: Text('immediately')),
              Divider(),
              Center(child: Text('Cardholder\'s signature')),
              Center(child: Text('THANK YOU')),
              Center(child: Text('powered by Saharafcs')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _printMiniStatement,
          backgroundColor: ColorsUniversal.buttonsColor,
          child: const Icon(Icons.print, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
