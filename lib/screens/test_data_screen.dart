import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/time_tracking_service.dart';
import '../utils/test_data_generator.dart';

class TestDataScreen extends StatefulWidget {
  const TestDataScreen({Key? key}) : super(key: key);

  @override
  State<TestDataScreen> createState() => _TestDataScreenState();
}

class _TestDataScreenState extends State<TestDataScreen> {
  bool _isGenerating = false;
  String _statusMessage = '';
  
  // Daily data settings
  final TextEditingController _daysController = TextEditingController(text: '7');
  final TextEditingController _entriesPerDayController = TextEditingController(text: '5');
  
  // Monthly data settings
  final TextEditingController _monthsController = TextEditingController(text: '3');
  final TextEditingController _daysPerMonthController = TextEditingController(text: '20');
  
  // Yearly data settings
  final TextEditingController _yearsController = TextEditingController(text: '1');
  final TextEditingController _monthsPerYearController = TextEditingController(text: '12');
  
  @override
  void dispose() {
    _daysController.dispose();
    _entriesPerDayController.dispose();
    _monthsController.dispose();
    _daysPerMonthController.dispose();
    _yearsController.dispose();
    _monthsPerYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Test Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Data Generator',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use this tool to generate test data for your reports. This will help you verify that daily, monthly, and yearly reports are working correctly.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Daily data generation
            _buildSection(
              title: 'Daily Test Data',
              description: 'Generate time entries for the past X days',
              fields: [
                _buildTextField(
                  controller: _daysController,
                  label: 'Number of Days',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _entriesPerDayController,
                  label: 'Entries Per Day (avg)',
                  keyboardType: TextInputType.number,
                ),
              ],
              onGenerate: _generateDailyData,
            ),
            
            const SizedBox(height: 24),
            
            // Monthly data generation
            _buildSection(
              title: 'Monthly Test Data',
              description: 'Generate time entries for the past X months',
              fields: [
                _buildTextField(
                  controller: _monthsController,
                  label: 'Number of Months',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _daysPerMonthController,
                  label: 'Days Per Month (avg)',
                  keyboardType: TextInputType.number,
                ),
              ],
              onGenerate: _generateMonthlyData,
            ),
            
            const SizedBox(height: 24),
            
            // Yearly data generation
            _buildSection(
              title: 'Yearly Test Data',
              description: 'Generate time entries for the past X years',
              fields: [
                _buildTextField(
                  controller: _yearsController,
                  label: 'Number of Years',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _monthsPerYearController,
                  label: 'Months Per Year',
                  keyboardType: TextInputType.number,
                ),
              ],
              onGenerate: _generateYearlyData,
            ),
            
            const SizedBox(height: 24),
            
            // Clear all data button
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _clearAllData,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All Time Entries'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _isGenerating
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Icon(Icons.info_outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_statusMessage),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required String description,
    required List<Widget> fields,
    required VoidCallback onGenerate,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            ...fields,
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : onGenerate,
              icon: const Icon(Icons.add),
              label: const Text('Generate Data'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
      ),
    );
  }
  
  Future<void> _generateDailyData() async {
    final timeTrackingService = Provider.of<TimeTrackingService>(context, listen: false);
    final testDataGenerator = TestDataGenerator(timeTrackingService);
    
    final days = int.tryParse(_daysController.text) ?? 7;
    final entriesPerDay = int.tryParse(_entriesPerDayController.text) ?? 5;
    
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating daily test data for $days days...';
    });
    
    await testDataGenerator.generateDailyTestData(
      days: days,
      entriesPerDay: entriesPerDay,
    );
    
    setState(() {
      _isGenerating = false;
      _statusMessage = 'Successfully generated test data for $days days!';
    });
  }
  
  Future<void> _generateMonthlyData() async {
    final timeTrackingService = Provider.of<TimeTrackingService>(context, listen: false);
    final testDataGenerator = TestDataGenerator(timeTrackingService);
    
    final months = int.tryParse(_monthsController.text) ?? 3;
    final daysPerMonth = int.tryParse(_daysPerMonthController.text) ?? 20;
    
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating monthly test data for $months months...';
    });
    
    await testDataGenerator.generateMonthlyTestData(
      months: months,
      daysPerMonth: daysPerMonth,
    );
    
    setState(() {
      _isGenerating = false;
      _statusMessage = 'Successfully generated test data for $months months!';
    });
  }
  
  Future<void> _generateYearlyData() async {
    final timeTrackingService = Provider.of<TimeTrackingService>(context, listen: false);
    final testDataGenerator = TestDataGenerator(timeTrackingService);
    
    final years = int.tryParse(_yearsController.text) ?? 1;
    final monthsPerYear = int.tryParse(_monthsPerYearController.text) ?? 12;
    
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating yearly test data for $years years...';
    });
    
    await testDataGenerator.generateYearlyTestData(
      years: years,
      monthsPerYear: monthsPerYear,
    );
    
    setState(() {
      _isGenerating = false;
      _statusMessage = 'Successfully generated test data for $years years!';
    });
  }
  
  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Time Entries'),
        content: const Text(
          'This will delete all time entries from your app. This action cannot be undone. Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final timeTrackingService = Provider.of<TimeTrackingService>(context, listen: false);
      
      setState(() {
        _isGenerating = true;
        _statusMessage = 'Clearing all time entries...';
      });
      
      await timeTrackingService.clearAllTimeEntries();
      
      setState(() {
        _isGenerating = false;
        _statusMessage = 'Successfully cleared all time entries!';
      });
    }
  }
}
