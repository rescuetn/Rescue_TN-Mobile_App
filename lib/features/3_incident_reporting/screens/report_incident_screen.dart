import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/app/districts.dart';
import 'package:rescuetn/common_widgets/custom_button.dart';
import 'package:rescuetn/models/incident_model.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rescuetn/features/3_incident_reporting/providers/incident_provider.dart';
import 'package:rescuetn/core/providers/locale_provider.dart';
import 'package:rescuetn/core/utils/translation_helper.dart';

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  ConsumerState<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();

  IncidentType? _selectedType;
  Severity? _selectedSeverity;
  String? _selectedDistrict;
  final List<File> _pickedImages = [];
  final List<String> _audioRecordings = [];
  Position? _currentPosition;
  String _locationMessage = 'Fetching location...';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _animationController.forward();
    _handleLocationInitialization();
  }

  Future<void> _handleLocationInitialization() async {
    // Delay slightly to ensure context is valid if we need to show messages immediately, 
    // though _getCurrentLocation mainly sets state.
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _locationMessage = 'Location services are disabled.');
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _locationMessage = 'Location permissions are denied.');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() =>
        _locationMessage = 'Location permissions are permanently denied.');
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          // 'incident.locationLoading'.tr(context); // We might keep coordinate display as is or format it
          '${"incident.locationLoading".tr(context)}: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationMessage = 'Could not get location.');
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile =
      await _imagePicker.pickImage(source: source, imageQuality: 50);
      if (pickedFile != null && mounted) {
        setState(() {
          _pickedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      _showSnackBar(
        message: 'Failed to pick image: $e',
        icon: Icons.error_outline,
        backgroundColor: AppColors.error,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        if (mounted) {
          setState(() {
            _isRecording = true;
            _recordingDuration = Duration.zero;
          });
        }

        _updateRecordingDuration();
      } else {
        _showSnackBar(
          message: 'Microphone permission is required',
          icon: Icons.error_outline,
          backgroundColor: AppColors.error,
        );
      }
    } catch (e) {
      _showSnackBar(
        message: 'Failed to start recording: $e',
        icon: Icons.error_outline,
        backgroundColor: AppColors.error,
      );
    }
  }

  void _updateRecordingDuration() {
    Future.doWhile(() async {
      if (!_isRecording) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      }
      return _isRecording;
    });
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null && mounted) {
        setState(() {
          _audioRecordings.add(path);
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });
        _showSnackBar(
          message: 'Voice recording saved',
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.shade600,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });
      }
      _showSnackBar(
        message: 'Failed to stop recording: $e',
        icon: Icons.error_outline,
        backgroundColor: AppColors.error,
      );
    }
  }

  void _removeAudioRecording(int index) {
    setState(() {
      _audioRecordings.removeAt(index);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // --- UPDATED _submitReport METHOD ---
  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null) {
        _showSnackBar(
          message: "incident.locationLoading".tr(context),
          icon: Icons.error_outline,
          backgroundColor: AppColors.error,
        );
        return;
      }

      // Call the notifier to handle all the submission logic.
      // The UI doesn't need to know the details; it just triggers the action.
      await ref.read(reportIncidentProvider.notifier).submitIncident(
        type: _selectedType!,
        description: _descriptionController.text.trim(),
        severity: _selectedSeverity!,
        position: _currentPosition!,
        district: _selectedDistrict,
        images: _pickedImages,
        audioPaths: _audioRecordings,
      );
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.accent.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_photo_alternate,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "incident.evidence".tr(context),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildImageSourceOption(
                icon: Icons.photo_library_rounded,
                title: "incident.gallery".tr(context),
                subtitle: 'Choose from existing photos', // Missed this key? I'll leave as is or add later.
                // I will add "incident.gallerySubtitle" later. For now just title.
                gradient: [Colors.purple.shade400, Colors.purple.shade600],
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              _buildImageSourceOption(
                icon: Icons.camera_alt_rounded,
                title: "incident.camera".tr(context),
                subtitle: 'Take a new photo',
                gradient: [Colors.blue.shade400, Colors.blue.shade600],
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.low:
        return Colors.blue;
      case Severity.medium:
        return Colors.green;
      case Severity.high:
        return Colors.orange;
      case Severity.critical:
        return Colors.red;
    }
  }

  IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.fire:
        return Icons.local_fire_department_rounded;
      case IncidentType.flood:
        return Icons.water_damage_rounded;
      case IncidentType.earthquake:
        return Icons.vibration;
      case IncidentType.accident:
        return Icons.car_crash_rounded;
      case IncidentType.medical:
        return Icons.medical_services_rounded;
      case IncidentType.other:
        return Icons.report_problem_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Watch the provider state for UI updates (isLoading, progress, etc.)
    final reportState = ref.watch(reportIncidentProvider);

    // Listen for state changes to show messages and navigate
    ref.listen<ReportIncidentState>(reportIncidentProvider, (previous, next) {
      if (next.isSuccess) {
        _showSnackBar(
          message: "incident.submitSuccess".tr(context),
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.shade600,
        );
        // Reset provider state and navigate back
        Future.microtask(() {
          ref.read(reportIncidentProvider.notifier).reset();
          if (context.mounted) context.pop();
        });
      } else if (next.error != null && previous?.error != next.error) {
        _showSnackBar(
          message: 'Failed to report incident: ${next.error}',
          icon: Icons.error_outline,
          backgroundColor: AppColors.error,
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade700,
              Colors.red.shade600,
              Colors.red.shade500,
              AppColors.background,
            ],
            stops: const [0.0, 0.15, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Hero(
                      tag: 'back_button',
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                            onPressed: () => context.go('/home'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "incident.title".tr(context),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "incident.subtitle".tr(context),
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emergency_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Enhanced Alert Banner
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.red.shade50,
                                      Colors.orange.shade50,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.shade100.withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.emergency_rounded,
                                        color: Colors.red.shade700,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "incident.bannerTitle".tr(context),
                                            style: textTheme.bodyLarge?.copyWith(
                                              color: Colors.red.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "incident.bannerSubtitle".tr(context),
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: Colors.red.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Incident Details Section
                              _buildEnhancedSectionHeader(
                                icon: Icons.description_rounded,
                                title: "incident.details".tr(context),
                                subtitle: "incident.detailsSub".tr(context),
                                gradient: [Colors.blue.shade400, Colors.blue.shade600],
                              ),
                              const SizedBox(height: 20),

                              // Incident Type
                              _buildEnhancedDropdownField<IncidentType>(
                                label: "incident.type".tr(context),
                                value: _selectedType,
                                items: IncidentType.values,
                                icon: Icons.category_rounded,
                                onChanged: (value) => setState(() => _selectedType = value),
                                itemBuilder: (type) => Row(
                                  children: [
                                    Icon(_getIncidentIcon(type), size: 20),
                                    const SizedBox(width: 12),
                                    Text(TranslationHelper.translateIncidentType(context, type)),
                                  ],
                                ),
                                validator: (value) =>
                                value == null ? "incident.selectType".tr(context) : null,
                              ),
                              const SizedBox(height: 20),

                              // Description
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.textPrimary.withValues(alpha: 0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _descriptionController,
                                  decoration: InputDecoration(
                                    labelText: "incident.description".tr(context),
                                    hintText: "incident.descriptionHint".tr(context),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Icon(Icons.edit_note_rounded,
                                          color: AppColors.primary),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: AppColors.textSecondary.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  maxLines: 5,
                                  validator: (value) =>
                                  value!.isEmpty ? "incident.enterDesc".tr(context) : null,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Severity
                              _buildEnhancedDropdownField<Severity>(
                                label: "incident.severity".tr(context),
                                value: _selectedSeverity,
                                items: Severity.values,
                                icon: Icons.priority_high_rounded,
                                onChanged: (value) => setState(() => _selectedSeverity = value),
                                itemBuilder: (severity) => Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: _getSeverityColor(severity),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getSeverityColor(severity).withValues(alpha: 0.4),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(TranslationHelper.translateSeverity(context, severity)),
                                  ],
                                ),
                                validator: (value) =>
                                value == null ? "incident.selectSeverity".tr(context) : null,
                              ),
                              const SizedBox(height: 32),

                              // Evidence Section
                              _buildEnhancedSectionHeader(
                                icon: Icons.camera_alt_rounded,
                                title: 'taskCompletion.photoEvidence'.tr(context),
                                subtitle: 'Add photos to support your report',
                                gradient: [Colors.purple.shade400, Colors.purple.shade600],
                              ),
                              const SizedBox(height: 20),
                              _buildEnhancedEvidenceSection(),
                              const SizedBox(height: 32),

                              // Voice Recording Section
                              _buildEnhancedSectionHeader(
                                icon: Icons.mic_rounded,
                                title: 'Voice Recording',
                                subtitle: 'Record audio description of the incident',
                                gradient: [Colors.pink.shade400, Colors.pink.shade600],
                              ),
                              const SizedBox(height: 20),
                              _buildVoiceRecordingSection(),
                              const SizedBox(height: 32),

                              // Location Section
                              _buildEnhancedSectionHeader(
                                icon: Icons.location_on_rounded,
                                title: 'Location',
                                subtitle: 'Incident location tracking',
                                gradient: [Colors.green.shade400, Colors.green.shade600],
                              ),
                              const SizedBox(height: 20),
                              _buildEnhancedLocationSection(),
                              const SizedBox(height: 24),

                              // District Dropdown Section
                              _buildEnhancedSectionHeader(
                                icon: Icons.map_outlined,
                                title: 'District',
                                subtitle: 'Select the district where incident occurred',
                                gradient: [Colors.teal.shade400, Colors.teal.shade600],
                              ),
                              const SizedBox(height: 20),
                              _buildDistrictDropdown(),
                              const SizedBox(height: 32),

                              // Upload Progress Indicator
                              if (reportState.isLoading && reportState.uploadStatus.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade50,
                                        Colors.purple.shade50,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              reportState.uploadStatus,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (reportState.uploadProgress > 0) ...[
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: reportState.uploadProgress,
                                            minHeight: 8,
                                            backgroundColor: Colors.blue.shade100,
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${(reportState.uploadProgress * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                              // Submit Button
                              CustomButton(
                                text: 'Submit Report',
                                onPressed: _submitReport,
                                isLoading: reportState.isLoading,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required IconData icon,
    required ValueChanged<T?> onChanged,
    required Widget Function(T) itemBuilder,
    String? Function(T?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.15),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: itemBuilder(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildEnhancedEvidenceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_pickedImages.isNotEmpty) ...[
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _pickedImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'image_$index',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                _pickedImages[index],
                                height: 140,
                                width: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade500,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.accent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showImageSourceActionSheet,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _pickedImages.isEmpty ? 'Add Photos' : 'Add More Photos',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_pickedImages.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Optional: Add photos to provide visual evidence',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceRecordingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_audioRecordings.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _audioRecordings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.pink.shade50,
                        Colors.pink.shade100.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.pink.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.shade400,
                              Colors.pink.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.audiotrack_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recording ${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.pink.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Audio file saved',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.pink.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeAudioRecording(index),
                        icon: Icon(
                          Icons.delete_rounded,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          if (_isRecording)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade50,
                    Colors.pink.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade400,
                                Colors.red.shade600,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade300.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      if (_isRecording && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recording...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade500,
                          Colors.red.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade300.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _stopRecording,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stop_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Stop Recording',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.shade400.withValues(alpha: 0.1),
                    Colors.pink.shade600.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.pink.shade300,
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _startRecording,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.pink.shade400,
                                Colors.pink.shade600,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _audioRecordings.isEmpty ? 'Start Recording' : 'Record Another',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.pink.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_audioRecordings.isEmpty && !_isRecording)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Optional: Record audio description of the incident',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade50,
            Colors.teal.shade100.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.teal.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade200.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedDistrict,
        decoration: InputDecoration(
          labelText: 'Select District',
          hintText: 'Choose the district',
          labelStyle: TextStyle(
            color: Colors.teal.shade700,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: Colors.teal.shade400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade600],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_city_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.teal.shade400,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        isExpanded: true,
        menuMaxHeight: 300,
        dropdownColor: Colors.teal.shade50,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.teal.shade700,
          ),
        ),
        items: tamilNaduDistricts.map((district) {
          return DropdownMenuItem(
            value: district,
            child: Text(
              district,
              style: TextStyle(
                fontSize: 15,
                color: Colors.teal.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedDistrict = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a district';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEnhancedLocationSection() {
    final isLocationAvailable = _currentPosition != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLocationAvailable
              ? [
            Colors.green.shade50,
            Colors.green.shade100.withValues(alpha: 0.5),
          ]
              : [
            Colors.orange.shade50,
            Colors.orange.shade100.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLocationAvailable ? Colors.green.shade300 : Colors.orange.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLocationAvailable ? Colors.green.shade200 : Colors.orange.shade200)
                .withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLocationAvailable
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : [Colors.orange.shade400, Colors.orange.shade600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isLocationAvailable ? Colors.green.shade300 : Colors.orange.shade300)
                      .withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isLocationAvailable
                ? const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 28,
            )
                : const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLocationAvailable ? 'Location Captured' : 'Getting Location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isLocationAvailable ? Colors.green.shade900 : Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _locationMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: isLocationAvailable ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (isLocationAvailable)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.my_location_rounded,
                color: Colors.green.shade700,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}