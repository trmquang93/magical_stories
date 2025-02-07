import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import '../widgets/story_form.dart';

class HomeScreen extends StatelessWidget {
  final TabController tabController;

  const HomeScreen({
    super.key,
    required this.tabController,
  });

  void _navigateToTab(int index) {
    tabController.animateTo(index);
  }

  Future<void> _showStoryCreatedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Story Created! 🎉'),
          content:
              const Text('Your magical story has been created successfully!'),
          actions: <Widget>[
            TextButton(
              child: const Text('Stay Here'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            FilledButton(
              child: const Text('Read Story'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _navigateToTab(1); // Navigate to library tab
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Magical Stories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<StoryProvider>(
        builder: (context, storyProvider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome to Magical Stories!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      context,
                      icon: Icons.auto_awesome,
                      label: 'Generate a New Story',
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: StoryForm(
                              onStoryCreated: () {
                                Navigator.pop(context); // Dismiss form
                                _showStoryCreatedDialog(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      context,
                      icon: Icons.library_books,
                      label: 'My Library',
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () => _navigateToTab(1),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      context,
                      icon: Icons.headphones,
                      label: 'Audio Stories',
                      color: Theme.of(context).colorScheme.tertiary,
                      onTap: () => _navigateToTab(2),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      context,
                      icon: Icons.settings,
                      label: 'Settings & Parental Control',
                      color: Colors.grey,
                      onTap: () => _navigateToTab(3),
                    ),
                  ],
                ),
              ),
              if (storyProvider.isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
