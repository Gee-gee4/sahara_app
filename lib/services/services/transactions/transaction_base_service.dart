import 'package:flutter/material.dart';
import 'package:sahara_app/utils/colors_universal.dart';

abstract class TransactionBaseService {
  // Common success dialog
  static Future<void> showSuccessDialog(
    BuildContext context, 
    String title, 
    String message, {
    Map<String, dynamic>? details,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              if (details != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100], 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    children: details.entries.map((entry) => 
                      _infoRow(entry.key, entry.value.toString())
                    ).toList(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
          ],
        );
      },
    );
  }

  // Common confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    String confirmText, {
    Color confirmColor = Colors.red,
    String cancelText = 'Cancel',
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 48),
              SizedBox(height: 16),
              Text(message),
              SizedBox(height: 16),
              Text(
                'This action cannot be undone.', 
                style: TextStyle(color: Colors.red, fontSize: 12)
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText, style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText,
                style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Common input dialog - FIXED: Removed dead code
  static Future<String?> showInputDialog(
    BuildContext context,
    String title,
    String labelText,
    String hintText, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLength = 50,
    String? Function(String)? validator,
  }) async {
    final controller = TextEditingController();
    String? errorMessage;

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    obscureText: obscureText,
                    maxLength: maxLength,
                    cursorColor: ColorsUniversal.buttonsColor,
                    decoration: InputDecoration(
                      labelText: labelText,
                      labelStyle: TextStyle(color: ColorsUniversal.buttonsColor),
                      hintText: hintText,
                      errorText: errorMessage,
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsUniversal.buttonsColor)
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
                ),
                TextButton(
                  onPressed: () {
                    final input = controller.text.trim();
                    
                    if (validator != null) {
                      final error = validator(input);
                      if (error != null) {
                        setState(() => errorMessage = error);
                        return;
                      }
                    }
                    
                    Navigator.of(context).pop(input);
                  },
                  child: Text('SUBMIT', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper widget for info rows
  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontFamily: 'Courier')),
        ],
      ),
    );
  }
}