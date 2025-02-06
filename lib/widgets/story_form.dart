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

  final Map<String, List<String>> _languageAliases = {
    'Vietnamese': ['Việt Nam', 'Tiếng Việt', 'Vietnam'],
    'Spanish': ['Español', 'Espanol', 'Castellano'],
    'French': ['Français', 'Francais'],
    'German': ['Deutsch'],
    'Italian': ['Italiano'],
    'Chinese': ['中文', 'Zhōngwén', 'Chinese Mandarin', '普通话', 'Pǔtōnghuà'],
    'Japanese': ['日本語', 'Nihongo'],
    'Korean': ['한국어', 'Hangugeo', '조선말', 'Chosŏnmal'],
    'Russian': ['Русский', 'Russkiy'],
    'Arabic': ['العربية', 'Al-ʻArabīyah'],
    'Hindi': ['हिन्दी', 'Hindī'],
    'Portuguese': ['Português', 'Portugues'],
    'Dutch': ['Nederlands'],
    'Polish': ['Polski', 'Język polski'],
    'Turkish': ['Türkçe', 'Turkce'],
    'Thai': ['ไทย', 'Phasa Thai'],
    'Swedish': ['Svenska'],
    'Danish': ['Dansk'],
    'Finnish': ['Suomi', 'Suomen kieli'],
    'Norwegian': ['Norsk', 'Norsk Bokmål'],
    'Greek': ['Ελληνικά', 'Elliniká'],
    'Hebrew': ['עברית', 'Ivrit'],
    'Indonesian': ['Bahasa Indonesia'],
    'Malaysian': ['Bahasa Melayu', 'Malay'],
    'Filipino': ['Tagalog', 'Wikang Filipino'],
    'Bengali': ['বাংলা', 'Bangla'],
    'Ukrainian': ['Українська', 'Ukrainska'],
    'Romanian': ['Română', 'Romana'],
    'Czech': ['Čeština', 'Cestina'],
    'Hungarian': ['Magyar'],
    'Bulgarian': ['Български', 'Bǎlgarski'],
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storyProvider = context.read<StoryProvider>();
    _formDataProvider = context.read<FormDataProvider>();

    // Load saved form data
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
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _childNameController,
                decoration: const InputDecoration(
                  labelText: 'Child\'s Name',
                  icon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the child\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  icon: Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the child\'s age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _characterController,
                decoration: const InputDecoration(
                  labelText: 'Favorite Character/Animal',
                  icon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a favorite character or animal';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTheme,
                decoration: const InputDecoration(
                  labelText: 'Story Theme',
                  icon: Icon(Icons.book),
                ),
                items: _themes.map((String theme) {
                  return DropdownMenuItem<String>(
                    value: theme,
                    child: Text(theme.substring(0, 1).toUpperCase() +
                        theme.substring(1)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTheme = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SearchAnchor(
                builder: (BuildContext context, SearchController controller) {
                  return SearchBar(
                    controller: controller,
                    padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    leading: const Icon(Icons.language),
                    hintText: 'Select Language',
                    onTap: () {
                      controller.openView();
                    },
                    textStyle: const WidgetStatePropertyAll<TextStyle>(
                      TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    surfaceTintColor: WidgetStatePropertyAll<Color>(
                      Theme.of(context).colorScheme.surface,
                    ),
                  );
                },
                suggestionsBuilder:
                    (BuildContext context, SearchController controller) {
                  final keyword = controller.text.toLowerCase();
                  return _languages.where((language) {
                    if (language.toLowerCase().contains(keyword)) return true;
                    final aliases = _languageAliases[language] ?? [];
                    return aliases
                        .any((alias) => alias.toLowerCase().contains(keyword));
                  }).map((language) => ListTile(
                        title: Text(language),
                        onTap: () {
                          setState(() {
                            _selectedLanguage = language;
                          });
                          controller.closeView(language);
                        },
                      ));
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text(
                  'Selected Language: $_selectedLanguage',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _generateStory,
                icon: const Icon(Icons.auto_stories),
                label: const Text('Generate Story'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
