import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rescuetn/app/constants.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppPadding.large),
        children: [
          const SizedBox(height: AppPadding.medium),
          Icon(
            Icons.help_outline,
            size: 80,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: AppPadding.large),
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppPadding.xLarge),

          _buildFAQItem(
            context,
            'How do I report an emergency?',
            'Tap the "Report Incident" button on your dashboard, fill in the details, add photos if available, and submit. Your location will be automatically captured.',
          ),
          _buildFAQItem(
            context,
            'How do I become a volunteer?',
            'During registration, select "Volunteer" as your role and add your relevant skills. You\'ll then be able to receive and accept rescue tasks.',
          ),
          _buildFAQItem(
            context,
            'How do I update my profile?',
            'Go to your Profile screen and tap "Edit Profile". You can update your phone number, address, age, and profile photo.',
          ),
          _buildFAQItem(
            context,
            'How do I change my password?',
            'Go to Profile → Change Password. Enter your current password and choose a new one. Make sure it\'s at least 6 characters long.',
          ),
          _buildFAQItem(
            context,
            'What should I include in my preparedness plan?',
            'Your preparedness plan includes essential supplies, important documents, and action items. Check off items as you complete them to track your readiness.',
          ),
          _buildFAQItem(
            context,
            'How do I find nearby shelters?',
            'Use the "Shelter Locator" feature to see available shelters on a map. You can see capacity and get directions to each shelter.',
          ),

          const SizedBox(height: AppPadding.xLarge),
          const Divider(),
          const SizedBox(height: AppPadding.large),

          const Text(
            'Contact Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppPadding.medium),

          _buildContactOption(
            context,
            Icons.email,
            'Email Support',
            'support@rescuetn.com',
            () async {
              final uri = Uri.parse('mailto:support@rescuetn.com');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          _buildContactOption(
            context,
            Icons.phone,
            'Emergency Hotline',
            '+91 100',
            () async {
              final uri = Uri.parse('tel:+91100');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          _buildContactOption(
            context,
            Icons.web,
            'Visit Website',
            'www.rescuetn.gov.in',
            () async {
              final uri = Uri.parse('https://www.rescuetn.gov.in');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

