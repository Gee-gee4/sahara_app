import 'package:flutter/material.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/utils/configs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoModeSettings extends StatefulWidget {
  final Color borderColor;
  final TextEditingController urlController;
  final TextEditingController stationNameController;
  final TextEditingController fetchingTimeController;
  
  const AutoModeSettings({
    Key? key, 
    required this.borderColor,
    required this.urlController,
    required this.stationNameController,
    required this.fetchingTimeController,
  }) : super(key: key);

  @override
  State<AutoModeSettings> createState() => _AutoModeSettingsState();
}

class _AutoModeSettingsState extends State<AutoModeSettings> {
  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved values into the parent's controllers
    widget.urlController.text = prefs.getString(urlKey) ?? '';
    widget.stationNameController.text = prefs.getString(stationNameKey) ?? '';
    widget.fetchingTimeController.text = prefs.getString(durationKey) ?? '';
    
    print('📖 Loaded settings:');
    print('  URL: ${widget.urlController.text}');
    print('  Station: ${widget.stationNameController.text}');
    print('  Duration: ${widget.fetchingTimeController.text}');
  }

  TextField myAutoTextField(
    String labelText,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      cursorColor: ColorsUniversal.buttonsColor,
      decoration: InputDecoration(
        labelText: labelText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: widget.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.borderColor, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      autofocus: autofocus,
      // ✅ REMOVED auto-save on change - now only saves when user clicks main button
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 14),
        myAutoTextField(
          'URL',
          widget.urlController,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        myAutoTextField(
          'Station',
          widget.stationNameController,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 12),
        myAutoTextField(
          'Fetching Time',
          widget.fetchingTimeController,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}