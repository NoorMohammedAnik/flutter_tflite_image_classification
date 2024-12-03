import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'classification.dart';

class ImageClassifier {
  // Path to the TensorFlow Lite model
  final String _modelPath;

  // Path to the labels file
  final String _labelPath;

  // TensorFlow Lite Interpreter
  late Interpreter _interpreter;

  // List of labels
  late List<String> _labels;

  // Input image size
  final int _inputSize;


  //provide path of your model and labels file
  ImageClassifier({
    String modelPath = 'assets/model.tflite',
    String labelPath = 'assets/labels.txt',
    int inputSize = 224,
  })  : _modelPath = modelPath,
        _labelPath = labelPath,
        _inputSize = inputSize;

  // Initialize the model
  Future<void> initialize() async {
    // Load model
    _interpreter = await Interpreter.fromAsset(_modelPath);

    // Load labels
    _labels = await _loadLabels();
  }

  // Load labels from assets
  Future<List<String>> _loadLabels() async {
    final labelsData = await rootBundle.loadString(_labelPath);
    return labelsData.split('\n');
  }

  // Preprocess image for TensorFlow Lite
  Float32List _preprocessImage(File imageFile) {
    // Read the image file
    final bytes = imageFile.readAsBytesSync();

    // Decode the image
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize the image to the input size expected by the model
    img.Image resizedImage =
        img.copyResize(image, width: _inputSize, height: _inputSize);

    // Create a 3D tensor of floating-point values
    final Float32List inputTensor =
        Float32List(1 * _inputSize * _inputSize * 3);

    // Normalize pixel values and convert to tensor
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        // Use getPixelSafe to handle potential out-of-bounds access
        final pixel = resizedImage.getPixelSafe(x, y);

        // More robust RGB extraction
        // final r = (pixel && 0xFF0000) >> 16;
        // final g = (pixel & 0x00FF00) >> 8;
        // final b = pixel & 0x0000FF;

        // Extract RGB values using helper functions
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);

        // Normalize to [-1, 1]
        inputTensor[3 * (y * _inputSize + x)] = (r / 127.5) - 1.0;
        inputTensor[3 * (y * _inputSize + x) + 1] = (g / 127.5) - 1.0;
        inputTensor[3 * (y * _inputSize + x) + 2] = (b / 127.5) - 1.0;
      }
    }

    // Reshape the tensor to match model input
    return inputTensor;
  }

  // Classify image
  Future<List<Classification>> classifyImage(File imageFile) async {
    // Ensure model is initialized
    if (_interpreter == null) {
      await initialize();
    }

    // Preprocess the image
    final Float32List inputTensor = _preprocessImage(imageFile);

    // Prepare output tensor
    // Adjust the output size based on your specific model
    // here 2 is the size/number of the classes. Update it according to your model
    final output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    // Run inference
    _interpreter.run(
        inputTensor.reshape([1, _inputSize, _inputSize, 3]), output);

    // Process and sort results
    return _processClassifications(output[0]);
  }

  // Process classification results
  List<Classification> _processClassifications(List<double> rawOutput) {
    // Create a list of classifications with their confidence scores
    final classifications = rawOutput
        .asMap()
        .entries
        .map((entry) => Classification(
              label: _getLabel(entry.key),
              confidence: entry.value,
            ))
        .toList();

    // Sort by confidence in descending order
    classifications.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Return top 5 classifications
    return classifications.take(5).toList();
  }

  // Get label for a given index
  String _getLabel(int index) {
    // Ensure index is within labels range
    if (index >= 0 && index < _labels.length) {
      return _labels[index].trim();
    }
    return 'Unknown';
  }

  // Close the interpreter to free resources
  void close() {
    _interpreter.close();
  }
}
