import 'package:flutter/material.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_result.dart';
import 'package:sahara_app/pages/tap_card_page.dart';
import 'package:sahara_app/services/services/nfc/nfc_service_factory.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'transaction_base_service.dart';


class PinChangeService extends TransactionBaseService {
  static Future<TransactionResult> handleChangePin(
    BuildContext context, 
    StaffListModel user
  ) async {
    final pinData = await _showPinChangeDialog(context);
    
    if (pinData == null) {
      return TransactionResult.error('PIN change cancelled');
    }

    // Navigate to TapCardPage for NFC operation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TapCardPage(
          user: user,
          action: TapCardAction.changePin,
          extraData: pinData,
        ),
      ),
    );

    return TransactionResult.success('PIN change initiated');
  }

  static Future<Map<String, String>?> _showPinChangeDialog(BuildContext context) async {
    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final oldPinController = TextEditingController();
        final newPinController = TextEditingController();
        final confirmPinController = TextEditingController();

        return AlertDialog(
          title: const Text('Change Card Pin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                myPinTextField(
                  controller: oldPinController,
                  myLabelText: 'Current PIN',
                  myHintText: 'Enter current 4-digit PIN',
                ),
                const SizedBox(height: 5),
                myPinTextField(
                  controller: newPinController,
                  myLabelText: 'New PIN',
                  myHintText: 'Enter new 4-digit PIN',
                ),
                const SizedBox(height: 5),
                myPinTextField(
                  controller: confirmPinController,
                  myLabelText: 'Confirm New PIN',
                  myHintText: 'Re-enter new PIN',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
            TextButton(
              onPressed: () {
                String oldPin = oldPinController.text;
                String newPin = newPinController.text;
                String confirmPin = confirmPinController.text;

                if (oldPin.length != 4 || newPin.length != 4 || confirmPin.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All PINs must be exactly 4 digits'))
                  );
                  return;
                }

                if (newPin != confirmPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New PIN and confirmation do not match'))
                  );
                  return;
                }

                if (oldPin == newPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New PIN must be different from current PIN'))
                  );
                  return;
                }

                Navigator.of(context).pop({'oldPin': oldPin, 'newPin': newPin});
              },
              child: Text('SUBMIT', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }
}