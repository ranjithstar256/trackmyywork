import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/time_tracking_service.dart';
import 'dart:math' as math;

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = '0xFF4CAF50'; // Default green
  String _selectedIcon = 'access_time'; // Default icon
  bool _showCustomColorPicker = false;
  double _hue = 120; // Default green hue
  double _saturation = 0.5;
  double _lightness = 0.5;
  
  // For editing mode
  bool _isEditMode = false;
  String? _editingActivityId;
  
  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Red', 'value': '0xFFF44336'},
    {'name': 'Pink', 'value': '0xFFE91E63'},
    {'name': 'Purple', 'value': '0xFF9C27B0'},
    {'name': 'Deep Purple', 'value': '0xFF673AB7'},
    {'name': 'Indigo', 'value': '0xFF3F51B5'},
    {'name': 'Blue', 'value': '0xFF2196F3'},
    {'name': 'Light Blue', 'value': '0xFF03A9F4'},
    {'name': 'Cyan', 'value': '0xFF00BCD4'},
    {'name': 'Teal', 'value': '0xFF009688'},
    {'name': 'Green', 'value': '0xFF4CAF50'},
    {'name': 'Light Green', 'value': '0xFF8BC34A'},
    {'name': 'Lime', 'value': '0xFFCDDC39'},
    {'name': 'Yellow', 'value': '0xFFFFEB3B'},
    {'name': 'Amber', 'value': '0xFFFFC107'},
    {'name': 'Orange', 'value': '0xFFFF9800'},
    {'name': 'Deep Orange', 'value': '0xFFFF5722'},
    {'name': 'Brown', 'value': '0xFF795548'},
    {'name': 'Grey', 'value': '0xFF9E9E9E'},
    // Additional colors
    {'name': 'Blue Grey', 'value': '0xFF607D8B'},
    {'name': 'Navy', 'value': '0xFF000080'},
    {'name': 'Turquoise', 'value': '0xFF40E0D0'},
    {'name': 'Violet', 'value': '0xFF8A2BE2'},
    {'name': 'Magenta', 'value': '0xFFFF00FF'},
    {'name': 'Coral', 'value': '0xFFFF7F50'},
    {'name': 'Gold', 'value': '0xFFFFD700'},
    {'name': 'Lavender', 'value': '0xFFE6E6FA'},
    {'name': 'Mint', 'value': '0xFF98FB98'},
    {'name': 'Salmon', 'value': '0xFFFA8072'},
    {'name': 'Plum', 'value': '0xFFDDA0DD'},
    {'name': 'Olive', 'value': '0xFF808000'},
  ];
  
  final List<Map<String, dynamic>> _iconOptions = [
    // Work & Productivity
    {'name': 'Work', 'value': 'work'},
    {'name': 'Office', 'value': 'business_center'},
    {'name': 'Meeting', 'value': 'groups'},
    {'name': 'Presentation', 'value': 'present_to_all'},
    {'name': 'Laptop', 'value': 'laptop'},
    {'name': 'Computer', 'value': 'computer'},
    {'name': 'Coding', 'value': 'code'},
    {'name': 'Task', 'value': 'task_alt'},
    {'name': 'Project', 'value': 'assignment'},
    {'name': 'Call', 'value': 'call'},
    {'name': 'Email', 'value': 'email'},
    
    // Education
    {'name': 'Study', 'value': 'school'},
    {'name': 'Book', 'value': 'menu_book'},
    {'name': 'Research', 'value': 'psychology'},
    {'name': 'Learning', 'value': 'auto_stories'},
    {'name': 'Homework', 'value': 'edit_note'},
    
    // Health & Fitness
    {'name': 'Exercise', 'value': 'fitness_center'},
    {'name': 'Running', 'value': 'directions_run'},
    {'name': 'Walking', 'value': 'directions_walk'},
    {'name': 'Cycling', 'value': 'pedal_bike'},
    {'name': 'Yoga', 'value': 'self_improvement'},
    {'name': 'Meditation', 'value': 'spa'},
    {'name': 'Health', 'value': 'favorite'},
    {'name': 'Doctor', 'value': 'medical_services'},
    
    // Food & Drink
    {'name': 'Food', 'value': 'restaurant'},
    {'name': 'Coffee', 'value': 'coffee'},
    {'name': 'Breakfast', 'value': 'egg_alt'},
    {'name': 'Lunch', 'value': 'fastfood'},
    {'name': 'Dinner', 'value': 'restaurant_menu'},
    {'name': 'Cooking', 'value': 'soup_kitchen'},
    {'name': 'Grocery', 'value': 'local_grocery_store'},
    
    // Entertainment & Leisure
    {'name': 'Entertainment', 'value': 'theaters'},
    {'name': 'Movie', 'value': 'movie'},
    {'name': 'TV', 'value': 'tv'},
    {'name': 'Music', 'value': 'music_note'},
    {'name': 'Gaming', 'value': 'sports_esports'},
    {'name': 'Party', 'value': 'celebration'},
    {'name': 'Reading', 'value': 'auto_stories'},
    {'name': 'Art', 'value': 'palette'},
    
    // Travel & Transportation
    {'name': 'Travel', 'value': 'flight'},
    {'name': 'Car', 'value': 'directions_car'},
    {'name': 'Bus', 'value': 'directions_bus'},
    {'name': 'Train', 'value': 'train'},
    {'name': 'Bike', 'value': 'pedal_bike'},
    {'name': 'Walking', 'value': 'directions_walk'},
    {'name': 'Vacation', 'value': 'beach_access'},
    {'name': 'Explore', 'value': 'explore'},
    
    // Home & Personal
    {'name': 'Home', 'value': 'home'},
    {'name': 'Cleaning', 'value': 'cleaning_services'},
    {'name': 'Laundry', 'value': 'local_laundry_service'},
    {'name': 'Shopping', 'value': 'shopping_cart'},
    {'name': 'Sleep', 'value': 'hotel'},
    {'name': 'Family', 'value': 'family_restroom'},
    {'name': 'Pet', 'value': 'pets'},
    {'name': 'Gardening', 'value': 'yard'},
    
    // Social & Communication
    {'name': 'Social', 'value': 'people'},
    {'name': 'Friends', 'value': 'group'},
    {'name': 'Date', 'value': 'favorite'},
    {'name': 'Chat', 'value': 'chat'},
    {'name': 'Phone', 'value': 'phone'},
    {'name': 'Video Call', 'value': 'video_call'},
    
    // Finance & Shopping
    {'name': 'Finance', 'value': 'account_balance'},
    {'name': 'Banking', 'value': 'account_balance_wallet'},
    {'name': 'Money', 'value': 'payments'},
    {'name': 'Shopping', 'value': 'shopping_bag'},
    {'name': 'Gift', 'value': 'redeem'},
    
    // Miscellaneous
    {'name': 'Break', 'value': 'coffee_maker'},
    {'name': 'Clock', 'value': 'access_time'},
    {'name': 'Calendar', 'value': 'calendar_today'},
    {'name': 'Alarm', 'value': 'alarm'},
    {'name': 'Star', 'value': 'star'},
    {'name': 'Heart', 'value': 'favorite'},
    {'name': 'Settings', 'value': 'settings'},
    {'name': 'Custom', 'value': 'tune'},
  ];
  
  @override
  void initState() {
    super.initState();
    // Set system UI overlay style for better integration with the app design
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    
    // Delay to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Activity) {
        // We're in edit mode
        final activity = args;
        setState(() {
          _isEditMode = true;
          _editingActivityId = activity.id;
          _nameController.text = activity.name;
          _selectedColor = activity.color;
          _selectedIcon = activity.icon;
          
          // Update HSL values from the color
          final color = Color(int.parse(activity.color));
          final hslColor = HSLColor.fromColor(color);
          _hue = hslColor.hue;
          _saturation = hslColor.saturation;
          _lightness = hslColor.lightness;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double statusBarHeight = mediaQuery.padding.top;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + statusBarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isEditMode ? Icons.edit_rounded : Icons.add_task_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditMode ? 'Edit Activity' : 'Add New Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity name field
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Activity Name',
                      hintText: 'Enter a name for your activity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.label_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an activity name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Color selection
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.palette_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Select Color',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showCustomColorPicker = !_showCustomColorPicker;
                                
                                // If we're showing the color picker, initialize it with the current color
                                if (_showCustomColorPicker) {
                                  final color = Color(int.parse(_selectedColor));
                                  final HSLColor hslColor = HSLColor.fromColor(color);
                                  _hue = hslColor.hue;
                                  _saturation = hslColor.saturation;
                                  _lightness = hslColor.lightness;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _showCustomColorPicker 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                    : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _showCustomColorPicker ? Icons.palette_outlined : Icons.color_lens_outlined,
                                    size: 16,
                                    color: _showCustomColorPicker 
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _showCustomColorPicker ? 'Presets' : 'Custom',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _showCustomColorPicker 
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_showCustomColorPicker)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _colorOptions.map((color) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColor = color['value'];
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(color['value'])),
                                  shape: BoxShape.circle,
                                  border: _selectedColor == color['value']
                                      ? Border.all(color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(int.parse(color['value'])).withOpacity(0.4),
                                      blurRadius: _selectedColor == color['value'] ? 8 : 0,
                                      spreadRadius: _selectedColor == color['value'] ? 1 : 0,
                                    ),
                                  ],
                                ),
                                child: _selectedColor == color['value']
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                                    : null,
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Column(
                          children: [
                            // Current color preview
                            Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                color: HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor(),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor().withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Hue slider
                            Row(
                              children: [
                                const Icon(Icons.palette, size: 20),
                                const SizedBox(width: 8),
                                const Text('Hue', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.red,
                                          Colors.yellow,
                                          Colors.green,
                                          Colors.cyan,
                                          Colors.blue,
                                          Colors.purple,
                                          Colors.red,
                                        ],
                                      ),
                                    ),
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        trackShape: const RoundedRectSliderTrackShape(),
                                        trackHeight: 24,
                                        thumbShape: CustomSliderThumbShape(),
                                        overlayShape: SliderComponentShape.noOverlay,
                                      ),
                                      child: Slider(
                                        value: _hue,
                                        min: 0,
                                        max: 360,
                                        onChanged: (value) {
                                          setState(() {
                                            _hue = value;
                                            _updateSelectedColorFromHSL();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Saturation slider
                            Row(
                              children: [
                                const Icon(Icons.invert_colors, size: 20),
                                const SizedBox(width: 8),
                                const Text('Saturation', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          HSLColor.fromAHSL(1.0, _hue, 0, _lightness).toColor(),
                                          HSLColor.fromAHSL(1.0, _hue, 1, _lightness).toColor(),
                                        ],
                                      ),
                                    ),
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        trackShape: const RoundedRectSliderTrackShape(),
                                        trackHeight: 24,
                                        thumbShape: CustomSliderThumbShape(),
                                        overlayShape: SliderComponentShape.noOverlay,
                                      ),
                                      child: Slider(
                                        value: _saturation,
                                        min: 0,
                                        max: 1,
                                        onChanged: (value) {
                                          setState(() {
                                            _saturation = value;
                                            _updateSelectedColorFromHSL();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Lightness slider
                            Row(
                              children: [
                                const Icon(Icons.brightness_6, size: 20),
                                const SizedBox(width: 8),
                                const Text('Lightness', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black,
                                          HSLColor.fromAHSL(1.0, _hue, _saturation, 0.5).toColor(),
                                          Colors.white,
                                        ],
                                      ),
                                    ),
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        trackShape: const RoundedRectSliderTrackShape(),
                                        trackHeight: 24,
                                        thumbShape: CustomSliderThumbShape(),
                                        overlayShape: SliderComponentShape.noOverlay,
                                      ),
                                      child: Slider(
                                        value: _lightness,
                                        min: 0,
                                        max: 1,
                                        onChanged: (value) {
                                          setState(() {
                                            _lightness = value;
                                            _updateSelectedColorFromHSL();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Save custom color button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showCustomColorPicker = false;
                                  });
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Use This Color'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor(),
                                  foregroundColor: _lightness > 0.6 ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Icon selection
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select an icon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 300, // Increased height for better browsing
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DefaultTabController(
                          length: 8, // Number of categories
                          child: Column(
                            children: [
                              TabBar(
                                isScrollable: true,
                                labelColor: Theme.of(context).colorScheme.primary,
                                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                indicatorColor: Theme.of(context).colorScheme.primary,
                                tabs: const [
                                  Tab(text: 'Work'),
                                  Tab(text: 'Education'),
                                  Tab(text: 'Health'),
                                  Tab(text: 'Food'),
                                  Tab(text: 'Entertainment'),
                                  Tab(text: 'Travel'),
                                  Tab(text: 'Home'),
                                  Tab(text: 'Other'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    // Work & Productivity
                                    _buildIconGrid(_iconOptions.sublist(0, 11)),
                                    // Education
                                    _buildIconGrid(_iconOptions.sublist(11, 16)),
                                    // Health & Fitness
                                    _buildIconGrid(_iconOptions.sublist(16, 24)),
                                    // Food & Drink
                                    _buildIconGrid(_iconOptions.sublist(24, 31)),
                                    // Entertainment & Leisure
                                    _buildIconGrid(_iconOptions.sublist(31, 39)),
                                    // Travel & Transportation
                                    _buildIconGrid(_iconOptions.sublist(39, 47)),
                                    // Home & Personal
                                    _buildIconGrid(_iconOptions.sublist(47, 55)),
                                    // Miscellaneous and others
                                    _buildIconGrid(_iconOptions.sublist(55)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Preview
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(int.parse(_selectedColor)),
                              Color(int.parse(_selectedColor)).withBlue(
                                (Color(int.parse(_selectedColor)).blue + 20).clamp(0, 255)
                              ),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(int.parse(_selectedColor)).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconData(_selectedIcon),
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _nameController.text.isEmpty
                                    ? 'Preview'
                                    : _nameController.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _saveActivity,
          icon: Icon(
            _isEditMode ? Icons.check_rounded : Icons.add_rounded,
            color: Colors.white,
          ),
          label: Text(
            _isEditMode ? 'Save Changes' : 'Add Activity',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 4,
        ),
      ),
    );
  }
  
  void _saveActivity() {
    if (_formKey.currentState!.validate()) {
      final timeTrackingService = Provider.of<TimeTrackingService>(context, listen: false);
      
      if (_isEditMode && _editingActivityId != null) {
        // Update existing activity
        timeTrackingService.updateActivity(
          _editingActivityId!,
          _nameController.text,
          _selectedColor,
          _selectedIcon,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Activity updated successfully'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Add new activity
        timeTrackingService.addActivity(
          _nameController.text,
          _selectedColor,
          _selectedIcon,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Activity added successfully'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      Navigator.pop(context);
    }
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'entertainment':
        return Icons.theaters_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'groups':
        return Icons.groups_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'access_time':
        return Icons.access_time_rounded;
      case 'business_center':
        return Icons.business_center_rounded;
      case 'present_to_all':
        return Icons.present_to_all_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      case 'computer':
        return Icons.computer_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'task_alt':
        return Icons.task_alt_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'call':
        return Icons.call_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'edit_note':
        return Icons.edit_note_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'directions_walk':
        return Icons.directions_walk_rounded;
      case 'pedal_bike':
        return Icons.pedal_bike_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'egg_alt':
        return Icons.egg_alt_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      case 'restaurant_menu':
        return Icons.restaurant_menu_rounded;
      case 'soup_kitchen':
        return Icons.soup_kitchen_rounded;
      case 'local_grocery_store':
        return Icons.local_grocery_store_rounded;
      case 'theaters':
        return Icons.theaters_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'directions_bus':
        return Icons.directions_bus_rounded;
      case 'train':
        return Icons.train_rounded;
      case 'beach_access':
        return Icons.beach_access_rounded;
      case 'explore':
        return Icons.explore_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'local_laundry_service':
        return Icons.local_laundry_service_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'family_restroom':
        return Icons.family_restroom_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'yard':
        return Icons.yard_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'group':
        return Icons.group_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'chat':
        return Icons.chat_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'video_call':
        return Icons.video_call_rounded;
      case 'account_balance':
        return Icons.account_balance_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'redeem':
        return Icons.redeem_rounded;
      case 'coffee_maker':
        return Icons.coffee_maker_rounded;
      case 'calendar_today':
        return Icons.calendar_today_rounded;
      case 'alarm':
        return Icons.alarm_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'settings':
        return Icons.settings_rounded;
      case 'tune':
        return Icons.tune_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }
  
  void _updateSelectedColorFromHSL() {
    final color = HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();
    _selectedColor = '0x${color.value.toRadixString(16).toUpperCase()}';
  }
  
  Widget _buildIconGrid(List<Map<String, dynamic>> icons) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final iconOption = icons[index];
        final bool isSelected = _selectedIcon == iconOption['value'];
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIcon = iconOption['value'];
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor().withOpacity(0.2)
                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor(),
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconData(iconOption['value']),
                  size: 24,
                  color: isSelected
                      ? HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor()
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 4),
                Text(
                  iconOption['name'],
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor()
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CustomSliderThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(20, 20);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    // Draw shadow
    canvas.drawCircle(center, 10, shadowPaint);
    
    // Draw white circle
    canvas.drawCircle(center, 10, paint);
    
    // Draw border
    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, 9, borderPaint);
  }
}
