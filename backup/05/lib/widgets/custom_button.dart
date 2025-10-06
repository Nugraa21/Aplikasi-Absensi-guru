import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool filled;
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: filled
          ? ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            )
          : ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.deepOrange,
              side: const BorderSide(color: Colors.deepOrange),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}
