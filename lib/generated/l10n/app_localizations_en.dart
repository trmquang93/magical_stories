import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Magical Stories';

  @override
  String get homeTab => 'Home';

  @override
  String get storiesTab => 'Stories';

  @override
  String get audioStoriesTab => 'Audio Stories';

  @override
  String get settingsTab => 'Settings';

  @override
  String get createStory => 'Create Story';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get fontSize => 'Font Size';

  @override
  String get language => 'Language';

  @override
  String get myStories => 'My Stories';

  @override
  String get sortByDate => 'Sort by Date';

  @override
  String get sortByTheme => 'Sort by Theme';

  @override
  String get sortByFavorites => 'Sort by Favorites';

  @override
  String get deleteStory => 'Delete Story';

  @override
  String get deleteStoryConfirmation => 'Are you sure you want to delete this story?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get noStoriesYet => 'No stories yet.\nGenerate your first story!';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String goodEvening(String name) {
    return 'Good Evening, $name!';
  }

  @override
  String get readyForBedtime => 'Ready for tonight\'s bedtime story?';

  @override
  String get generateNewStory => 'Generate New Story';

  @override
  String get myLibrary => 'My Library';

  @override
  String get growthStories => 'Growth Stories';

  @override
  String get recentStories => 'Recent Stories';

  @override
  String lastRead(String time) {
    return 'Last read: $time';
  }
}
