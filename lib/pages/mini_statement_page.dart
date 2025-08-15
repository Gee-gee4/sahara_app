// lib/pages/mini_statement_page.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/ministatment_transaction_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class MiniStatementPage extends StatefulWidget {
  final StaffListModel user;
  final CustomerAccountDetailsModel accountDetails;
  final List<MinistatmentTransactionModel> transactions;

  const MiniStatementPage({
    super.key,
    required this.user,
    required this.accountDetails,
    required this.transactions,
  });

  @override
  State<MiniStatementPage> createState() => _MiniStatementPageState();
}

class _MiniStatementPageState extends State<MiniStatementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    if (widget.accountDetails.products.isNotEmpty)
                      _infoRow('Discount Voucher:', 'Available'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Transactions Header
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorsUniversal.buttonsColor,
              ),
            ),
            
            SizedBox(height: 8),
            
            // Transactions List
            if (widget.transactions.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              ...widget.transactions.map((transaction) => Card(
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
                          color: transaction.transactionType == 'Sale' 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          transaction.transactionType == 'Sale' 
                              ? Icons.add 
                              : Icons.remove,
                          color: transaction.transactionType == 'Sale' 
                              ? Colors.green 
                              : Colors.red,
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              transaction.channelName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDate(transaction.transactionDateCreated),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
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
                          color: transaction.transactionTotal >= 0 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
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