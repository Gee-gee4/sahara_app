// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:sahara_app/pages/pos_settings_form.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
// We'll create this for getDeviceId()

class PosSettingsPage extends StatelessWidget {
  const PosSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: myAppBar('POS Settings'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: PosSettingsForm(showSyncButton: true), // ⬅ Only save locally
      ),
    );
  }
}

