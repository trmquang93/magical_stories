import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import '../providers/settings_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StoryList extends StatelessWidget {
  final List<Story> stories;
  final FlutterTts flutterTts = FlutterTts();
  final Function(Story) onStoryTap;

  StoryList({
    super.key,
    required this.stories,
    required this.onStoryTap,
  });

  Future<void> _speak(String text, String language) async {
    await flutterTts.setLanguage(language);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  Future<void> _stop() async {
    await flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const Center(
        child: Text(
          'No stories yet! Create your first magical story above.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListView.builder(
          itemCount: stories.length,
          padding: const EdgeInsets.all(8.0),
          itemBuilder: (context, index) {
            final story = stories[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ExpansionTile(
                title: Text(
                  story.title,
                  style: TextStyle(
                    fontSize: settings.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'For ${story.childName} (${story.childAge} years old)',
                      style: TextStyle(
                        fontSize: settings.fontSize - 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Created on ${story.createdAt.toString().split(' ')[0]}',
                      style: TextStyle(fontSize: settings.fontSize - 2),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (settings.isTextToSpeechEnabled)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () =>
                                    _speak(story.content, story.language),
                              ),
                              IconButton(
                                icon: const Icon(Icons.stop),
                                onPressed: _stop,
                              ),
                            ],
                          ),
                        MarkdownBody(
                          data: story.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(fontSize: settings.fontSize),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete Story'),
                          onPressed: () {
                            context.read<StoryProvider>().deleteStory(index);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
