// tools/resize_splash.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final input = File('assets/img/LOGOV2.png');
  final bytes = await input.readAsBytes();
  final original = img.decodeImage(bytes)!;

  // Canvas cuadrado 480x480 con fondo crema #F2E8D5
  final canvas = img.Image(width: 480, height: 480);
  img.fill(canvas, color: img.ColorRgb8(242, 232, 213));

  // Escalar el logo para que quepa en 480x480 manteniendo proporción
  final scaled = img.copyResize(
    original,
    width: 400,
    height: (400 * original.height / original.width).round(),
    interpolation: img.Interpolation.linear,
  );

  // Centrar el logo en el canvas
  final offsetX = (480 - scaled.width) ~/ 2;
  final offsetY = (480 - scaled.height) ~/ 2;
  img.compositeImage(canvas, scaled, dstX: offsetX, dstY: offsetY);

  final output = File('assets/img/LOGOV2_splash.png');
  await output.writeAsBytes(img.encodePng(canvas));
 
}