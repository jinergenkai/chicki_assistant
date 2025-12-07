import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:moon_design/moon_design.dart';

class ResetButton extends StatelessWidget {
  const ResetButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MoonFilledButton(
      buttonSize: MoonButtonSize.sm,
      backgroundColor: Colors.red.shade400,
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restore, size: 18),
          SizedBox(width: 8),
          Text('Reset App Config (Clear All Data)'),
        ],
      ),
      onTap: () async {
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset App Config?'),
            content: const Text(
              'This will delete all app configuration including:\n\n'
              '• User profile (name, avatar)\n'
              '• Learning progress\n'
              '• Settings\n\n'
              'You will see the onboarding screen again.\n\n'
              'Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
        );
    
        if (confirmed == true && context.mounted) {
          try {
            final appConfig = Get.find<AppConfigController>();
            await appConfig.resetToDefault();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('App config reset successfully!'),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              
              // Navigate to home/onboarding
              context.go('/');
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          }
        }
      },
    );
  }
}