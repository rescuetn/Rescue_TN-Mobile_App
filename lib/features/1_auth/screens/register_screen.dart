import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/common_widgets/custom_button.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/models/user_model.dart';

/// Available skills for volunteers
enum VolunteerSkill {
  medicalAid('Medical Aid', Icons.medical_services),
  rescue('Rescue', Icons.emoji_people),
  foodSupply('Food Supply', Icons.restaurant),
  transport('Transport', Icons.directions_car),
  coordination('Coordination', Icons.groups);

  final String label;
  final IconData icon;
  const VolunteerSkill(this.label, this.icon);
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State for the role selection
  UserRole _selectedRole = UserRole.public;

  // State for volunteer skills
  Set<VolunteerSkill> _selectedSkills = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Validates the form and completes the profile setup with Firebase.
  Future<void> _completeProfile() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate volunteer skills if role is volunteer
    if (_selectedRole == UserRole.volunteer && _selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.onPrimary),
              const SizedBox(width: AppPadding.small),
              const Expanded(
                child: Text(
                  'Please select at least one skill',
                  style: TextStyle(color: AppColors.onPrimary),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
          margin: const EdgeInsets.all(AppPadding.medium),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Read the authentication service from the provider.
      final authService = ref.read(authRepositoryProvider);

      // 2. Prepare skills list for volunteers
      List<String>? skills;
      if (_selectedRole == UserRole.volunteer) {
        skills = _selectedSkills.map((skill) => skill.label).toList();
      }

      // 3. Call the createUser method with email, password, role, and skills.
      await authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        skills: skills, // Pass skills for volunteers
      );

      // 4. Navigation is now handled automatically!
      // The authStateChangesProvider will detect the new user, and the router
      // will automatically navigate to the home screen.

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors for better user feedback.
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email address is already registered.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.onPrimary),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: AppColors.onPrimary),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            margin: const EdgeInsets.all(AppPadding.medium),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.onPrimary),
                const SizedBox(width: AppPadding.small),
                const Expanded(
                  child: Text(
                    'An unexpected error occurred. Please try again.',
                    style: TextStyle(color: AppColors.onPrimary),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            margin: const EdgeInsets.all(AppPadding.medium),
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.accent.withOpacity(0.08),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: AppPadding.medium),
                    Expanded(
                      child: Text(
                        'Create Account',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.large,
                      vertical: AppPadding.medium,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Welcome Icon
                              Hero(
                                tag: 'register_icon',
                                child: Container(
                                  height: 100,
                                  width: 100,
                                  margin: const EdgeInsets.only(bottom: AppPadding.large),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.accent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_add,
                                    size: 50,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),

                              // Title and Subtitle
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                ).createShader(bounds),
                                child: Text(
                                  'Almost There!',
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppPadding.small),
                              Text(
                                'Complete your profile to get started',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppPadding.xLarge + AppPadding.small),

                              // Form Fields Card
                              Container(
                                padding: const EdgeInsets.all(AppPadding.large),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppPadding.medium + AppPadding.small),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.textPrimary.withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Section Header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(AppPadding.small),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                          ),
                                          child: const Icon(
                                            Icons.info_outline,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: AppPadding.small),
                                        Text(
                                          'Personal Information',
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppPadding.large),

                                    // --- Full Name Field ---
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      hint: 'Enter your full name',
                                      prefixIcon: Icons.person_outline,
                                      validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Please enter your full name'
                                          : null,
                                    ),
                                    const SizedBox(height: AppPadding.medium + AppPadding.small),

                                    // --- Email Field ---
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email Address',
                                      hint: 'Enter your email',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppPadding.large),

                                    // Security Section Divider
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(AppPadding.small),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                          ),
                                          child: const Icon(
                                            Icons.security,
                                            size: 18,
                                            color: AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(width: AppPadding.small),
                                        Text(
                                          'Account Security',
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppPadding.large),

                                    // --- Password Field ---
                                    _buildTextField(
                                      controller: _passwordController,
                                      label: 'Create Password',
                                      hint: 'Minimum 6 characters',
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      validator: (value) => value == null || value.length < 6
                                          ? 'Password must be at least 6 characters'
                                          : null,
                                    ),
                                    const SizedBox(height: AppPadding.medium + AppPadding.small),

                                    // --- Confirm Password Field ---
                                    _buildTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirm Password',
                                      hint: 'Re-enter your password',
                                      prefixIcon: Icons.lock_person_outlined,
                                      obscureText: _obscureConfirmPassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
                                      validator: (value) => value != _passwordController.text
                                          ? 'Passwords do not match'
                                          : null,
                                    ),
                                    const SizedBox(height: AppPadding.large),

                                    // Role Section Divider
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(AppPadding.small),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                          ),
                                          child: const Icon(
                                            Icons.badge_outlined,
                                            size: 18,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        const SizedBox(width: AppPadding.small),
                                        Text(
                                          'Account Type',
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppPadding.large),

                                    // --- Role Selection Dropdown ---
                                    DropdownButtonFormField<UserRole>(
                                      value: _selectedRole,
                                      decoration: InputDecoration(
                                        labelText: 'Register as',
                                        hintText: 'Select your role',
                                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                                        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
                                        prefixIcon: const Icon(Icons.badge_outlined, size: 22, color: AppColors.accent),
                                        filled: true,
                                        fillColor: AppColors.background.withOpacity(0.5),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                          borderSide: const BorderSide(
                                            color: AppColors.accent,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: AppPadding.medium + AppPadding.small,
                                          vertical: AppPadding.medium + 2,
                                        ),
                                      ),
                                      items: UserRole.values.map((role) {
                                        return DropdownMenuItem(
                                          value: role,
                                          child: Text(
                                            role.name[0].toUpperCase() + role.name.substring(1),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedRole = value;
                                            // Clear skills when changing from volunteer to another role
                                            if (value != UserRole.volunteer) {
                                              _selectedSkills.clear();
                                            }
                                          });
                                        }
                                      },
                                    ),

                                    // --- Volunteer Skills Section (Only shown for volunteers) ---
                                    if (_selectedRole == UserRole.volunteer) ...[
                                      const SizedBox(height: AppPadding.large),

                                      // Skills Section Divider
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(AppPadding.small),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                            ),
                                            child: const Icon(
                                              Icons.handyman,
                                              size: 18,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: AppPadding.small),
                                          Text(
                                            'Your Skills',
                                            style: textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppPadding.small),
                                      Text(
                                        'Select all skills that apply to you',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: AppPadding.medium),

                                      // Skills Checkboxes
                                      ...VolunteerSkill.values.map((skill) {
                                        final isSelected = _selectedSkills.contains(skill);
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: AppPadding.small),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary.withOpacity(0.1)
                                                : AppColors.background.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary.withOpacity(0.2),
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: CheckboxListTile(
                                            value: isSelected,
                                            onChanged: (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedSkills.add(skill);
                                                } else {
                                                  _selectedSkills.remove(skill);
                                                }
                                              });
                                            },
                                            title: Row(
                                              children: [
                                                Icon(
                                                  skill.icon,
                                                  size: 20,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : AppColors.textSecondary,
                                                ),
                                                const SizedBox(width: AppPadding.small),
                                                Text(
                                                  skill.label,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? AppColors.textPrimary
                                                        : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            activeColor: AppColors.primary,
                                            checkColor: AppColors.onPrimary,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: AppPadding.medium,
                                              vertical: AppPadding.small / 2,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppPadding.xLarge),

                              // --- Finish Setup Button ---
                              CustomButton(
                                text: 'Create Account',
                                onPressed: _completeProfile,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: AppPadding.large),

                              // Terms and Privacy
                              Text(
                                'By creating an account, you agree to our Terms of Service and Privacy Policy',
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppPadding.large),

                              // Back to Login
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account?',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/login'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                    ),
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
        prefixIcon: Icon(prefixIcon, size: 22, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.background.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppPadding.medium + AppPadding.small,
          vertical: AppPadding.medium + 2,
        ),
      ),
      validator: validator,
    );
  }
}