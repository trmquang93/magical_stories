import 'package:flutter/material.dart';

class AudioStoriesScreen extends StatelessWidget {
  const AudioStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Stories'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.play_circle_filled),
              title: const Text('Story 1'),
              subtitle: const Text('Duration: 5 mins'),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // TODO: Implement download functionality
                },
              ),
              onTap: () {
                // TODO: Implement play functionality
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.play_circle_filled),
              title: const Text('Story 2'),
              subtitle: const Text('Duration: 7 mins'),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // TODO: Implement download functionality
                },
              ),
              onTap: () {
                // TODO: Implement play functionality
              },
            ),
          ),
          // Add more story items here
        ],
      ),
    );
  }
}
