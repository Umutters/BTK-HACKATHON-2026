import 'package:flutter/material.dart';

/// FortuneFlow logosunu çizen widget.
/// [size] genişlik ve yüksekliği belirler (kare).
class FortuneFlowLogo extends StatelessWidget {
  final double size;

  const FortuneFlowLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
