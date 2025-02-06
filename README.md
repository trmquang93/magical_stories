# Magical Stories

A Flutter application that generates personalized bedtime stories for children using AI.

## Features

- Generate personalized stories based on child's name, age, and interests
- Customizable themes and moral lessons
- Text-to-speech functionality for story reading
- Dark mode and font size customization
- Save and review previous stories
- Child-friendly interface

## Getting Started

### Prerequisites

- Flutter SDK (^3.6.1)
- Dart SDK (^3.6.1)
- iOS/Android development environment set up
- Google AI Studio API key (Gemini Pro)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/trmquang3103/magical_stories.git
```

2. Navigate to the project directory:
```bash
cd magical_stories
```

3. Install dependencies:
```bash
flutter pub get
```

### Environment Setup

1. Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

2. Create a `.env` file in the project root:
```bash
cp .env.example .env
```

3. Open `.env` and replace the placeholder with your actual API key:
```
GOOGLE_AI_API_KEY=your_actual_api_key_here
```

Note: The `.env` file is ignored by git to keep your API key secure. Never commit your actual API key to version control.

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
  ├── main.dart
  ├── config/
  │   └── env.dart
  ├── screens/
  │   ├── home_screen.dart
  │   └── settings_screen.dart
  ├── widgets/
  │   ├── story_form.dart
  │   └── story_list.dart
  └── providers/
      ├── story_provider.dart
      └── settings_provider.dart
```

## Development

### Environment Files
- `.env`: Contains your actual API keys and secrets (not committed to git)
- `.env.example`: Template file showing required environment variables
- Make sure to update `.env` with your actual API keys before running the app

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
