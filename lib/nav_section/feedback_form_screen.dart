import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wesalvator/services/email_service.dart';
import 'dart:io';

class FeedbackFormScreen extends StatefulWidget {
  const FeedbackFormScreen({super.key});

  @override
  _FeedbackFormScreenState createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<XFile?> _selectedImages = [];
  final int _maxImages = 5;

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      _showSnackBar("Maximum $_maxImages images allowed.");
      return;
    }

    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null) {
      int availableSlots = _maxImages - _selectedImages.length;
      if (pickedFiles.length > availableSlots) {
        _showSnackBar("You can only add $availableSlots more images.");
      }

      setState(() {
        _selectedImages.addAll(pickedFiles.take(availableSlots));
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // 🚀 Function to handle form submission
  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      String email = _emailController.text;
      String description = _descriptionController.text;

      List<File> imageFiles =
          _selectedImages.map((img) => File(img!.path)).toList();

      await EmailService.sendFeedbackEmail(
        name: name,
        email: email,
        description: description,
        images: imageFiles,
      );

      _showSnackBar("Feedback sent successfully!");

      // Clear the form
      _nameController.clear();
      _emailController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Feedback Form")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Name"),
                validator: (value) => value!.isEmpty ? "Enter your name" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) return "Enter your email";
                  if (!RegExp(
                    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                  ).hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: "Description"),
                maxLines: 4,
                validator:
                    (value) => value!.isEmpty ? "Enter a description" : null,
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: Icon(Icons.camera_alt),
                label: Text("Attach Media"),
              ),
              SizedBox(height: 10),
              _selectedImages.isNotEmpty
                  ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _selectedImages.map((img) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(img!.path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          );
                        }).toList(),
                  )
                  : Container(),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitFeedback,
                  child: Text("Submit Feedback"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
