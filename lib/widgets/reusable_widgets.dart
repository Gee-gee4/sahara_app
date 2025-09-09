import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';

Column reusableTextField(
  String text,
  IconData? icon,
  bool showText,
  TextEditingController controller, {
  Function()? toggleOnOff,
  TextInputType? keyboardType,
  int? maxDigit,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Padding(
      //   padding: const EdgeInsets.only(left: 15, bottom: 3),
      //   child: Text('$text:'),
      // ),
      TextField(
        maxLength: maxDigit,
        controller: controller,
        obscureText: !showText,
        enableSuggestions: showText,
        cursorColor: hexToColor('903500'),
        style: const TextStyle(color: Colors.black),
        keyboardType: keyboardType ?? (!showText ? TextInputType.visiblePassword : TextInputType.emailAddress),
        inputFormatters: keyboardType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: Colors.teal[100]) : null,
          filled: true,
          fillColor: hexToColor('d3b49f'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: const BorderSide(width: 0, style: BorderStyle.none),
          ),
          hint: Text(text, style: TextStyle(color: Colors.black54)),
          suffixIcon: toggleOnOff == null
              ? null
              : IconButton(
                  onPressed: toggleOnOff,
                  icon: Icon(showText ? Icons.visibility_off : Icons.visibility, color: ColorsUniversal.buttonsColor),
                ),
        ),
      ),
    ],
  );
}

//........................................................................................

SizedBox myButton(
  BuildContext context,
  Function? onTap,
  String buttonText, {
  TextStyle buttonTextStyle = const TextStyle(color: Colors.white),
  bool isLoading = false,
  String loadingText = 'Syncing...',
}) {
  return SizedBox(
    width: MediaQuery.of(context).size.width,
    height: 55.0,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsUniversal.buttonsColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      onPressed: isLoading ? null : () => onTap?.call(),
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: SpinKitCircle(
                    size: 22,
                    duration: const Duration(milliseconds: 1000),
                    itemBuilder: (context, index) {
                      final colors = [
                        Colors.white, // make sure it fits the button's color
                        Colors.white54,
                      ];
                      final color = colors[index % colors.length];
                      return DecoratedBox(
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Text(loadingText, style: buttonTextStyle),
              ],
            )
          : Text(buttonText, style: buttonTextStyle),
    ),
  );
}

//........................................................................................

AppBar myAppBar(String titleText, {List<Widget>? actions}) {
  return AppBar(
    title: Text(titleText, style: TextStyle(color: Colors.white)),
    centerTitle: true,
    backgroundColor: ColorsUniversal.appBarColor,
    iconTheme: const IconThemeData(color: Colors.white),
    actions: actions,
    actionsPadding: EdgeInsets.symmetric(horizontal: 6),
  );
}

//..........................................................................................................
//CHANGE PIN TEXTFIELD
TextField myPinTextField({
  required TextEditingController controller,
  required String myLabelText,
  required String myHintText,
  TextInputType keyboardType = TextInputType.number, // Defaults to number
  bool obscureText = true,
  int maxLength = 4,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType, // Now customizable
    obscureText: obscureText,
    maxLength: maxLength,
    cursorColor: ColorsUniversal.buttonsColor,
    decoration: InputDecoration(
      labelText: myLabelText,
      labelStyle: TextStyle(color: Colors.brown[300]),
      hintText: myHintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
    ),
  );
}
//..............................................................................................................