import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';

class GrowthStoryForm extends StatefulWidget {
  const GrowthStoryForm({super.key});

  @override
  State<GrowthStoryForm> createState() => _GrowthStoryFormState();
}

class _GrowthStoryFormState extends State<GrowthStoryForm> {
  final _formKey = GlobalKey<FormState>();
  String _selectedAgeGroup = '3-5';
  String _selectedGender = '';
  String _favoriteThings = '';
  String _childName = '';
  String _selectedGrowthFocus = 'emotional';

  final List<String> _ageGroups = ['3-5', '6-8', '9-10'];
  final List<String> _genders = ['', 'Boy', 'Girl'];
  final Map<String, String> _growthFocusAreas = {
    'emotional': 'Emotional Intelligence (Kindness, Empathy, Patience)',
    'cognitive': 'Cognitive Skills (Problem-Solving, Creativity)',
    'confidence': 'Confidence & Leadership (Courage, Self-Belief)',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Personalized Growth Stories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Child\'s Name (Optional)',
                  hintText: 'Enter child\'s name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _childName = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Age Group',
                  border: OutlineInputBorder(),
                ),
                value: _selectedAgeGroup,
                items: _ageGroups.map((String ageGroup) {
                  return DropdownMenuItem<String>(
                    value: ageGroup,
                    child: Text('$ageGroup years'),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _selectedAgeGroup = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gender (Optional)',
                  border: OutlineInputBorder(),
                ),
                value: _selectedGender,
                items: _genders.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender.isEmpty ? 'Not specified' : gender),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Favorite Things',
                  hintText: 'Animals, superheroes, activities...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (value) => setState(() => _favoriteThings = value),
                maxLines: 3,
                textAlignVertical: TextAlignVertical.top,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Growth Focus',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  alignLabelWithHint: true,
                ),
                value: _selectedGrowthFocus,
                selectedItemBuilder: (BuildContext context) {
                  return _growthFocusAreas.entries.map((entry) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Text(
                        entry.value,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(
                          height: 1.3,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: _growthFocusAreas.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entry.value,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(
                          height: 1.3,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _selectedGrowthFocus = value);
                  }
                },
                isExpanded: true,
                menuMaxHeight: 300,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _generateStoryCollection,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Generate Story Collection',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _generateStoryCollection() {
    if (_formKey.currentState!.validate()) {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);

      // Create story collection request
      final request = {
        'childName': _childName,
        'ageGroup': _selectedAgeGroup,
        'gender': _selectedGender,
        'favoriteThings': _favoriteThings,
        'growthFocus': _selectedGrowthFocus,
      };

      // TODO: Implement story collection generation in StoryProvider
      storyProvider.generateStoryCollection(request).then((_) {
        Navigator.pop(context);
        _showCollectionCreatedDialog();
      });
    }
  }

  Future<void> _showCollectionCreatedDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Story Collection Created! 🎉'),
          content: const Text(
            'Your personalized growth story collection has been created successfully!',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Stay Here'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('View Collection'),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to the story collection view
              },
            ),
          ],
        );
      },
    );
  }
}
