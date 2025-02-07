import 'package:flutter/material.dart';
import '../widgets/story_list.dart';
import '../providers/story_provider.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        elevation: 0,
      ),
      body: Consumer<StoryProvider>(
        builder: (context, storyProvider, child) {
          return StoryList(
            stories: storyProvider.savedStories,
            onStoryTap: (story) {
              Navigator.pushNamed(
                context,
                '/story',
                arguments: story,
              );
            },
          );
        },
      ),
    );
  }
}
