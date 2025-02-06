import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import '../widgets/story_form.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Magical Stories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<StoryProvider>(
        builder: (context, storyProvider, child) {
          if (storyProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (storyProvider.error.isNotEmpty) {
            return Center(
              child: Text(
                storyProvider.error,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: StoryForm(),
              ),
            ),
          );
        },
      ),
    );
  }
}
