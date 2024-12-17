import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintext;
  final bool obscuretext;
  final prefixicon;
  final double width;
  final double height;
  final int maxlines;
  // final TextInputType keyboard;
  MyTextField(
      {super.key,
      required this.controller,
      required this.hintext,
      required this.obscuretext,
      this.prefixicon,
      required this.width,
      required this.height,
      // required this.keyboard,
      required this.maxlines});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        controller: controller,
        obscureText: obscuretext,
        maxLines: maxlines,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(width: 2, color: Colors.blue.shade100),
          ),
          contentPadding: EdgeInsets.symmetric(
              horizontal: width, vertical: height), // Adjust these values.
          prefixIcon: prefixicon,
          fillColor: Theme.of(context).colorScheme.shadow,
          filled: true,
          hintText: hintext,
          // keyboardType: keyboard,
          // inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          hintStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
