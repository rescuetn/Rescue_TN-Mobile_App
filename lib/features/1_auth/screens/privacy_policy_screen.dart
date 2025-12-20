import 'package:flutter/material.dart';
import 'package:rescuetn/app/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppPadding.medium),
            const Icon(
              Icons.privacy_tip,
              size: 60,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppPadding.large),
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppPadding.medium),
            Text(
              'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppPadding.xLarge),

            _buildSection(
              '1. Information We Collect',
              'We collect information that you provide directly to us, including:\n\n'
              '• Personal information (name, email, phone number, address)\n'
              '• Location data when you report incidents\n'
              '• Photos and audio recordings you upload\n'
              '• Emergency preparedness information\n'
              '• Volunteer skills and availability status',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Provide emergency response services\n'
              '• Coordinate rescue operations\n'
              '• Send you important alerts and notifications\n'
              '• Match volunteers with appropriate tasks\n'
              '• Improve our services and user experience',
            ),
            _buildSection(
              '3. Data Security',
              'We implement appropriate security measures to protect your personal information:\n\n'
              '• All data is encrypted in transit and at rest\n'
              '• Access to personal data is restricted to authorized personnel\n'
              '• Regular security audits and updates\n'
              '• Secure authentication and authorization',
            ),
            _buildSection(
              '4. Location Data',
              'We collect location data to:\n\n'
              '• Accurately report incident locations\n'
              '• Help emergency responders reach you quickly\n'
              '• Show nearby shelters and resources\n\n'
              'Location data is only shared with emergency services and authorized volunteers during active incidents.',
            ),
            _buildSection(
              '5. Your Rights',
              'You have the right to:\n\n'
              '• Access your personal data\n'
              '• Correct inaccurate information\n'
              '• Delete your account and data\n'
              '• Opt-out of non-essential communications\n'
              '• Request a copy of your data',
            ),
            _buildSection(
              '6. Third-Party Services',
              'We use Firebase (Google) for:\n\n'
              '• Authentication and user management\n'
              '• Cloud storage and database\n'
              '• Push notifications\n\n'
              'These services have their own privacy policies that govern data handling.',
            ),
            _buildSection(
              '7. Contact Us',
              'If you have questions about this Privacy Policy, please contact us:\n\n'
              'Email: privacy@rescuetn.com\n'
              'Phone: +91 100\n'
              'Address: RescueTN Headquarters, Tamil Nadu',
            ),

            const SizedBox(height: AppPadding.xLarge),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'By using RescueTN, you agree to this Privacy Policy. We may update this policy from time to time, and we will notify you of any significant changes.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: AppPadding.large),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

