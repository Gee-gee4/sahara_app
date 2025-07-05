class PermissionsModel {
  PermissionsModel({required this.id, required this.permissionName});
  final int id;
  final PermissionsEnum permissionName;

  factory PermissionsModel.fromJson(Map<dynamic, dynamic> json) {
    return PermissionsModel(
      id: json['id'],
      permissionName: PermissionsEnum.values.byName(json['permissionName']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permissionName': permissionName.name,
    };
  }
}

enum PermissionsEnum {
  canSellTerminal,
  canTopupTerminal,
  canViewCustdataTerminal,
  canCloseDayTerminal,
  canReprintTicket,
  canReverseTransaction,
  canPrintMiniStatement,
  canChangeCardPin,
  canInitializeCard,
  canUnblockCard,
  canRedeem,
  canChangeStaffPin,
  canResetCardPin,
  canReverseTopup,
  canFormatCard,
  canCashExpress,
  canCardOnly,
  canCashLoyalty,
  canVoucherLoyalty,
  canReadUid,
  canChangeStaffPinWithOld,
  canRedeemPreviousMonth,
  canRedeemWithCode,
  canRedeemWithApprovals,
  canRedeemConversion,
  canInitializeTag,
  canFormatCorruptedCard,
  canAccessPosSettings,
  canAccessAutoSettings,
  canAccessSyncItems,
  canAccessCloudSettings,
}

// List<String> permissionsList2 = [
//    'CAN_SELL_TERMINAL',
//    'CAN_TOPUP_TERMINAL',
//   'CAN_VIEW_CUSTDATA_TERMINAL',
//   'CAN_CLOSE_DAY_TERMINAL',
//   'CAN_REPRINT_TICKET',
//   'CAN_REVERSE_TRANSACTION',
//   'CAN_PRINT_MINI_STATEMENT',
//   'CAN_CHANGE_CARD_PIN',
//   'CAN_INITIALIZE_CARD',
//   'CAN_UNBLOCK_CARD',
//   'CAN_REDEEM',
//   'CAN_CHANGE_STAFF_PIN',
//   'CAN_RESET_CARD_PIN',
//   'CAN_REVERSE_TOPUP',
//   'CAN_FORMAT_CARD',
//   'CAN_CASH_EXPRESS',
//   'CAN_CARD_ONLY',
//   'CAN_CASH_LOYALTY',
//   'CAN_VOUCHER_LOYALTY',
//   'CAN_READ_UID',
//   'CAN_CHANGE_STAFF_PIN_WITH_OLD',
//   'CAN_REDEEM_PREVIOUS_MONTH',
//   'CAN_REDEEM_WITH_CODE',
//   'CAN_REDEEM_WITH_APPROVALS',
//   'CAN_REDEEM_CONVERSION',
//   'CAN_INITIALIZE_TAG',
//   'CAN_FORMAT_CORRUPTED_CARD',
//   'CAN_ACCESS_POS_SETTINGS',
//   'CAN_ACCESS_AUTO_SETTINGS',
//   'CAN_ACCESS_SYNC_ITEMS',
//  'CAN_ACCESS_CLOUD_SETTINGS',
// ];
