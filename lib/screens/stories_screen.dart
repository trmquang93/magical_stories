import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import 'story_display_screen.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  String _sortBy = 'date'; // 'date', 'theme', 'favorites'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Stories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'theme',
                child: Text('Sort by Theme'),
              ),
              const PopupMenuItem(
                value: 'favorites',
                child: Text('Sort by Favorites'),
              ),
            ],
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

          // TODO: Replace with actual stories from provider
          final stories = [
            {
              'title': 'The Brave Dragon',
              'theme': 'Bravery',
              'date': DateTime.now(),
              'isFavorite': true,
              'hasAudio': true,
              'imageUrl': null,
            },
            {
              'title': 'Friends Forever',
              'theme': 'Friendship',
              'date': DateTime.now().subtract(const Duration(days: 1)),
              'isFavorite': false,
              'hasAudio': true,
              'imageUrl': null,
            },
          ];

          // Sort stories based on selected criteria
          switch (_sortBy) {
            case 'date':
              stories.sort((a, b) =>
                  (b['date'] as DateTime).compareTo(a['date'] as DateTime));
            case 'theme':
              stories.sort((a, b) =>
                  (a['theme'] as String).compareTo(b['theme'] as String));
            case 'favorites':
              stories.sort((a, b) => (b['isFavorite'] as bool)
                  .toString()
                  .compareTo((a['isFavorite'] as bool).toString()));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return _buildStoryCard(story);
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryDisplayScreen(
                title: story['title'],
                content: 'Once upon a time...', // TODO: Add actual content
                imageUrl: story['imageUrl'],
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (story['imageUrl'] != null)
              Image.network(
                story['imageUrl'],
                height: 150,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 150,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.auto_stories,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          story['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          story['isFavorite']
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: story['isFavorite'] ? Colors.red : null,
                        ),
                        onPressed: () {
                          // TODO: Implement favorite toggle
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          story['theme'],
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (story['hasAudio'])
                        IconButton(
                          icon: const Icon(Icons.headphones),
                          onPressed: () {
                            // TODO: Implement audio playback
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          // TODO: Implement share functionality
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
