// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/services/services/nfc/nfc_service_factory.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class TapCardPage extends StatefulWidget {
  const TapCardPage({
    super.key,
    required this.user,
    required this.action,
    this.extraData,
    this.cartItems,
    this.selectedPaymentMode,
    this.topUpAmount,
  });
  
  final StaffListModel user;
  final TapCardAction action;
  final Map<String, String>? extraData;
  final List<CartItem>? cartItems;
  final String? selectedPaymentMode;
  final double? topUpAmount;

  @override
  State<TapCardPage> createState() => _TapCardPageState();
}

class _TapCardPageState extends State<TapCardPage> {
  bool isProcessing = false;
  String result = '';
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    result = NFCServiceFactory.getActionTitle(widget.action);
    
    // Auto-execute the action when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeAction();
    });
  }

  Future<void> _executeAction() async {
    if (isProcessing || !mounted || _isCancelled) return;
    
    setState(() => isProcessing = true);
    
    try {
      // Prepare extra data for the service
      final extraData = <String, dynamic>{
        'cartItems': widget.cartItems,
        'selectedPaymentMode': widget.selectedPaymentMode,
        'topUpAmount': widget.topUpAmount,
        // Add any existing extraData (like PIN data for changePin)
        if (widget.extraData != null) ...widget.extraData!,
      };

      print('🚀 Executing ${widget.action.name} with factory...');

      // Execute the action through the factory
      final result = await NFCServiceFactory.executeAction(
        widget.action,
        context,
        widget.user,
        extraData: extraData,
      );
      
      if (result.success) {
        print('✅ ${widget.action.name} completed: ${result.message}');
        // Most services handle their own navigation, so we don't need to do anything here
      } else {
        print('❌ ${widget.action.name} failed: ${result.error}');
        // Error handling is done within the services
      }
      
    } catch (e) {
      print('💥 Unexpected error in ${widget.action.name}: $e');
      
      // Show a generic error if something unexpected happens
      if (mounted && !_isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted && !_isCancelled) {
        setState(() => isProcessing = false);
      }
    }
  }

  // Handle cancellation and cleanup
  void cancelOperation() {
    _isCancelled = true;
    if (mounted) {
      setState(() => isProcessing = false);
    }
  }

  // Handle back button press
  Future<bool> handleBackPress() async {
    if (isProcessing) {
      // Cancel any ongoing operation
      cancelOperation();
      try {
        await FlutterNfcKit.finish(); // Stop NFC
      } catch (e) {
        // NFC might not be active
      }
      return true; // Allow pop
    }
    return true; // Allow normal pop
  }

  @override
  void dispose() {
    // Clean up when page is disposed
    _isCancelled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop && isProcessing) {
          // If the pop already happened and we were processing, clean up
          await handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: ColorsUniversal.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  'Hold the Card/Tag at the \nreader and keep it there',
                  style: TextStyle(
                    fontSize: 25, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.black54
                  ),
                ),
                RotatedBox(
                  quarterTurns: -2,
                  child: Image.asset(
                    'assets/images/nfc_scan.png', 
                    fit: BoxFit.fitHeight, 
                    height: 300
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        // Show current action status
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  result,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic, 
                                    fontSize: 16, 
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isProcessing) ...[
                                  SizedBox(height: 20),
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        ColorsUniversal.buttonsColor
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      color: ColorsUniversal.buttonsColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 55.0,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorsUniversal.buttonsColor,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: (isProcessing || _isCancelled) ? null : () {
                              _executeAction();
                            },
                            child: Text(
                              isProcessing ? 'PROCESSING...' : 'TAP AGAIN !',
                              style: TextStyle(
                                fontSize: 25, 
                                color: (isProcessing || _isCancelled) 
                                  ? Colors.white38 
                                  : Colors.white70
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}