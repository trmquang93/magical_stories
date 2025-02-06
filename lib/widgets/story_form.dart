import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';

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

  final List<String> _themes = [
    'friendship',
    'bravery',
    'kindness',
    'honesty',
    'perseverance',
    'responsibility',
  ];

  @override
  void dispose() {
    _childNameController.dispose();
    _ageController.dispose();
    _characterController.dispose();
    super.dispose();
  }

  void _generateStory() {
    if (_formKey.currentState!.validate()) {
      context.read<StoryProvider>().generateStory(
            childName: _childNameController.text,
            childAge: int.parse(_ageController.text),
            favoriteCharacter: _characterController.text,
            theme: _selectedTheme,
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
