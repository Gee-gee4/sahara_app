import 'package:flutter/material.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class AutomationSettingsPage extends StatefulWidget {
  const AutomationSettingsPage({super.key});

  @override
  State<AutomationSettingsPage> createState() => _AutomationSettingsPageState();
}

class _AutomationSettingsPageState extends State<AutomationSettingsPage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _stationNameController = TextEditingController();
  final TextEditingController _fetchingTimeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar('Automations Settings'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'URL',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorsUniversal.buttonsColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ColorsUniversal.buttonsColor,
                    width: 2,
                  ), // selected border
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stationNameController,
              decoration: InputDecoration(
                hintText: 'Station Name',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorsUniversal.buttonsColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ColorsUniversal.buttonsColor,
                    width: 2,
                  ), // selected border
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fetchingTimeController,
              decoration: InputDecoration(
                labelText: 'Fetching Time',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: TextStyle(color: ColorsUniversal.buttonsColor),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorsUniversal.buttonsColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ColorsUniversal.buttonsColor,
                    width: 2,
                  ), // selected border
                ),
              ),
              cursorColor: ColorsUniversal.buttonsColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: myButton(context, () {}, 'Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _stationNameController.dispose();
    _fetchingTimeController.dispose();
    super.dispose();
  }
}
