import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;


class RecolorImage extends StatefulWidget {
  final String assetPath;
  final Color color;
  final double? width;
  final double? height;
  final double threshold;

  const RecolorImage({
    super.key,
    required this.assetPath,
    required this.color,
    this.width,
    this.height,
    this.threshold = 0.1,
  });

  @override
  State<RecolorImage> createState() => _RecolorImageState();
}

class _RecolorImageState extends State<RecolorImage> {
  static ui.FragmentProgram? _program;
  static final Map<String, ui.Image> _imageCache = {};

  ui.FragmentShader? _shader;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _initShader();
    _loadImage();
  }

  void _initShader() async {
    _program ??=
        await ui.FragmentProgram.fromAsset('shaders/recolor.frag');

    if (mounted) {
      setState(() {
        _shader = _program!.fragmentShader();
      });
    }
  }

  void _loadImage() async {
    if (_imageCache.containsKey(widget.assetPath)) {
      _image = _imageCache[widget.assetPath];
      if (mounted) setState(() {});
      return;
    }

    final data = await rootBundle.load(widget.assetPath);
    final codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();

    _imageCache[widget.assetPath] = frame.image;

    if (mounted) {
      setState(() {
        _image = frame.image;
      });
    }
  }

  @override
  void didUpdateWidget(covariant RecolorImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.assetPath != widget.assetPath) {
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null || _shader == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    }

    final c = widget.color;

    _shader!
      ..setFloat(0, c.red / 255)
      ..setFloat(1, c.green / 255)
      ..setFloat(2, c.blue / 255)
      ..setFloat(3, widget.threshold)
      ..setFloat(4, _image!.width.toDouble())
      ..setFloat(5, _image!.height.toDouble())
      ..setImageSampler(0, _image!);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RepaintBoundary(
        child: FittedBox(
          fit: BoxFit.contain,
          child: CustomPaint(
            size: Size(
              _image!.width.toDouble(),
              _image!.height.toDouble(),
            ),
            painter: _Painter(_shader!),
          ),
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final ui.FragmentShader shader;

  _Painter(this.shader);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}