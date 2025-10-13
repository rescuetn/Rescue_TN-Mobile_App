import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/common_widgets/custom_button.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/models/user_model.dart';

enum LoginRole { public, volunteer }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  LoginRole _selectedRole = LoginRole.public;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authRepositoryProvider);
      final AppUser loggedInUser = await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      ref.read(userStateProvider.notifier).state = loggedInUser;
    } catch (e) {
      final snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.onPrimary),
            const SizedBox(width: AppPadding.small),
            Expanded(
              child: Text(
                e.toString().replaceFirst('Exception: ', ''),
                style: const TextStyle(fontSize: 14, color: AppColors.onPrimary),
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
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.large,
                vertical: AppPadding.medium,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with shadow and decoration
                      Center(
                        child: Hero(
                          tag: 'app_logo',
                          child: Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.3),
                                  AppColors.accent.withOpacity(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surface,
                                    width: 3,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(70),
                                  child: Image.asset(
                                    'assets/images/rescuetn.jpg',
                                    height: 140,
                                    width: 140,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppPadding.xLarge),

                      // Welcome Text with gradient and app name
                      Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.accent,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'RescueTN',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppPadding.small),
                          Text(
                            'Emergency Response System',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppPadding.xLarge),
                      // Welcome back message
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.large,
                          vertical: AppPadding.medium,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.08),
                              AppColors.accent.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppPadding.large),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.waving_hand,
                              color: AppColors.accent,
                              size: 20,
                            ),
                            const SizedBox(width: AppPadding.small),
                            Text(
                              'Welcome Back!',
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppPadding.xLarge + AppPadding.small),

                      // Role Selector Card
                      Container(
                        padding: const EdgeInsets.all(AppPadding.medium + AppPadding.small),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppPadding.small),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.2),
                                        AppColors.accent.withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                  ),
                                  child: const Icon(
                                    Icons.badge_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.small),
                                Text(
                                  'Select Your Role',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppPadding.small),
                            Text(
                              'Choose how you want to sign in',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppPadding.medium + AppPadding.small),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRoleCard(
                                    role: LoginRole.public,
                                    title: 'Public User',
                                    icon: Icons.person,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.medium),
                                Expanded(
                                  child: _buildRoleCard(
                                    role: LoginRole.volunteer,
                                    title: 'Volunteer',
                                    icon: Icons.health_and_safety,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppPadding.xLarge),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Please enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: AppPadding.medium + AppPadding.small),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureText,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: AppPadding.small),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppPadding.large),

                      // Sign In Button
                      CustomButton(
                        text: 'Sign In',
                        onPressed: _login,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: AppPadding.large),

                      // Divider with OR
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.medium,
                            ),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppPadding.large),

                      // Sign Up Section
                      Container(
                        padding: const EdgeInsets.all(AppPadding.medium + AppPadding.small),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(AppPadding.large),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/register'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppPadding.medium),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required LoginRole role,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppPadding.medium,
          horizontal: AppPadding.medium,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : AppColors.background.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppPadding.large),
          border: Border.all(
            color: isSelected ? color : AppColors.textSecondary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppPadding.medium),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppPadding.medium),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
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
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
        prefixIcon: Icon(prefixIcon, size: 22, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.large),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.large),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.large),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.large),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPadding.large),
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