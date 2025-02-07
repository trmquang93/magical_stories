import 'package:flutter/material.dart';
import '../widgets/story_form.dart';

class StoryGenerationScreen extends StatelessWidget {
  const StoryGenerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Story'),
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: StoryForm(),
        ),
      ),
    );
  }
}
