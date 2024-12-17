import 'package:flutter/material.dart';

class MyButton extends StatefulWidget {
  final void Function()? onPressed;
  final String text;
  const MyButton({super.key, required this.onPressed, required this.text});

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // color: Colors.deepPurple[300],
          border: Border.all(color: Colors.blue.shade100, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(widget.text, style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 15, fontWeight: FontWeight.w600),),
        ),
      ),
    );
  }
}
