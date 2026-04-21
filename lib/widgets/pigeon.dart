import 'package:flutter/material.dart';
import 'recolor_image.dart';

class PigeonWidget extends StatelessWidget {
  final int head;
  final int body;
  final int legs;
  final int color;
  final double scale;

  const PigeonWidget({
    super.key,
    required this.head,
    required this.body,
    required this.legs,
    required this.color,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final heads = [
      'assets/heads/Head10.png',
      'assets/heads/Head20.png',
      'assets/heads/Head30.png',
      'assets/heads/Head40.png',
    ];

    final torsos = [
      'assets/Torsos/Body10.png',
      'assets/Torsos/Body20.png',
    ];

    final legsList = [
      'assets/Legs/Feet10.png',
      'assets/Legs/Feet20.png',
      'assets/Legs/Feet30.png',
    ];

    final pigeonColor = Color(color);

    return SizedBox(
      height: 240 * scale,
      width: 220 * scale,
      child: Stack(
        children: [
          // Body
          Positioned(
            bottom: 9 * scale,
            left: 0,
            right: 0,
            child: Center(
              child: RecolorImage(
                assetPath: torsos[body % torsos.length],
                color: pigeonColor,
                height: 134 * scale,
              ),
            ),
          ),

          // Head
          Positioned(
            top: 6 * scale,
            left: 90 * scale,
            child: RecolorImage(
              assetPath: heads[head % heads.length],
              color: pigeonColor,
              height: 102 * scale,
            ),
          ),

          // Legs
          Positioned(
            bottom: 0.5 * scale,
            left: 0,
            right: 0.6 * scale,
            child: Center(
              child: RecolorImage(
                assetPath: legsList[legs % legsList.length],
                color: pigeonColor,
                height: 50 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}