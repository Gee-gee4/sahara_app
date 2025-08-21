import 'package:flutter/material.dart';

class TopUpReceipt extends StatelessWidget {
  final String title;
  final String refNumber;
  final String termNumber;
  final double amount;
  final Map<String, dynamic> topUpData;
  final String accountNo;
  final String staffName;
  final bool isReversal;

  const TopUpReceipt({
    super.key,
    required this.title,
    required this.refNumber,
    required this.termNumber,
    required this.amount,
    required this.topUpData,
    required this.accountNo,
    required this.staffName,
    this.isReversal = false,
  });

  @override
  Widget build(BuildContext context) {
    final customerAccount = topUpData['customerAccount'] ?? {};
    final customer = customerAccount['customer'] ?? {};
    final customerName = customer['customerName'] ?? 'N/A';
    final accountBalance = customerAccount['accountBalance']?.toString() ?? 'N/A';
    final accountMask = customerAccount['accountMask'] ?? 'N/A';
    final agreementTypeName = customerAccount['agreementTypeName'] ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: const Text('SaharaFCS')),
        Center(child: const Text('Station')),
        Center(child: Text(title)), // Top Up or Reverse Top Up
        Text('TERM# $termNumber'),
        Text('REF# $refNumber'),
        const Divider(),
        if (isReversal)
          _infoRow('Reversed Amount', '-Ksh ${amount.toStringAsFixed(2)}')
        else
          _infoRow('Top Up', 'Ksh ${amount.toStringAsFixed(2)}'),
        _infoRow('Card Balance', 'Ksh $accountBalance'),
        const Divider(),
        _infoRow('Customer', customerName),
        _infoRow('Account', accountNo),
        _infoRow('Card', accountMask),
        _infoRow('Account Type', agreementTypeName),
        const Divider(),
        _infoRow('Date', DateTime.now().toString().substring(0, 19)),
        _infoRow('Served By', staffName),
        const Divider(),
        const Center(child: Text("Cardholder's signature")),
        const Center(child: Text("THANK YOU")),
        const Center(child: Text("powered by Saharafcs")),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
