import 'package:flutter/material.dart';

class StoryDisplayScreen extends StatefulWidget {
  final String title;
  final String content;
  final String? imageUrl;

  const StoryDisplayScreen({
    super.key,
    required this.title,
    required this.content,
    this.imageUrl,
  });

  @override
  State<StoryDisplayScreen> createState() => _StoryDisplayScreenState();
}

class _StoryDisplayScreenState extends State<StoryDisplayScreen> {
  bool _isNightMode = false;
  double _fontSize = 18;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_isNightMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isNightMode = !_isNightMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildFontSizeControls(),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: _isNightMode ? Colors.black87 : Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.imageUrl != null)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(widget.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              Text(
                widget.content,
                style: TextStyle(
                  fontSize: _fontSize,
                  color: _isNightMode ? Colors.white : Colors.black,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          color: _isNightMode ? Colors.black87 : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                  // TODO: Implement audio playback
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_previous,
                  size: 32,
                ),
                onPressed: () {
                  // TODO: Implement previous page
                },
              ),
              Text(
                'Page 1',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isNightMode ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_next,
                  size: 32,
                ),
                onPressed: () {
                  // TODO: Implement next page
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.download,
                  size: 32,
                ),
                onPressed: () {
                  // TODO: Implement download functionality
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Adjust Text Size',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    if (_fontSize > 14) {
                      _fontSize -= 2;
                    }
                  });
                },
              ),
              const SizedBox(width: 16),
              Text(
                'Aa',
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    if (_fontSize < 32) {
                      _fontSize += 2;
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
