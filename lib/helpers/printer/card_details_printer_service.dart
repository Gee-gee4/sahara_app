// lib/helpers/printer/card_details_printer_service.dart
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

class CardDetailsPrinterService {
  static final _instance = CardDetailsPrinterService._internal();
  factory CardDetailsPrinterService() => _instance;
  CardDetailsPrinterService._internal();

  final TelpoFlutterChannel _printer = TelpoFlutterChannel();

  Future<PrintResult> printCardDetails({
    required StaffListModel user,
    required CustomerAccountDetailsModel details,
    required String termNumber,
    String? companyName,
    String? channelName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool printPolicies = prefs.getBool('printPolicies') ?? false;
    final sheet = TelpoPrintSheet();

    // Header
    sheet.addElement(
      PrintData.text(companyName ?? 'SAHARA FCS', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(
      PrintData.text(channelName ?? 'CMB Station', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 4));

    // Document type
    sheet.addElement(
      PrintData.text('CARD DETAILS', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 2));

    // Terminal info
    sheet.addElement(PrintData.text('TERM# $termNumber', fontSize: PrintedFontSize.size24));

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // Customer basic information
    sheet.addElement(PrintData.text('CUSTOMER INFORMATION', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Customer: ${details.customerName}', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Card: ${details.mask ?? 'N/A'}', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Agreement: ${details.agreementDescription}', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(
      PrintData.text('Account Type: ${details.accountCreditTypeName}', fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(
      PrintData.text('Balance: ${details.customerAccountBalance.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(
      PrintData.text('Status: ${details.customerIsActive ? 'Active' : 'Inactive'}', fontSize: PrintedFontSize.size24),
    );

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    if (printPolicies) {
      // Account policies section
      sheet.addElement(PrintData.text('ACCOUNT POLICIES', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Start Time: ${details.startTime}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('End Time: ${details.endTime}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Frequency: ${details.frequecy.toString()}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(
        PrintData.text('Frequency Period: ${details.frequencyPeriod ?? 'null'}', fontSize: PrintedFontSize.size24),
      );

      sheet.addElement(PrintData.space(line: 2));

      // Fueling days section
      sheet.addElement(PrintData.text('Fueling Days', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));

      // Handle long fueling days text by splitting into lines
      final fuelingDays = details.dateToFuel;
      if (fuelingDays.length > 40) {
        final words = fuelingDays.split(' ');
        String currentLine = '';
        for (String word in words) {
          if ((currentLine + word).length > 40) {
            if (currentLine.isNotEmpty) {
              sheet.addElement(PrintData.text(currentLine.trim(), fontSize: PrintedFontSize.size24));
              sheet.addElement(PrintData.space(line: 1));
            }
            currentLine = word + ' ';
          } else {
            currentLine += word + ' ';
          }
        }
        if (currentLine.isNotEmpty) {
          sheet.addElement(PrintData.text(currentLine.trim(), fontSize: PrintedFontSize.size24));
        }
      } else {
        sheet.addElement(PrintData.text(fuelingDays, fontSize: PrintedFontSize.size24));
      }

      sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
      sheet.addElement(PrintData.space(line: 2));

      // Vehicles section
      if (details.customerVehicles.isNotEmpty) {
        sheet.addElement(PrintData.text('CUSTOMER VEHICLES', fontSize: PrintedFontSize.size24));
        sheet.addElement(PrintData.space(line: 2));

        for (final vehicle in details.customerVehicles) {
          sheet.addElement(PrintData.text('Reg No: ${vehicle.regNo}', fontSize: PrintedFontSize.size24));
          sheet.addElement(PrintData.space(line: 2));

          sheet.addElement(PrintData.text('Fuel Type: ${vehicle.fuelType}', fontSize: PrintedFontSize.size24));
          sheet.addElement(PrintData.space(line: 2));

          sheet.addElement(PrintData.text('Tank Capacity: ${vehicle.tankCapacity}', fontSize: PrintedFontSize.size24));
          sheet.addElement(PrintData.space(line: 2));

          sheet.addElement(PrintData.text('Start Time: ${vehicle.startTime}', fontSize: PrintedFontSize.size24));
          sheet.addElement(PrintData.space(line: 2));

          sheet.addElement(PrintData.text('End Time: ${vehicle.endTime}', fontSize: PrintedFontSize.size24));
          sheet.addElement(PrintData.space(line: 2));

          // handle fueling days text wrapping (like accountPolicies)
          final vehicleFuelDays = vehicle.fuelDays;
          sheet.addElement(PrintData.text('Fueling Days:', fontSize: PrintedFontSize.size24));
          if (vehicleFuelDays.length > 40) {
            final words = vehicleFuelDays.split(' ');
            String currentLine = '';
            for (String word in words) {
              if ((currentLine + word).length > 40) {
                if (currentLine.isNotEmpty) {
                  sheet.addElement(PrintData.text(currentLine.trim(), fontSize: PrintedFontSize.size24));
                  sheet.addElement(PrintData.space(line: 1));
                }
                currentLine = word + ' ';
              } else {
                currentLine += word + ' ';
              }
            }
            if (currentLine.isNotEmpty) {
              sheet.addElement(PrintData.text(currentLine.trim(), fontSize: PrintedFontSize.size24));
            }
          } else {
            sheet.addElement(PrintData.text(vehicleFuelDays, fontSize: PrintedFontSize.size24));
          }

          // 👇 ADD SEPARATOR HERE (inside loop, after each vehicle)
          sheet.addElement(PrintData.space(line: 2));
          sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
          sheet.addElement(PrintData.space(line: 2));
        }
      }
    }

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 2));

    // Date and staff
    sheet.addElement(
      PrintData.text('Date: ${DateTime.now().toString().substring(0, 19)}', fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Served By: ${user.staffName}', fontSize: PrintedFontSize.size24));

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 4));

    // Approval section
    sheet.addElement(PrintData.text('APPROVAL', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24));
    sheet.addElement(
      PrintData.text(
        'Customer acknowledges receipt of',
        alignment: PrintAlignment.center,
        fontSize: PrintedFontSize.size24,
      ),
    );
    sheet.addElement(
      PrintData.text(
        'card details and account information',
        alignment: PrintAlignment.center,
        fontSize: PrintedFontSize.size24,
      ),
    );
    sheet.addElement(
      PrintData.text('shown above.', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 4));

    sheet.addElement(
      PrintData.text('Cardholder Signature', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 4));

    // Footer
    sheet.addElement(PrintData.text('THANK YOU', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24));
    sheet.addElement(
      PrintData.text('CUSTOMER COPY', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(
      PrintData.text('Powered by Sahara FCS', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 20));

    return await _printer.print(sheet);
  }
}
