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
  void initState() {
    super.initState();
    // Refresh stories when screen loads
    Future.microtask(() =>
        Provider.of<StoryProvider>(context, listen: false).refreshStories());
  }

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

          if (storyProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${storyProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => storyProvider.refreshStories(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stories = List<Story>.from(storyProvider.stories);

          if (stories.isEmpty) {
            return const Center(
              child: Text(
                'No stories yet.\nGenerate your first story!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Sort stories based on selected criteria
          switch (_sortBy) {
            case 'date':
              stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            case 'theme':
              stories.sort((a, b) => a.title.compareTo(b.title));
            // Note: Favorites sorting is commented out as it's not implemented in the Story model yet
            // case 'favorites':
            //   stories.sort((a, b) => (b.isFavorite).toString().compareTo(a.isFavorite.toString()));
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

  Widget _buildStoryCard(Story story) {
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
                title: story.title,
                content: story.content,
                // imageUrl is not implemented in Story model yet
                imageUrl: null,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                          story.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Favorite functionality to be implemented
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {
                          // TODO: Implement favorite toggle when added to Story model
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
                          story.language,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
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
