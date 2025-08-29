// lib/pages/operation_mode_settings_page.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/pages/pos_settings_helper.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'package:sahara_app/pages/pos_settings_form.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';

class OperationModeSettingsPage extends StatefulWidget {
  const OperationModeSettingsPage({super.key});

  @override
  State<OperationModeSettingsPage> createState() => _OperationModeSettingsPageState();
}

class _OperationModeSettingsPageState extends State<OperationModeSettingsPage> {
  OperationMode _currentMode = OperationMode.manual;
  OperationMode _newMode = OperationMode.manual;
  bool _isLoading = false;

  // Controllers for auto mode settings
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _stationNameController = TextEditingController();
  final TextEditingController _fetchingTimeController = TextEditingController();

  // Original values to track changes
  String _originalUrl = '';
  String _originalStationName = '';
  String _originalFetchingTime = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
    _loadAutoModeSettings();
    
    // Add listeners to text controllers
    _urlController.addListener(_onTextFieldChanged);
    _stationNameController.addListener(_onTextFieldChanged);
    _fetchingTimeController.addListener(_onTextFieldChanged);
  }

  void _onTextFieldChanged() {
    setState(() {}); // Trigger rebuild to update button state
  }

  Future<void> _loadCurrentMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString('operationMode') ?? 'manual';
    setState(() {
      _currentMode = modeString == 'auto' ? OperationMode.auto : OperationMode.manual;
      _newMode = _currentMode;
    });
  }

  Future<void> _loadAutoModeSettings() async {
    final settings = await PosSettingsHelper.loadSettings();
    setState(() {
      _originalUrl = settings['url'] ?? '';
      _originalStationName = settings['stationName'] ?? '';
      _originalFetchingTime = settings['fetchingTime'] ?? '';
      
      _urlController.text = _originalUrl;
      _stationNameController.text = _originalStationName;
      _fetchingTimeController.text = _originalFetchingTime;
    });
  }

  bool get _hasModeChanged => _currentMode != _newMode;
  
  bool get _hasSettingsChanged =>
      _urlController.text.trim() != _originalUrl ||
      _stationNameController.text.trim() != _originalStationName ||
      _fetchingTimeController.text.trim() != _originalFetchingTime;

  bool get _hasAnyChanges => _hasModeChanged || _hasSettingsChanged;

  String get _buttonText {
    if (!_hasAnyChanges) return 'BACK';
    if (_hasModeChanged) return 'APPLY MODE CHANGE';
    return 'SAVE SETTINGS';
  }

  Future<void> _handleSave() async {
    if (!_hasAnyChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Always save the settings if they changed
      if (_hasSettingsChanged || _newMode == OperationMode.auto) {
        await PosSettingsHelper.saveSettings(
          url: _urlController.text.trim(),
          stationName: _stationNameController.text.trim(),
          fetchingTime: _fetchingTimeController.text.trim(),
        );
      }

      if (_hasModeChanged) {
        // Mode changed - save mode and logout
        await SharedPrefsHelper.savePosSettings(
          mode: _newMode == OperationMode.auto ? 'auto' : 'manual',
          receiptCount: 1,
          printPolicies: false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully switched to ${_newMode == OperationMode.auto ? 'Auto' : 'Manual'} mode'),
            backgroundColor: hexToColor('8f9c68'),
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a moment for the snackbar to show
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to UsersPage (logout) and clear the entire navigation stack
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => UsersPage()),
            (route) => false,
          );
        }
      } else {
        // Only settings changed - save without logout
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: hexToColor('8f9c68'),
            duration: Duration(seconds: 2),
          ),
        );

        // Update original values to reflect saved state
        setState(() {
          _originalUrl = _urlController.text.trim();
          _originalStationName = _stationNameController.text.trim();
          _originalFetchingTime = _fetchingTimeController.text.trim();
        });

        // Wait a moment for the snackbar to show, then go back
        await Future.delayed(Duration(milliseconds: 1500));
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAutoModeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text('Auto Mode Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 12),

        TextField(
          controller: _urlController,
          cursorColor: ColorsUniversal.buttonsColor,
          decoration: InputDecoration(
            labelText: 'URL',
            labelStyle: TextStyle(color: ColorsUniversal.buttonsColor),
            hintText: 'Enter API URL',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
          ),
        ),
        SizedBox(height: 12),

        TextField(
          controller: _stationNameController,
          cursorColor: ColorsUniversal.buttonsColor,
          decoration: InputDecoration(
            labelText: 'Station Name',
            labelStyle: TextStyle(color: ColorsUniversal.buttonsColor),
            hintText: 'Enter station name',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
          ),
        ),
        SizedBox(height: 12),

        TextField(
          controller: _fetchingTimeController,
          cursorColor: ColorsUniversal.buttonsColor,
          decoration: InputDecoration(
            labelText: 'Fetching Time',
            labelStyle: TextStyle(color: ColorsUniversal.buttonsColor),
            hintText: 'Enter time in seconds',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: myAppBar('Advanced Settings'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Mode: ${_currentMode == OperationMode.manual ? 'Manual' : 'Auto'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: ColorsUniversal.buttonsColor),
            ),
            SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Operation Mode', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 12),

                    RadioListTile(
                      activeColor: ColorsUniversal.buttonsColor,
                      tileColor: Colors.brown[100],
                      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Manual')]),
                      value: OperationMode.manual,
                      groupValue: _newMode,
                      onChanged: (value) => setState(() => _newMode = value!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),

                    SizedBox(height: 12),

                    RadioListTile(
                      activeColor: ColorsUniversal.buttonsColor,
                      tileColor: Colors.brown[100],
                      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Auto')]),
                      value: OperationMode.auto,
                      groupValue: _newMode,
                      onChanged: (value) => setState(() => _newMode = value!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),

                    // Show auto mode settings when auto is selected OR when current mode is auto
                    if (_newMode == OperationMode.auto || _currentMode == OperationMode.auto) 
                      _buildAutoModeSettings(),

                    if (_hasAnyChanges) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColorsUniversal.fillWids,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ColorsUniversal.buttonsColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: ColorsUniversal.buttonsColor),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _hasModeChanged 
                                  ? 'Changing operation mode will require you to log in again for optimal performance.'
                                  : 'Settings changes will be saved and applied immediately.',
                                style: TextStyle(color: ColorsUniversal.buttonsColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 55.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsUniversal.buttonsColor,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('Saving...', style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : Text(_buttonText, style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.removeListener(_onTextFieldChanged);
    _stationNameController.removeListener(_onTextFieldChanged);
    _fetchingTimeController.removeListener(_onTextFieldChanged);
    
    _urlController.dispose();
    _stationNameController.dispose();
    _fetchingTimeController.dispose();
    super.dispose();
  }
}