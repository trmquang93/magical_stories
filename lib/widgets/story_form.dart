import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import '../providers/form_data_provider.dart';

class StoryForm extends StatefulWidget {
  const StoryForm({super.key});

  @override
  State<StoryForm> createState() => _StoryFormState();
}

class _StoryFormState extends State<StoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _childNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _characterController = TextEditingController();
  String _selectedTheme = 'friendship';
  String _selectedLanguage = 'English';
  late StoryProvider _storyProvider;
  late FormDataProvider _formDataProvider;

  final List<String> _themes = [
    'friendship',
    'bravery',
    'kindness',
    'honesty',
    'perseverance',
    'responsibility',
    'creativity',
    'teamwork',
    'respect',
    'gratitude',
    'family',
    'adventure',
    'nature',
    'curiosity',
    'empathy',
  ];

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Vietnamese',
    'Chinese',
    'Japanese',
    'Korean',
    'Russian',
    'Arabic',
    'Hindi',
    'Portuguese',
    'Dutch',
    'Polish',
    'Turkish',
    'Thai',
    'Swedish',
    'Danish',
    'Finnish',
    'Norwegian',
    'Greek',
    'Hebrew',
    'Indonesian',
    'Malaysian',
    'Filipino',
    'Bengali',
    'Ukrainian',
    'Romanian',
    'Czech',
    'Hungarian',
    'Bulgarian',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storyProvider = context.read<StoryProvider>();
    _formDataProvider = context.read<FormDataProvider>();

    // Load saved form data
    _updateFormFields();
  }

  void _updateFormFields() {
    _childNameController.text = _formDataProvider.childName;
    _ageController.text = _formDataProvider.age;
    _characterController.text = _formDataProvider.favoriteCharacter;
    setState(() {
      _selectedTheme = _formDataProvider.theme;
      _selectedLanguage = _formDataProvider.language;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _storyProvider = context.read<StoryProvider>();
      _formDataProvider = context.read<FormDataProvider>();
      _storyProvider.addListener(_handleError);
      // Add listener for form data changes
      _formDataProvider.addListener(_updateFormFields);
    });
  }

  void _handleError() {
    final error = _storyProvider.error;
    if (error.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _storyProvider.removeListener(_handleError);
    _formDataProvider.removeListener(_updateFormFields);
    _childNameController.dispose();
    _ageController.dispose();
    _characterController.dispose();
    super.dispose();
  }

  void _generateStory() {
    if (_formKey.currentState!.validate()) {
      // Save form data before generating story
      _formDataProvider.saveFormData(
        childName: _childNameController.text,
        age: _ageController.text,
        favoriteCharacter: _characterController.text,
        theme: _selectedTheme,
        language: _selectedLanguage,
      );

      _storyProvider.generateStory(
        childName: _childNameController.text,
        childAge: int.parse(_ageController.text),
        favoriteCharacter: _characterController.text,
        theme: _selectedTheme,
        language: _selectedLanguage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Form(
          key: _formKey,
          child: Consumer2<StoryProvider, FormDataProvider>(
            builder: (context, storyProvider, formDataProvider, child) {
              if (formDataProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '✨ Create Your Story',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _childNameController,
                    enabled: !storyProvider.isLoading,
                    label: 'Child\'s Name',
                    icon: Icons.child_care,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the child\'s name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _ageController,
                    enabled: !storyProvider.isLoading,
                    label: 'Age',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the child\'s age';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid age';
                      }
                      final age = int.parse(value);
                      if (age < 3 || age > 10) {
                        return 'Age should be between 3 and 10';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _characterController,
                    enabled: !storyProvider.isLoading,
                    label: 'Favorite Character',
                    icon: Icons.auto_awesome,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a favorite character';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildThemeSelector(storyProvider.isLoading),
                  const SizedBox(height: 16),
                  _buildLanguageSelector(storyProvider.isLoading),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: storyProvider.isLoading ? null : _generateStory,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: storyProvider.isLoading
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      storyProvider.isLoading
                          ? 'Creating Magic...'
                          : 'Generate Story',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required bool enabled,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedTheme,
        decoration: InputDecoration(
          labelText: 'Theme',
          prefixIcon: const Icon(Icons.category),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: _themes.map((String theme) {
          return DropdownMenuItem<String>(
            value: theme,
            child: Text(theme[0].toUpperCase() + theme.substring(1)),
          );
        }).toList(),
        onChanged: isLoading
            ? null
            : (String? newValue) {
                setState(() {
                  _selectedTheme = newValue!;
                });
              },
      ),
    );
  }

  Widget _buildLanguageSelector(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedLanguage,
        decoration: InputDecoration(
          labelText: 'Language',
          prefixIcon: const Icon(Icons.language),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: _languages.map((String language) {
          return DropdownMenuItem<String>(
            value: language,
            child: Text(language),
          );
        }).toList(),
        onChanged: isLoading
            ? null
            : (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue!;
                });
              },
      ),
    );
  }
}
