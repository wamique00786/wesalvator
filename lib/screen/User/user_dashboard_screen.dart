import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:wesalvator/provider/user_provider.dart';
import 'package:wesalvator/screen/User/Uwidget/image_preview.dart';
import 'package:wesalvator/screen/User/Uwidget/submit_button.dart';
import 'package:wesalvator/screen/User/map_section.dart';
import 'package:wesalvator/views/navbar.dart';

import '../../utils/snackbar_utils';

import 'Uservice/submit_report.dart';
import 'Uwidget/location_bar.dart';
import 'Uwidget/priority_buttons.dart';

class UserDashBoardScreen extends StatefulWidget {
  const UserDashBoardScreen({super.key});

  @override
  State<UserDashBoardScreen> createState() => _UserDashBoardScreenState();
}

class _UserDashBoardScreenState extends State<UserDashBoardScreen> {
  final List<XFile> _capturedImages = [];
  Position? currentPosition;
  String _selectedPriority = 'MEDIUM';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<bool> _fetchLocation() async {
    if (_isLoadingLocation) return false;

    setState(() => _isLoadingLocation = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        SnackbarUtils.showSnackbar(
          context: context,
          message: 'Please enable GPS to continue',
        );
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          SnackbarUtils.showSnackbar(
            context: context,
            message: 'Location permissions are required',
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        SnackbarUtils.showSnackbar(
          context: context,
          message:
              'Location access is permanently denied. Please enable in settings.',
        );
        return false;
      }

      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return true;
    } catch (e) {
      SnackbarUtils.showSnackbar(
        context: context,
        message: 'Error fetching location: ${e.toString().substring(0, 50)}',
      );
      return false;
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _pickImage() async {
    if (_capturedImages.length >= 5) {
      SnackbarUtils.showSnackbar(
        context: context,
        message: 'Maximum 5 images allowed',
      );
      return;
    }

    if (currentPosition == null) {
      SnackbarUtils.showSnackbar(
        context: context,
        message: 'Getting your location...',
      );
      final hasLocation = await _fetchLocation();
      if (!hasLocation) return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        setState(() => _capturedImages.add(photo));
      }
    } catch (e) {
      SnackbarUtils.showSnackbar(
        context: context,
        message: 'Could not capture image',
      );
    }
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _capturedImages.length && mounted) {
      setState(() => _capturedImages.removeAt(index));
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _capturedImages.clear();
        _descriptionController.clear();
        _selectedPriority = 'MEDIUM';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themedata = Theme.of(context);

    return Scaffold(
      drawer: NavBar(),
      appBar: AppBar(elevation: 3, title: Text("WeSalvator"), actions: []),
      body: Stack(
        children: [
          // Map section
          Positioned.fill(
            child:
                currentPosition != null
                    ? Mapsection(userPosition: currentPosition!)
                    : Container(color: Colors.grey[300]),
          ),

          // Bottom sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                color: themedata.scaffoldBackgroundColor,

                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location bar
                  LocationBar(
                    currentPosition: currentPosition,
                    onCameraPressed: _pickImage,
                  ),

                  // Priority Buttons
                  PriorityButtons(
                    selectedPriority: _selectedPriority,
                    onPrioritySelected: (priority) {
                      setState(() => _selectedPriority = priority);
                    },
                  ),

                  // Description Field
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Describe the situation...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),

                  // Image Preview
                  if (_capturedImages.isNotEmpty)
                    ImagePreview(
                      capturedImages: _capturedImages,
                      onRemoveImage: _removeImage,
                    ),

                  // Submit Button
                  SubmitButton(
                    isSubmitting: _isSubmitting,
                    onSubmit: _submitReport,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_capturedImages.isEmpty) {
      SnackbarUtils.showSnackbar(
        context: context,
        message: 'Please capture at least one image',
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      SnackbarUtils.showSnackbar(
        context: context,
        message: 'Please provide a description',
      );
      return;
    }

    if (currentPosition == null) {
      SnackbarUtils.showSnackbar(
        context: context,
        message: 'Getting your location...',
      );
      final hasLocation = await _fetchLocation();
      if (!hasLocation) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String? token = userProvider.authToken;

      if (token == null) {
        if (mounted) {}
        return;
      }

      final response = await ApiService.submitReport(
        token: token,
        description: description,
        priority: _selectedPriority,
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
        images: _capturedImages,
      );

      if (response.statusCode == 201) {
        SnackbarUtils.showSnackbar(
          context: context,
          message: 'Report submitted successfully',
        );
        _resetForm();
      } else {
        SnackbarUtils.showSnackbar(
          context: context,
          message: 'Failed to submit: ${response.statusCode}',
        );
      }
    } catch (e) {
      SnackbarUtils.showSnackbar(
        context: context,
        message: 'Error submitting report. Check your connection',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
