import 'package:flutter/material.dart';
import 'package:sahara_app/services/services/nfc/nfc_details_service.dart';
import 'package:sahara_app/services/services/nfc/nfc_pin_service.dart';
import 'package:sahara_app/services/services/nfc/nfc_sales_service.dart';
import 'package:sahara_app/services/services/nfc/nfc_statement_service.dart';
import 'package:sahara_app/services/services/nfc/nfc_topup_service.dart';
import 'package:sahara_app/services/services/nfc/nfc_uid_service.dart';
import '../../../models/staff_list_model.dart';
import '../../../models/nfc_result.dart';
import 'nfc_format_service.dart';
import 'nfc_initialize_service.dart';



enum TapCardAction {
  initialize,
  format,
  viewUID,
  changePin,
  cardDetails,
  cashCardSales,
  cardSales,
  miniStatement,
  topUp,
  reverseTopUp,
}

class NFCServiceFactory {
  static Future<NFCResult> executeAction(
    TapCardAction action,
    BuildContext context,
    StaffListModel user, {
    Map<String, dynamic>? extraData,
  }) async {
    switch (action) {
      case TapCardAction.format:
        return await NFCFormatService.formatCard(context, user);
        
      case TapCardAction.initialize:
        return await NFCInitializeService.initializeCard(context, user);
        
      case TapCardAction.viewUID:
        return await NFCUIDService.viewUID(context);
        
      case TapCardAction.changePin:
        return await NFCPinService.changeCardPIN(context, user, extraData);
        
      case TapCardAction.cardDetails:
        return await NFCDetailsService.handleCardDetails(context, user);
        
      case TapCardAction.cashCardSales:
        return await NFCSalesService.handleCardSale(context, user, extraData);
        
      case TapCardAction.cardSales:
        return await NFCSalesService.handleOnlyCardSales(context, user, extraData);

      case TapCardAction.topUp:
        return await NFCTopUpService.handleTopUp(context, user, extraData);

      case TapCardAction.miniStatement:
        return await NFCStatementService.handleMiniStatement(context, user);
        
      case TapCardAction.reverseTopUp:
        return NFCResult.error('Reverse top-up not implemented yet');
        
      }
  }

  static String getActionTitle(TapCardAction action) {
    switch (action) {
      case TapCardAction.initialize:
        return "Initialize card";
      case TapCardAction.format:
        return "Formatting card...";
      case TapCardAction.viewUID:
        return "Card UID";
      case TapCardAction.changePin:
        return "Change card PIN";
      case TapCardAction.cardDetails:
        return "Card details";
      case TapCardAction.cashCardSales:
        return "Scanning card for sale...";
      case TapCardAction.cardSales:
        return "Card sales";
      case TapCardAction.miniStatement:
        return "Ministatement";
      case TapCardAction.topUp:
        return "Top-up";
      case TapCardAction.reverseTopUp:
        return "Reverse top-up";
      }
  }
}