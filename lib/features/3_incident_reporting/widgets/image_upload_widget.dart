import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rescuetn/app/constants.dart';

/// A reusable widget for picking and displaying a single image.
///
/// This widget shows a placeholder and allows the user to tap it to select
/// an image from their gallery or camera. Once selected, it displays a preview
/// of the image and provides a callback with the selected image file.
class ImageUploadWidget extends StatefulWidget {
  final Function(File) onImageSelected;

  const ImageUploadWidget({
    super.key,
    required this.onImageSelected,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Compress image to save storage space
        maxWidth: 800,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _imageFile = imageFile;
        });
        widget.onImageSelected(imageFile);
      }
    } catch (e) {
      if (!mounted) return;
      // Handle potential errors, e.g., if the user denies permissions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(context),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _imageFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          child: Image.file(
            _imageFile!,
            fit: BoxFit.cover,
          ),
        )
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.textSecondary,
              size: 40,
            ),
            SizedBox(height: AppPadding.small),
            Text(
              'Add Photo Evidence',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
