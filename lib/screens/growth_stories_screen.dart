import 'package:flutter/material.dart';

class GrowthStoriesScreen extends StatelessWidget {
  const GrowthStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporary dummy data - replace with actual story data later
    final List<Map<String, String>> stories = [
      {'title': 'My First Growth Story', 'date': '2024-03-20'},
      {'title': 'Learning to Share', 'date': '2024-03-19'},
      {'title': 'Making New Friends', 'date': '2024-03-18'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth Stories'),
      ),
      body: ListView.builder(
        itemCount: stories.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(stories[index]['title']!),
              subtitle: Text(stories[index]['date']!),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to story detail screen
              },
            ),
          );
        },
      ),
    );
  }
} 