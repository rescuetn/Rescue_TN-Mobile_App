import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/common_widgets/custom_button.dart';
import 'package:rescuetn/core/providers/locale_provider.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authStateChangesProvider).value;
    if (user != null) {
      _nameController.text = user.fullName ?? '';
      _phoneController.text = user.phoneNumber;
      _addressController.text = user.address ?? '';
      _ageController.text = user.age?.toString() ?? '';
      _imageUrl = user.profilePhotoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return _imageUrl;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');

      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) {
        throw Exception("editProfile.errorGeneric".tr(context));
      }

      // Upload image if selected
      String? photoUrl = _imageUrl;
      if (_selectedImage != null) {
        photoUrl = await _uploadImage(user.uid);
      }

      // Parse age
      int? age;
      if (_ageController.text.trim().isNotEmpty) {
        age = int.tryParse(_ageController.text.trim());
        if (age == null || age < 1 || age > 150) {
          throw Exception("editProfile.validationAge".tr(context));
        }
      }

      // Update user record
      final updatedUser = user.copyWith(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim().isNotEmpty 
            ? _addressController.text.trim() 
            : null,
        age: age,
        profilePhotoUrl: photoUrl,
      );

      await ref.read(databaseServiceProvider).updateUserRecord(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text("editProfile.successMessage".tr(context)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')), // Leaving error technical for now or make it generic
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text("editProfile.title".tr(context)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppPadding.large),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Photo Section
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_imageUrl != null
                                    ? NetworkImage(_imageUrl!)
                                    : null) as ImageProvider?,
                            child: _selectedImage == null && _imageUrl == null
                                ? Text(
                                    user.email[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppPadding.xLarge),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "editProfile.fullName".tr(context),
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "editProfile.validationName".tr(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppPadding.large),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: "editProfile.phoneNumber".tr(context),
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "editProfile.validationPhone".tr(context);
                        }
                        final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                        if (cleaned.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
                          return "editProfile.validationPhone".tr(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppPadding.large),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: "editProfile.address".tr(context),
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.streetAddress,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppPadding.large),

                    // Age
                    TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: "editProfile.age".tr(context),
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final age = int.tryParse(value);
                          if (age == null || age < 1 || age > 150) {
                            return "editProfile.validationAge".tr(context);
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppPadding.xLarge),

                    // Save Button
                    CustomButton(
                      text: "editProfile.saveChanges".tr(context),
                      onPressed: _saveProfile,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

