// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:typed_data';

// FIXED NFC MODULE
class NfcModule {
  // Default keys (all FF)
  static final Uint8List _defaultKeyA = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);
  static final Uint8List _defaultKeyB = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);

  // POS system keys
  static final Uint8List _keyA = Uint8List.fromList([0x87, 0x65, 0x43, 0x21, 0x43, 0x21]);
  static final Uint8List _keyB = Uint8List.fromList([0x87, 0x65, 0x43, 0x21, 0x43, 0x21]); // FIXED: was _keyB = _keyB

  /// Authenticate with sector
  Future<bool> _authenticate({required int sectorIndex, required bool useDefaultKeys}) async {
    try {
      return await FlutterNfcKit.authenticateSector(
        sectorIndex,
        keyA: useDefaultKeys ? _defaultKeyA : _keyA,
        keyB: useDefaultKeys ? _defaultKeyB : _keyB,
      );
    } catch (e) {
      print("Authentication error: $e");
      rethrow;
    }
  }

  /// Write to a specific block in a sector
  Future<NfcMessage> writeSectorBlock({
    required int sectorIndex,
    required String data,
    required int blockSectorIndex,
    bool useDefaultKeys = true,
  }) async {
    try {
      // Calculate actual block index
      int blockIndex = sectorIndex * 4 + blockSectorIndex;

      print("Writing to sector $sectorIndex, block $blockSectorIndex (index $blockIndex)");
      print("Data: '$data'");

      // Authenticate
      final authenticated = await _authenticate(sectorIndex: sectorIndex, useDefaultKeys: useDefaultKeys);

      if (!authenticated) {
        return NfcMessage(
          status: NfcMessageStatus.authenticationError,
          data: 'Unable to authenticate sector $sectorIndex',
        );
      }

      // Prepare block data (16 bytes)
      List<int> blockRawData = [];
      List<int> rawData = data.codeUnits;

      if (rawData.length > 16) {
        blockRawData = rawData.sublist(0, 16);
      } else {
        blockRawData = [...rawData, ...List.filled(16 - rawData.length, 0x00)];
      }

      print("Raw data bytes: $blockRawData");

      await FlutterNfcKit.writeBlock(blockIndex, Uint8List.fromList(blockRawData));

      print("✅ Successfully wrote to block $blockIndex");
      return NfcMessage(status: NfcMessageStatus.success, data: "Write success");
    } catch (e) {
      print("❌ Error writing sector block: $e");
      return NfcMessage(status: NfcMessageStatus.failed, data: "Error writing block: $e");
    }
  }

  /// Read from a specific block in a sector
  Future<NfcMessage> readSectorBlock({
    required int sectorIndex,
    required int blockSectorIndex,
    bool useDefaultKeys = true,
  }) async {
    try {
      int blockIndex = sectorIndex * 4 + blockSectorIndex;

      // Authenticate
      final authenticated = await _authenticate(sectorIndex: sectorIndex, useDefaultKeys: useDefaultKeys);

      if (!authenticated) {
        return NfcMessage(
          status: NfcMessageStatus.authenticationError,
          data: 'Unable to authenticate sector $sectorIndex',
        );
      }

      final rawData = await FlutterNfcKit.readBlock(blockIndex);

      // Convert to string, filtering out null bytes and 0xFF
      final List<int> blockData = rawData.where((item) => item != 0 && item != 0xFF).toList();
      String dataString = String.fromCharCodes(blockData);

      return NfcMessage(status: NfcMessageStatus.success, data: dataString);
    } catch (e) {
      return NfcMessage(status: NfcMessageStatus.failed, data: "Error reading block: $e");
    }
  }

  /// Change sector keys from default to POS keys (or vice versa)
  Future<NfcMessage> changeKeys({required int sectorIndex, required bool fromDefault, bool authenticate = true}) async {
    try {
      if (authenticate) {
        final authenticated = await _authenticate(sectorIndex: sectorIndex, useDefaultKeys: fromDefault);

        if (!authenticated) {
          return NfcMessage(
            status: NfcMessageStatus.authenticationError,
            data: 'Unable to authenticate sector $sectorIndex',
          );
        }
      }

      // Create sector trailer with new keys
      final rawData = Uint8List.fromList([
        // Key A
        ...(fromDefault ? _keyA : _defaultKeyA),
        // Access bits (default)
        0xFF, 0x07, 0x80, 0x69,
        // Key B
        ...(fromDefault ? _keyB : _defaultKeyB),
      ]);

      // Write to sector trailer (block 3)
      int trailerBlockIndex = sectorIndex * 4 + 3;
      await FlutterNfcKit.writeBlock(trailerBlockIndex, rawData);

      print("✅ Changed keys for sector $sectorIndex");
      return NfcMessage(status: NfcMessageStatus.success, data: "Keys changed successfully");
    } catch (e) {
      print("❌ Error changing keys: $e");
      return NfcMessage(status: NfcMessageStatus.failed, data: "Error changing keys: $e");
    }
  }

  /// Format/Reset a sector - clears all data and resets keys to default
  Future<NfcMessage> formatSector({required int sectorIndex, bool useDefaultKeys = false}) async {
    try {
      // Authenticate with current keys
      final authenticated = await _authenticate(sectorIndex: sectorIndex, useDefaultKeys: useDefaultKeys);

      if (!authenticated) {
        return NfcMessage(
          status: NfcMessageStatus.authenticationError,
          data: 'Unable to authenticate sector $sectorIndex',
        );
      }

      // Clear all data blocks (0, 1, 2) with zeros
      final emptyBlock = Uint8List.fromList(List.filled(16, 0x00));

      for (int blockIndex = 0; blockIndex < 3; blockIndex++) {
        int actualBlockIndex = sectorIndex * 4 + blockIndex;
        await FlutterNfcKit.writeBlock(actualBlockIndex, emptyBlock);
        print("✅ Cleared block $actualBlockIndex");
      }

      // Reset sector trailer to default keys
      final defaultTrailer = Uint8List.fromList([
        // Key A: Default (FF FF FF FF FF FF)
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        // Access bits: Default
        0xFF, 0x07, 0x80, 0x69,
        // Key B: Default (FF FF FF FF FF FF)
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
      ]);

      int trailerBlockIndex = sectorIndex * 4 + 3;
      await FlutterNfcKit.writeBlock(trailerBlockIndex, defaultTrailer);

      print("✅ Reset keys for sector $sectorIndex to default");
      return NfcMessage(status: NfcMessageStatus.success, data: "Sector $sectorIndex formatted successfully");
    } catch (e) {
      print("❌ Error formatting sector: $e");
      return NfcMessage(status: NfcMessageStatus.failed, data: "Error formatting sector: $e");
    }
  }
}

// NFC MESSAGE CLASSES
class NfcMessage {
  NfcMessage({required this.status, required this.data});
  final NfcMessageStatus status;
  final String data;
}

Future<String> readCardUID() async {
  try {
    // Poll for card
    final tag = await FlutterNfcKit.poll();

    if (tag.type != NFCTagType.mifare_classic) {
      await FlutterNfcKit.finish();
      return "Error: Not a MIFARE Classic card";
    }

    // Get the UID from the tag
    String uid = tag.id;

    // Clean up
    await FlutterNfcKit.finish();

    // Return the UID as uppercase hex string
    return uid.toUpperCase();
  } catch (e) {
    await FlutterNfcKit.finish();
    return "Error reading UID: $e";
  }
}

enum NfcMessageStatus { authenticationError, success, failed }

// MAIN INITIALIZATION WIDGET
class NfcCardInit extends StatefulWidget {
  const NfcCardInit({super.key});

  @override
  State<NfcCardInit> createState() => _NfcCardInitState();
}

class _NfcCardInitState extends State<NfcCardInit> {
  String result = "Ready to initialize card";
  bool isProcessing = false;

  Future<void> initializeCard() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      result = "Starting initialization...";
    });

    final nfc = NfcModule();

    try {
      // Step 1: Prompt user for PIN
      String? pin = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Set Your PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter a 4-digit PIN for your card:'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(hintText: 'Enter 4-digit PIN', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('OK')),
            ],
          );
        },
      );

      if (pin == null || pin.length != 4) {
        setState(() {
          result = "❌ PIN entry cancelled or invalid";
          isProcessing = false;
        });
        return;
      }

      setState(() => result = "📱 Waiting for card...\nPlace your blank card on the phone");

      // Step 2: Poll for card
      final tag = await FlutterNfcKit.poll();
      if (tag.type != NFCTagType.mifare_classic) {
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      setState(() => result = "📝 Initializing card...");

      // Step 3: Write account number to Sector 1, Block 0
      const accountNo = '34904084'; // Hardcoded account as requested
      final result1 = await nfc.writeSectorBlock(
        sectorIndex: 1,
        blockSectorIndex: 0,
        data: '$accountNo;',
        useDefaultKeys: true,
      );

      if (result1.status != NfcMessageStatus.success) {
        throw Exception("Failed to write account number: ${result1.data}");
      }

      // Step 4: Write PIN to Sector 2, Block 0
      final result2 = await nfc.writeSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        data: '$pin;',
        useDefaultKeys: true,
      );

      if (result2.status != NfcMessageStatus.success) {
        throw Exception("Failed to write PIN: ${result2.data}");
      }

      // Step 5: Write max attempts (3) to Sector 2, Block 1
      final result3 = await nfc.writeSectorBlock(sectorIndex: 2, blockSectorIndex: 1, data: '3;', useDefaultKeys: true);

      if (result3.status != NfcMessageStatus.success) {
        throw Exception("Failed to write lock count: ${result3.data}");
      }

      // Step 6: Write initialization flag (1) to Sector 2, Block 2
      final result4 = await nfc.writeSectorBlock(sectorIndex: 2, blockSectorIndex: 2, data: '1;', useDefaultKeys: true);

      if (result4.status != NfcMessageStatus.success) {
        throw Exception("Failed to write init status: ${result4.data}");
      }

      // Step 7: Change keys for both sectors to POS keys
      final changeKey1 = await nfc.changeKeys(sectorIndex: 1, fromDefault: true);
      if (changeKey1.status != NfcMessageStatus.success) {
        throw Exception("Failed to change keys for sector 1: ${changeKey1.data}");
      }

      final changeKey2 = await nfc.changeKeys(sectorIndex: 2, fromDefault: true);
      if (changeKey2.status != NfcMessageStatus.success) {
        throw Exception("Failed to change keys for sector 2: ${changeKey2.data}");
      }

      // Step 8: Success!
      await FlutterNfcKit.finish();

      setState(() {
        result =
            "✅ Card initialized successfully!\n\n"
            "📊 Card Details:\n"
            "• Account: 34904084\n"
            "• PIN: $pin\n"
            "• Max attempts: 3\n"
            "• Status: Initialized\n\n"
            "🔑 Keys: POS system keys set\n"
            "🏪 Ready for POS use!";
        isProcessing = false;
      });
    } catch (e) {
      await FlutterNfcKit.finish();
      setState(() {
        result = "❌ Initialization failed:\n$e";
        isProcessing = false;
      });
    }
  }

  //FORMAT CARD
  Future<void> formatCard() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      result = "⚠️ FORMATTING CARD...\nThis will erase ALL data!";
    });

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('⚠️ Format Card'),
          content: const Text(
            'This will completely erase all data on the card and reset it to factory defaults.\n\n'
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('FORMAT'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      setState(() {
        result = "❌ Format cancelled";
        isProcessing = false;
      });
      return;
    }

    final nfc = NfcModule();

    try {
      setState(() => result = "📱 Waiting for card to format...\nPlace your card on the phone");

      // Poll for card
      final tag = await FlutterNfcKit.poll();
      if (tag.type != NFCTagType.mifare_classic) {
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      setState(() => result = "🗑️ Formatting card...\nErasing all data and resetting keys");

      // Try to format sectors 1 and 2 (first try with POS keys, then default keys)
      List<String> formatResults = [];

      for (int sector in [1, 2]) {
        bool formatted = false;

        // Try with POS keys first (if card was initialized)
        try {
          final result = await nfc.formatSector(sectorIndex: sector, useDefaultKeys: false);
          if (result.status == NfcMessageStatus.success) {
            formatResults.add("✅ Sector $sector: ${result.data}");
            formatted = true;
          }
        } catch (e) {
          print("POS key format failed for sector $sector: $e");
        }

        // If POS keys failed, try default keys
        if (!formatted) {
          try {
            final result = await nfc.formatSector(sectorIndex: sector, useDefaultKeys: true);
            if (result.status == NfcMessageStatus.success) {
              formatResults.add("✅ Sector $sector: ${result.data}");
              formatted = true;
            } else {
              formatResults.add("❌ Sector $sector: ${result.data}");
            }
          } catch (e) {
            formatResults.add("❌ Sector $sector: Error - $e");
          }
        }
      }

      await FlutterNfcKit.finish();

      // Show results
      String resultText = "🎉 Card Format Complete!\n\n";
      resultText += formatResults.join('\n');
      resultText += "\n\n🔓 All keys reset to default (FF FF FF FF FF FF)";
      resultText += "\n💳 Card ready for new assignment";

      setState(() {
        result = resultText;
        isProcessing = false;
      });
    } catch (e) {
      await FlutterNfcKit.finish();
      setState(() {
        result = "❌ Format failed:\n$e";
        isProcessing = false;
      });
    }
  }

  //CHANGE CARD PIN
  Future<void> changeCardPIN() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      result = "🔐 Preparing to change PIN...";
    });

    //  Show PIN change dialog
    Map<String, String>? pinData = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final oldPinController = TextEditingController();
        final newPinController = TextEditingController();
        final confirmPinController = TextEditingController();

        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('🔐 Change Card PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your current PIN and new PIN:'),
                const SizedBox(height: 16),

                // Old PIN field
                TextField(
                  controller: oldPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Current PIN',
                    hintText: 'Enter current 4-digit PIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),

                // New PIN field
                TextField(
                  controller: newPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'New PIN',
                    hintText: 'Enter new 4-digit PIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm new PIN field
                TextField(
                  controller: confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New PIN',
                    hintText: 'Re-enter new PIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                // Validate inputs
                String oldPin = oldPinController.text;
                String newPin = newPinController.text;
                String confirmPin = confirmPinController.text;

                if (oldPin.length != 4 || newPin.length != 4 || confirmPin.length != 4) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('All PINs must be exactly 4 digits')));
                  return;
                }

                if (newPin != confirmPin) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('New PIN and confirmation do not match')));
                  return;
                }

                if (oldPin == newPin) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('New PIN must be different from current PIN')));
                  return;
                }

                Navigator.of(context).pop({'oldPin': oldPin, 'newPin': newPin});
              },
              child: const Text('Change PIN'),
            ),
          ],
        );
      },
    );

    if (pinData == null) {
      setState(() {
        result = "❌ PIN change cancelled";
        isProcessing = false;
      });
      return;
    }

    final nfc = NfcModule();

    try {
      setState(() => result = "📱 Waiting for card...\nPlace your card on the phone");

      // Step 2: Poll for card
      final tag = await FlutterNfcKit.poll();
      if (tag.type != NFCTagType.mifare_classic) {
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      setState(() => result = "🔍 Verifying current PIN...");

      // Step 3: Read current PIN from Sector 2, Block 0 (using POS keys)
      final currentPinResult = await nfc.readSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        useDefaultKeys: false, // Use POS keys
      );

      if (currentPinResult.status != NfcMessageStatus.success) {
        throw Exception("Failed to read current PIN: ${currentPinResult.data}");
      }

      // Step 4: Verify the old PIN matches
      String storedPin = currentPinResult.data.replaceAll(';', '').trim();
      String enteredOldPin = pinData['oldPin']!;

      if (storedPin != enteredOldPin) {
        setState(() {
          result =
              "❌ PIN Change Failed!\n\n"
              "Incorrect current PIN entered.\n"
              "Stored PIN: '$storedPin'\n"
              "Entered PIN: '$enteredOldPin'\n\n"
              "Please try again with correct current PIN.";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      setState(() => result = "✅ Current PIN verified!\n🔄 Writing new PIN...");

      // Step 5: Write new PIN to Sector 2, Block 0
      final newPinResult = await nfc.writeSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        data: '${pinData['newPin']!};',
        useDefaultKeys: false, // Use POS keys
      );

      if (newPinResult.status != NfcMessageStatus.success) {
        throw Exception("Failed to write new PIN: ${newPinResult.data}");
      }

      // Step 6: Verify the new PIN was written correctly
      final verifyResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      String newStoredPin = verifyResult.data.replaceAll(';', '').trim();

      await FlutterNfcKit.finish();

      setState(() {
        result =
            "✅ PIN Changed Successfully!\n\n"
            "📊 PIN Change Details:\n"
            "• Old PIN: ${pinData['oldPin']!}\n"
            "• New PIN: ${pinData['newPin']!}\n"
            "• Verified: $newStoredPin\n\n"
            "🔒 Your card PIN has been updated!\n"
            "💡 Remember your new PIN for future use.";
        isProcessing = false;
      });
    } catch (e) {
      await FlutterNfcKit.finish();
      setState(() {
        result =
            "❌ PIN change failed:\n$e\n\n"
            "💡 Make sure:\n"
            "• Card is properly positioned\n"
            "• Card was previously initialized\n"
            "• Current PIN is correct";
        isProcessing = false;
      });
    }
  }

  Future<void> readCard() async {
    setState(() => result = "📖 Reading card...");

    final nfc = NfcModule();
    try {
      final tag = await FlutterNfcKit.poll();
      if (tag.type != NFCTagType.mifare_classic) {
        setState(() => result = "❌ Not a MIFARE Classic card");
        await FlutterNfcKit.finish();
        return;
      }

      // Read with POS keys
      final account = await nfc.readSectorBlock(sectorIndex: 1, blockSectorIndex: 0, useDefaultKeys: false);
      final pin = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);
      final attempts = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 1, useDefaultKeys: false);
      final status = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 2, useDefaultKeys: false);

      await FlutterNfcKit.finish();

      setState(() {
        result =
            "📖 Card Data:\n\n"
            "Account: ${account.data}\n"
            "PIN: ${pin.data}\n"
            "Attempts: ${attempts.data}\n"
            "Status: ${status.data}";
      });
    } catch (e) {
      await FlutterNfcKit.finish();
      setState(() => result = "❌ Read failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Management System'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: SingleChildScrollView(
                  child: Text(result, style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : initializeCard,
                icon: Icon(isProcessing ? Icons.hourglass_empty : Icons.credit_card, color: Colors.white),
                label: Text(
                  isProcessing ? 'Processing...' : 'Initialize Card',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isProcessing ? Colors.grey : Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : readCard,
                icon: const Icon(Icons.visibility, color: Colors.white),
                label: const Text('Read Card', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : formatCard,
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text('Format Card', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  String uid = await readCardUID();

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text('Card UID'),
                      content: Text(uid),
                      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                    ),
                  );
                },

                icon: const Icon(Icons.card_membership_rounded, color: Colors.white),
                label: const Text('Card Uid', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : changeCardPIN,
                icon: const Icon(Icons.pin, color: Colors.white),
                label: const Text('Change PIN', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
