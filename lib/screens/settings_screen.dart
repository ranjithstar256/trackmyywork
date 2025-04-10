import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/theme_service.dart';
import '../services/subscription_service.dart';
import '../services/time_tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'privacy_policy_screen.dart';
import 'test_data_screen.dart';

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
          
          // Data management
          ListTile(
            title: const Text('Data Management'),
            subtitle: const Text('Export or delete your data'),
            leading: const Icon(Icons.storage),
            onTap: () {
              _showDataManagementDialog(context);
            },
          ),
          
          // Test Data Generator
          ListTile(
            title: const Text('Test Data Generator'),
            subtitle: const Text('Generate test data for reports'),
            leading: const Icon(Icons.science),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestDataScreen(),
                ),
              );
            },
          ),
          
          const Divider(),
          
          // About
          _buildSectionHeader(context, 'About'),
          
          // App info
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.1'),
            leading: const Icon(Icons.info),
          ),
          
          // Privacy policy
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          
          // Terms of service
          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.description),
            onTap: () {
              // Show terms of service (to be implemented)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms of Service coming soon'),
                ),
              );
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

  void _exportData(BuildContext context) async {
    // Show loading indicator
    final loadingDialog = _showLoadingDialog(context, 'Preparing data export...');
    
    try {
      // Get the time tracking service
      final timeTrackingService = Provider.of<TimeTrackingService>(context, listen: false);
      
      // Create a JSON object with all the user's data
      final Map<String, dynamic> exportData = {
        'activities': timeTrackingService.activities.map((a) => a.toJson()).toList(),
        'timeEntries': timeTrackingService.timeEntries.map((e) => e.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.1',
      };
      
      // Convert to pretty JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'trackmywork_export_$formattedDate.json';
      final filePath = '${directory.path}/$fileName';
      
      // Write the JSON data to a file
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success dialog with share option
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Data Exported'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Your data has been exported successfully.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Total Activities: ${timeTrackingService.activities.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Total Time Entries: ${timeTrackingService.timeEntries.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Export Location:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(filePath),
              const SizedBox(height: 8),
              const Text(
                'Note: The file is saved in your app\'s documents directory. Use the Share button below to save it to a more accessible location or send it via email.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              onPressed: () async {
                Navigator.pop(context);
                // Share the file
                final result = await Share.shareXFiles(
                  [XFile(filePath)],
                  text: 'TrackMyWork Data Export',
                );
                
                if (result.status == ShareResultStatus.dismissed) {
                  // Show a hint if user dismissed the share dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You can access this file later from Settings > Data Management'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'There was an error exporting your data.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $e',
                style: const TextStyle(fontSize: 12),
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
  }
  
  Widget _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
    
    // Return a placeholder widget (the dialog is shown by showDialog)
    return const SizedBox.shrink();
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
