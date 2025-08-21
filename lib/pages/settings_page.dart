import 'package:flutter/material.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/tap_card_page.dart';
import 'package:sahara_app/services/services/nfc/nfc_service_factory.dart';
import 'package:sahara_app/services/services/transactions/transaction_service_factory.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.user});
  final StaffListModel user;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Handle card actions (NFC operations)
  Future<void> _handleCardAction(TapCardAction action) async {
    if (action == TapCardAction.changePin) {
      // Use transaction service for PIN change
      await TransactionServiceFactory.executeAction(
        TransactionAction.changePin, 
        context, 
        widget.user
      );
    } else if (action == TapCardAction.format) {
      // Show confirmation for format
      final confirmed = await _showFormatConfirmation();
      if (confirmed) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TapCardPage(user: widget.user, action: action),
          ),
        );
      }
    } else {
      // For all other card actions (initialize, viewUID, cardDetails)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TapCardPage(user: widget.user, action: action),
        ),
      );
    }
  }

  // Handle transaction actions
  Future<void> _handleTransactionAction(String actionName) async {
    switch (actionName) {
      case 'Ministatement':
        // Navigate to TapCardPage for ministatement (requires NFC)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TapCardPage(
              user: widget.user, 
              action: TapCardAction.miniStatement
            ),
          ),
        );
        break;
        
      case 'Top Up':
        // Use transaction service for top-up
        await TransactionServiceFactory.executeAction(
          TransactionAction.topUp, 
          context, 
          widget.user
        );
        break;
        
      case 'Reverse Top Up':
        // Use transaction service for reverse top-up
        await TransactionServiceFactory.executeAction(
          TransactionAction.reverseTopUp, 
          context, 
          widget.user
        );
        break;
        
      case 'Re-Print Sale':
        // Use transaction service for reprint
        await TransactionServiceFactory.executeAction(
          TransactionAction.reprintReceipt, 
          context, 
          widget.user
        );
        break;
        
      case 'Reverse Sale':
        // Use transaction service for reverse sale
        await TransactionServiceFactory.executeAction(
          TransactionAction.reverseSale, 
          context, 
          widget.user
        );
        break;
        
      default:
        print('Unknown transaction action: $actionName');
    }
  }

  Future<bool> _showFormatConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Card Formating'),
        content: const Text(
          'Formating will erase all the user data on the card.\n\n'
          'Are you sure you wish to proceed with formatting card?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('PROCEED', style: TextStyle(color: ColorsUniversal.buttonsColor)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> cardItems = [
      'Card Details', 
      'Initialize Card', 
      'Format Card', 
      'Card UID', 
      'Change Card Pin'
    ];
    
    final List<String> transactionItems = [
      'Ministatement',
      'Top Up',
      'Reverse Top Up',
      'Re-Print Sale',
      'Reverse Sale',
    ];

    // Map card items to their corresponding TapCardActions
    final Map<String, TapCardAction> cardActionMap = {
      'Card Details': TapCardAction.cardDetails,
      'Initialize Card': TapCardAction.initialize,
      'Format Card': TapCardAction.format,
      'Card UID': TapCardAction.viewUID,
      'Change Card Pin': TapCardAction.changePin,
    };

    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView(
          children: [
            Text('Card', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            
            // Build card action tiles
            ...cardItems.map((item) => _buildListTile(
              item, 
              () => _handleCardAction(cardActionMap[item]!)
            )),
            
            const SizedBox(height: 20),
            Text('Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            
            // Build transaction action tiles
            ...transactionItems.map((item) => _buildListTile(
              item, 
              () => _handleTransactionAction(item)
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Text(title, style: TextStyle(fontSize: 16)),
        tileColor: Colors.brown[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}