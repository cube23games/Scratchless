import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/services/location_permission_plan_service.dart';
import '../../shared/widgets/app_card.dart';

class ScratchLessPrivacyScreen extends StatelessWidget {
  const ScratchLessPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScratchLess privacy policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy first',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ScratchLess is designed to keep your recovery data under your control.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your recovery entries and saved risky places are kept on your device unless you choose an in-app sharing or export action.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Risky Places',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  LocationPermissionPlanService.backgroundDisclosureBody,
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 8),
                Text(
                  'Background location is optional. If you do not allow it, the rest of ScratchLess remains available, but Live Risky Place alerts cannot monitor saved places while the app is closed or not in use.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your controls',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'You decide which places are marked risky and whether live alerts are enabled for each one. You can turn live alerts off for a place or change ScratchLess location access in Android settings at any time.',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advertising and external services',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ScratchLess does not use location for advertising. If you choose to open an external support, chat, or help link, that destination may have its own privacy practices.',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Last updated: November 3, 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
