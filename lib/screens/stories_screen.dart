import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import '../widgets/story_list.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stories'),
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

          return StoryList(stories: storyProvider.stories);
        },
      ),
    );
  }
}
