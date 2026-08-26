import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilefacenet.tflite',
        options: options,
      );
      _isInitialized = true;
      debugPrint('MobileFaceNet model loaded successfully.');
    } catch (e) {
      debugPrint('Error loading MobileFaceNet model: $e');
    }
  }

  Future<List<double>?> predict(File imageFile, Rect boundingBox) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
    }
    if (_interpreter == null) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final params = _CropParams(
        Uint8List.fromList(bytes),
        boundingBox.left.toInt(),
        boundingBox.top.toInt(),
        boundingBox.width.toInt(),
        boundingBox.height.toInt(),
      );

      final tensorImage = await compute(_preprocessImageInBackground, params);
      if (tensorImage == null) return null;

      final input = [tensorImage];
      final output = List.generate(1, (_) => List<double>.filled(192, 0.0));

      _interpreter!.run(input, output);

      final List<double> embedding = List<double>.from(output[0]);

      // Normalize L2
      double sum = 0.0;
      for (final val in embedding) {
        sum += val * val;
      }
      final double norm = math.sqrt(sum);
      if (norm > 0) {
        for (int i = 0; i < embedding.length; i++) {
          embedding[i] = embedding[i] / norm;
        }
      }

      return embedding;
    } catch (e) {
      debugPrint('Error predicting face embedding: $e');
      return null;
    }
  }

  double euclideanDistance(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return double.infinity;
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      final double diff = e1[i] - e2[i];
      sum += diff * diff;
    }
    return math.sqrt(sum);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

class _CropParams {
  final Uint8List bytes;
  final int x;
  final int y;
  final int w;
  final int h;
  _CropParams(this.bytes, this.x, this.y, this.w, this.h);
}

List<List<List<double>>>? _preprocessImageInBackground(_CropParams params) {
  final img.Image? decodedImage = img.decodeImage(params.bytes);
  if (decodedImage == null) return null;

  final int x = params.x.clamp(0, decodedImage.width - 1);
  final int y = params.y.clamp(0, decodedImage.height - 1);
  final int w = params.w.clamp(1, decodedImage.width - x);
  final int h = params.h.clamp(1, decodedImage.height - y);

  final img.Image cropped = img.copyCrop(
    decodedImage,
    x: x,
    y: y,
    width: w,
    height: h,
  );

  final img.Image resized = img.copyResize(cropped, width: 112, height: 112);

  return List.generate(
    112,
    (y) => List.generate(
      112,
      (x) {
        final pixel = resized.getPixel(x, y);
        return [
          (pixel.r - 127.5) / 127.5,
          (pixel.g - 127.5) / 127.5,
          (pixel.b - 127.5) / 127.5,
        ];
      },
    ),
  );
}
