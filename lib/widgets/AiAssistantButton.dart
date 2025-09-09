import 'package:flutter/material.dart';

class AiAssistantButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AiAssistantButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(4), // más delgado

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              colors: [Color(0xFF00F5A0), Color(0xFF00D9F5),Color(0xFF0083B0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.cyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Recibir asesoramiento",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: <Color>[
                          Color(0xFF00C9A7),
                          Color(0xFF00B4DB),
                          Color(0xFF1A2980)
                        ],
                      ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
