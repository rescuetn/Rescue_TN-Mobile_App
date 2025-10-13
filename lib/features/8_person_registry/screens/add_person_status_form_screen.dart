import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/common_widgets/custom_button.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/features/8_person_registry/providers/person_status_provider.dart';
import 'package:rescuetn/models/person_status_model.dart';

class AddPersonStatusScreen extends ConsumerStatefulWidget {
  const AddPersonStatusScreen({super.key});

  @override
  ConsumerState<AddPersonStatusScreen> createState() =>
      _AddPersonStatusScreenState();
}

class _AddPersonStatusScreenState extends ConsumerState<AddPersonStatusScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  PersonSafetyStatus _selectedStatus = PersonSafetyStatus.safe;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(PersonSafetyStatus status) {
    switch (status) {
      case PersonSafetyStatus.safe:
        return Colors.green.shade600;
      case PersonSafetyStatus.missing:
        return Colors.orange.shade600;
    }
  }

  List<Color> _getStatusGradient(PersonSafetyStatus status) {
    switch (status) {
      case PersonSafetyStatus.safe:
        return [Colors.green.shade400, Colors.green.shade600];
      case PersonSafetyStatus.missing:
        return [Colors.orange.shade400, Colors.orange.shade600];
    }
  }

  IconData _getStatusIcon(PersonSafetyStatus status) {
    switch (status) {
      case PersonSafetyStatus.safe:
        return Icons.check_circle_rounded;
      case PersonSafetyStatus.missing:
        return Icons.error_rounded;
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = ref.read(userStateProvider);
        final newPerson = PersonStatus(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text),
          lastKnownLocation: _locationController.text.trim(),
          status: _selectedStatus,
          submittedBy: user?.email ?? 'anonymous',
        );

        ref.read(personStatusProvider.notifier).addPerson(newPerson);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Person status reported successfully!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: _getStatusColor(_selectedStatus),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to submit report: $e',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusGradient = _getStatusGradient(_selectedStatus);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusGradient[0],
              statusGradient[1],
              statusGradient[1].withOpacity(0.8),
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
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
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
                            'Report Person Status',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add to safety registry',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(_selectedStatus),
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
                              // Info Banner
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade50,
                                      Colors.blue.shade100.withOpacity(0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade400,
                                            Colors.blue.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.info_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Important Information',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Please provide accurate information to help locate or confirm safety.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Person Details Section
                              _buildSectionHeader(
                                icon: Icons.person_rounded,
                                title: 'Person Details',
                                subtitle: 'Provide basic information',
                                gradient: [
                                  Colors.purple.shade400,
                                  Colors.purple.shade600
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Name Field
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'Enter person\'s full name',
                                icon: Icons.badge_rounded,
                                validator: (v) =>
                                v!.isEmpty ? 'Name is required' : null,
                              ),
                              const SizedBox(height: 16),

                              // Age Field
                              _buildTextField(
                                controller: _ageController,
                                label: 'Age',
                                hint: 'Enter age',
                                icon: Icons.cake_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                v!.isEmpty ? 'Age is required' : null,
                              ),
                              const SizedBox(height: 32),

                              // Location Section
                              _buildSectionHeader(
                                icon: Icons.location_on_rounded,
                                title: 'Location Details',
                                subtitle: 'Where was the person last seen',
                                gradient: [
                                  Colors.red.shade400,
                                  Colors.red.shade600
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Location Field
                              _buildTextField(
                                controller: _locationController,
                                label: 'Last Known Location',
                                hint: 'Enter address or area',
                                icon: Icons.place_rounded,
                                maxLines: 3,
                                validator: (v) =>
                                v!.isEmpty ? 'Location is required' : null,
                              ),
                              const SizedBox(height: 32),

                              // Status Section
                              _buildSectionHeader(
                                icon: Icons.flag_rounded,
                                title: 'Safety Status',
                                subtitle: 'Select current status',
                                gradient: statusGradient,
                              ),
                              const SizedBox(height: 20),

                              // Status Options
                              _buildStatusOption(
                                PersonSafetyStatus.safe,
                                'Marked Safe',
                                'Person is safe and accounted for',
                                Icons.check_circle_rounded,
                                [Colors.green.shade400, Colors.green.shade600],
                              ),
                              const SizedBox(height: 12),
                              _buildStatusOption(
                                PersonSafetyStatus.missing,
                                'Reported Missing',
                                'Person is missing or unaccounted for',
                                Icons.error_rounded,
                                [
                                  Colors.orange.shade400,
                                  Colors.orange.shade600
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Submit Button
                              CustomButton(
                                text: 'Submit Report',
                                onPressed: _submitReport,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 16),
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
            child: Icon(icon, color: AppColors.primary),
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
              color: AppColors.textSecondary.withOpacity(0.15),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: AppColors.error,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildStatusOption(
      PersonSafetyStatus status,
      String title,
      String description,
      IconData icon,
      List<Color> gradient,
      ) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? gradient[0].withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? gradient[0].withOpacity(0.5)
                : AppColors.textSecondary.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: gradient[0].withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? gradient[1] : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}