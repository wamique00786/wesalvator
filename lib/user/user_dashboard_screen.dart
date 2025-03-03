import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:wesalvator/provider/user_provider.dart';
import 'package:wesalvator/services/chatbot.dart';
import 'package:wesalvator/services/compressImage.dart';
import 'package:wesalvator/views/navbar.dart';

class UserDashBoardScreen extends StatefulWidget {
  const UserDashBoardScreen({super.key});

  @override
  State<UserDashBoardScreen> createState() => _UserDashBoardScreenState();
}

class _UserDashBoardScreenState extends State<UserDashBoardScreen> {
  final List<XFile> _capturedImages = [];
  Position? _currentPosition;
  String _selectedPriority = 'MEDIUM';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  final _storage = const FlutterSecureStorage();
  final _imagePicker = ImagePicker();

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
        _showSnackbar('Please enable GPS to continue');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackbar('Location permissions are required');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackbar(
            'Location access is permanently denied. Please enable in settings.');
        return false;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return true;
    } catch (e) {
      _showSnackbar(
          'Error fetching location: ${e.toString().substring(0, 50)}');
      return false;
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _pickImage() async {
    if (_capturedImages.length >= 5) {
      _showSnackbar('Maximum 5 images allowed');
      return;
    }

    if (_currentPosition == null) {
      _showSnackbar('Getting your location...');
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
      _showSnackbar('Could not capture image');
    }
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _capturedImages.length) {
      setState(() => _capturedImages.removeAt(index));
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<String?> _getBaseUrl() async {
    return await _storage.read(key: "BASE_URL");
  }

  Future<void> _submitReport() async {
    if (_capturedImages.isEmpty) {
      _showSnackbar('Please capture at least one image');
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      _showSnackbar('Please provide a description');
      return;
    }

    if (_currentPosition == null) {
      _showSnackbar('Getting your location...');
      final hasLocation = await _fetchLocation();
      if (!hasLocation) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String? token = userProvider.authToken;
      final String? baseUrl = await _getBaseUrl();

      if (token == null || baseUrl == null) {
        _showSnackbar('Authentication failed. Please log in again');
        return;
      }

      final uri = Uri.parse('$baseUrl/user/');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Token $token'
        ..headers['Accept'] = 'application/json'
        ..fields['description'] = description
        ..fields['priority'] = _selectedPriority
        ..fields['latitude'] = _currentPosition!.latitude.toString()
        ..fields['longitude'] = _currentPosition!.longitude.toString();

      // Process images in parallel
      final compressedImages =
          await Future.wait(_capturedImages.map((image) async {
        final compressed = await compressImage(File(image.path));
        final mimeType = lookupMimeType(compressed.path) ?? 'image/jpeg';

        return {
          'path': compressed.path,
          'mimeType': mimeType,
        };
      }));

      for (final image in compressedImages) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          image['path']!,
          contentType: MediaType.parse(image['mimeType']!),
        ));
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        _showSnackbar('Report submitted successfully');
        _resetForm();
      } else {
        _showSnackbar('Failed to submit: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Error submitting report. Check your connection');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _capturedImages.clear();
      _descriptionController.clear();
      _selectedPriority = 'MEDIUM';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        title: const Text('Animal Rescue'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  _buildCameraSection(),
                  const SizedBox(height: 20),
                  if (_capturedImages.isNotEmpty) ...[
                    _buildImagePreviewList(),
                    const SizedBox(height: 24),
                  ],
                  _buildReportForm(),
                ],
              ),
              _buildchatbot(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Take Photos',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    if (_isLoadingLocation)
                      CircularProgressIndicator(
                        color: colorScheme.secondary,
                        strokeWidth: 2,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to take a photo (${_capturedImages.length}/5)',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _capturedImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_capturedImages[index].path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Report Details',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            _buildPriorityDropdown(),
            const SizedBox(height: 20),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedPriority,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            items: [
              DropdownMenuItem(
                value: 'HIGH',
                child: Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text('HIGH'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'MEDIUM',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text('MEDIUM'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'LOW',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text('LOW'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPriority = value);
              }
            },
            dropdownColor: colorScheme.surface,
            icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            hintText: 'Describe the situation...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitReport,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _isSubmitting
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'SUBMIT REPORT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildchatbot() {
    return FloatingActionButton.small(
      onPressed: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Chatbot()));
      },
      child: const Icon(Icons.live_help),
    );
  }
}
