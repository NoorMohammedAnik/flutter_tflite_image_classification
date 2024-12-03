import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'classifier/classification.dart';
import 'classifier/image_classifier.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImageClassifier _classifier = ImageClassifier();
  File? _image;



  String myLabel = "";
  double myConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _classifier.initialize();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);


      });

      try {
        final classifications = await _classifier.classifyImage(_image!);

        final highestConfidenceClassification = classifications.reduce(
            (current, next) =>
                current.confidence > next.confidence ? current : next);

        String getLabel = highestConfidenceClassification.label;
        double getConfidence = highestConfidenceClassification.confidence;



        if (getConfidence >= 0.70) {
          myLabel = getLabel;
          myConfidence = getConfidence;

        } else {
          myLabel = "Tupi Not Detected";
          myConfidence = getConfidence;
        }

        print('Label: ${highestConfidenceClassification.label}');
        print('Confidence: ${highestConfidenceClassification.confidence}');

        for (int i = 0; i < classifications.length; i++) {
          print("Model Data");
          print(classifications[i].label);
          print(classifications[i].confidence);
        }



        setState(() {
          // Update UI with new classification results
        });


      } catch (e) {

        print('Classification error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Image Classification',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display selected image
            _image != null
                ? Image.file(_image!, height: 300)
                : Text('No image selected'),


            SizedBox(
              height: 20,
            ),


            // Classification results

            SizedBox(
              height: 20,
            ),

            Text("Result"),
            Text(myLabel,style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),),

            SizedBox(
              height: 20,
            ),
            // Image selection buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  label: Text("Take Photo"),
                  icon: Icon(Icons.camera),

                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  label: Text('Choose from Gallery'),
                  icon: Icon(Icons.photo_camera_back),

                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classifier.close();
    super.dispose();
  }
}
