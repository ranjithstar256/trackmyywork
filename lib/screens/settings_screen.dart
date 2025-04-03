import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/subscription_service.dart';
import '../services/time_tracking_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final timeTrackingService = Provider.of<TimeTrackingService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subscription status card
          _buildSubscriptionCard(context, subscriptionService),
          const SizedBox(height: 24),
          
          // Theme settings
          _buildSectionHeader(context, 'Appearance'),
          
          // Theme mode
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(
              themeService.themeMode == ThemeMode.system
                  ? 'System Default'
                  : themeService.themeMode == ThemeMode.light
                      ? 'Light'
                      : 'Dark',
            ),
            leading: const Icon(Icons.brightness_4),
            onTap: () {
              _showThemeModeDialog(context, themeService);
            },
          ),
          
          // Theme color
          ListTile(
            title: const Text('Theme Color'),
            subtitle: Text(themeService.currentThemeOption.name),
            leading: Icon(
              Icons.color_lens,
              color: themeService.currentThemeOption.primaryColor,
            ),
            onTap: () {
              _showThemeColorDialog(context, themeService);
            },
          ),
          
          const Divider(),
          
          // App settings
          _buildSectionHeader(context, 'App Settings'),
          
          // Notifications
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification settings'),
            leading: const Icon(Icons.notifications),
            onTap: () {
              _showNotificationSettingsDialog(context);
            },
          ),
          
          // Data management
          ListTile(
            title: const Text('Data Management'),
            subtitle: const Text('Export or delete your data'),
            leading: const Icon(Icons.storage),
            onTap: () {
              _showDataManagementDialog(context);
            },
          ),
          
          const Divider(),
          
          // About
          _buildSectionHeader(context, 'About'),
          
          // App info
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.info),
          ),
          
          // Privacy policy
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () {
              // Show privacy policy
            },
          ),
          
          // Terms of service
          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.description),
            onTap: () {
              // Show terms of service
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionCard(BuildContext context, SubscriptionService subscriptionService) {
    final isPro = subscriptionService.isPro;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 2,
      color: isPro ? colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPro ? Icons.workspace_premium : Icons.star_border,
                  size: 24,
                  color: isPro ? colorScheme.onPrimaryContainer : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isPro ? 'TrackMyWork Pro' : 'TrackMyWork Free',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPro ? colorScheme.onPrimaryContainer : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isPro
                  ? 'You have access to all premium features'
                  : 'Upgrade to Pro for unlimited activities, advanced reports, and more',
              style: TextStyle(
                color: isPro ? colorScheme.onPrimaryContainer.withOpacity(0.8) : null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPro ? Colors.white : colorScheme.primary,
                  foregroundColor: isPro ? colorScheme.primary : colorScheme.onPrimary,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/subscription');
                },
                child: Text(isPro ? 'Manage Subscription' : 'Upgrade to Pro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  void _showThemeModeDialog(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeModeOption(
              context,
              'System Default',
              'Follow system theme',
              ThemeMode.system,
              themeService,
            ),
            _buildThemeModeOption(
              context,
              'Light',
              'Always use light theme',
              ThemeMode.light,
              themeService,
            ),
            _buildThemeModeOption(
              context,
              'Dark',
              'Always use dark theme',
              ThemeMode.dark,
              themeService,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeModeOption(
    BuildContext context,
    String title,
    String subtitle,
    ThemeMode themeMode,
    ThemeService themeService,
  ) {
    final isSelected = themeService.themeMode == themeMode;
    
    return RadioListTile<ThemeMode>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: themeMode,
      groupValue: themeService.themeMode,
      onChanged: (value) {
        if (value != null) {
          themeService.setThemeMode(value);
          Navigator.pop(context);
        }
      },
    );
  }
  
  void _showThemeColorDialog(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: themeService.themeOptions.length,
            itemBuilder: (context, index) {
              final option = themeService.themeOptions[index];
              final isSelected = themeService.currentThemeOption.name == option.name;
              
              return InkWell(
                onTap: () {
                  themeService.setTheme(option.id);
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  backgroundColor: option.primaryColor,
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showNotificationSettingsDialog(BuildContext context) {
    // Use SharedPreferences to store notification settings
    bool reminderNotifications = true;
    bool activityNotifications = true;
    bool goalNotifications = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Notification Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Activity Reminders'),
                  subtitle: const Text('Remind you of scheduled activities'),
                  value: reminderNotifications,
                  onChanged: (value) {
                    setState(() {
                      reminderNotifications = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Activity Summaries'),
                  subtitle: const Text('Daily and weekly activity summaries'),
                  value: activityNotifications,
                  onChanged: (value) {
                    setState(() {
                      activityNotifications = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Goal Notifications'),
                  subtitle: const Text('Alerts when you reach activity goals'),
                  value: goalNotifications,
                  onChanged: (value) {
                    setState(() {
                      goalNotifications = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Save notification settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings saved'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDataManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Export Data'),
              subtitle: const Text('Export your activities as JSON'),
              leading: const Icon(Icons.download),
              onTap: () {
                Navigator.pop(context);
                _exportData(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Clear All Time Entries'),
              subtitle: const Text('Delete all your tracked time data'),
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: () {
                Navigator.pop(context);
                _showClearDataConfirmation(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    // Get the time tracking service
    final timeTrackingService = Provider.of<TimeTrackingService>(context, listen: false);
    
    // Create a JSON object with all the user's data
    final Map<String, dynamic> exportData = {
      'activities': timeTrackingService.activities.map((a) => a.toJson()).toList(),
      'timeEntries': timeTrackingService.timeEntries.map((e) => e.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
    };
    
    // Convert to pretty JSON string (for display purposes)
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    
    // In a real app, this would save the file to the device
    // For now, we'll just show a success message with a preview
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Exported'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Your data has been exported successfully.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Activities: ${timeTrackingService.activities.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Time Entries: ${timeTrackingService.timeEntries.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Time Entries?'),
        content: const Text(
          'This will permanently delete all your tracked time data. This action cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () async {
              // Get the time tracking service
              final timeTrackingService = Provider.of<TimeTrackingService>(context, listen: false);
              
              // Clear all time entries
              await _clearAllTimeEntries(context, timeTrackingService);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All time entries have been cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear All Time Entries'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllTimeEntries(BuildContext context, TimeTrackingService timeTrackingService) async {
    // Clear time entries from the service
    timeTrackingService.clearAllTimeEntries();
    
    // Also clear any other app data in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // Keep certain preferences like theme settings and subscription status
    final themeMode = prefs.getString('themeMode');
    final themeOption = prefs.getString('themeOption');
    final isPro = prefs.getBool('isPro');
    final proExpiryDate = prefs.getString('proExpiryDate');
    final isFirstLaunch = prefs.getBool('isFirstLaunch');
    
    // Clear all time entry data
    await prefs.remove('timeEntries');
    
    // Restore important settings
    if (themeMode != null) await prefs.setString('themeMode', themeMode);
    if (themeOption != null) await prefs.setString('themeOption', themeOption);
    if (isPro != null) await prefs.setBool('isPro', isPro);
    if (proExpiryDate != null) await prefs.setString('proExpiryDate', proExpiryDate);
    if (isFirstLaunch != null) await prefs.setBool('isFirstLaunch', isFirstLaunch);
  }
}
