// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcFunctions {
  ///K E Y S
  // Default keys (all FF)
  final Uint8List _defaultKeyA = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);
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

  /// W R I T E
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

  /// C H A N G E  K E Y S
  /// Change sector keys from default to POS keys (or vice versa)
  Future<NfcMessage> changeKeys({required int sectorIndex, required bool fromDefault}) async {
    try {
      print("Changing keys for sector $sectorIndex (fromDefault: $fromDefault)");

      // First authenticate with current keys
      final authenticated = await _authenticate(sectorIndex: sectorIndex, useDefaultKeys: fromDefault);

      if (!authenticated) {
        return NfcMessage(
          status: NfcMessageStatus.authenticationError,
          data: 'Unable to authenticate sector $sectorIndex for key change',
        );
      }

      // Calculate trailer block index (last block of sector)
      int trailerBlock = sectorIndex * 4 + 3;

      // Create new access conditions and keys
      List<int> newTrailerData = [
        // New Key A
        ...(fromDefault ? _keyA : _defaultKeyA),
        // Access bits (allowing read/write with Key A)
        0xFF, 0x07, 0x80, 0x69,
        // New Key B
        ...(fromDefault ? _keyB : _defaultKeyB),
      ];

      await FlutterNfcKit.writeBlock(trailerBlock, Uint8List.fromList(newTrailerData));

      print("✅ Successfully changed keys for sector $sectorIndex");
      return NfcMessage(status: NfcMessageStatus.success, data: "Key change success");
    } catch (e) {
      print("❌ Error changing keys: $e");
      return NfcMessage(status: NfcMessageStatus.failed, data: "Error changing keys: $e");
    }
  }

  /// F O R M A T
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

  /// R E A D  S E C T O R  B L O C K 
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
}

class NfcMessage {
  NfcMessage({required this.status, required this.data});
  final NfcMessageStatus status;
  final String data;
}

enum NfcMessageStatus { authenticationError, success, failed }
