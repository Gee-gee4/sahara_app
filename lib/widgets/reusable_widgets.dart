import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';

Column reusableTextField(
  String text,
  IconData? icon,
  bool showText,
  TextEditingController controller, {
  Function()? toggleOnOff,
  TextInputType? keyboardType,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Padding(
      //   padding: const EdgeInsets.only(left: 15, bottom: 3),
      //   child: Text('$text:'),
      // ),
      TextField(
        controller: controller,
        obscureText: !showText,
        enableSuggestions: showText,
        cursorColor: hexToColor('903500'),
        style: const TextStyle(color: Colors.black),
        keyboardType:
            keyboardType ??
            (!showText ? TextInputType.visiblePassword : TextInputType.emailAddress),
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
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
                  icon: Icon(
                    showText ? Icons.visibility_off : Icons.visibility,
                    color: hexToColor('005954'),
                  ),
                ),
        ),
      ),
    ],
  );
}

//........................................................................................

SizedBox myButton(
  BuildContext context,
  Function onTap,
  String buttonText, {
  TextStyle buttonTextStyle = const TextStyle(color: Colors.white),
}) {
  return SizedBox(
    width: MediaQuery.of(context).size.width,
    // width: 150,
    height: 55.0,
    // decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsUniversal.buttonsColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(25),
        ),
      ),
      onPressed: () {
        onTap();
      },
      child: Text(buttonText, style: buttonTextStyle),
    ),
  );
}

//........................................................................................

AppBar myAppBar(String titleText) {
  return AppBar(
    title: Text(titleText, style: TextStyle(color: Colors.white)),
    centerTitle: true,
    backgroundColor: ColorsUniversal.appBarColor,
  );
}
