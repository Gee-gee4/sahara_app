import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sahara_app/utils/colors_universal.dart';

Future<void> showLoadingSpinner(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: _SpinnerDialog(),
    ),
  );
}

class _SpinnerDialog extends StatelessWidget {
  const _SpinnerDialog();

  @override
  Widget build(BuildContext context) {
    final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
    return SpinKitCircle(
      size: 70,
      duration: const Duration(milliseconds: 1000),
      itemBuilder: (context, index) {
        final color = colors[index % colors.length];
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
