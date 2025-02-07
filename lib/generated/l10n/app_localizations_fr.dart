import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Histoires Magiques';

  @override
  String get homeTab => 'Accueil';

  @override
  String get storiesTab => 'Histoires';

  @override
  String get audioStoriesTab => 'Histoires Audio';

  @override
  String get settingsTab => 'Paramètres';

  @override
  String get createStory => 'Créer une Histoire';

  @override
  String get darkMode => 'Mode Sombre';

  @override
  String get fontSize => 'Taille de Police';

  @override
  String get language => 'Langue';

  @override
  String get myStories => 'Mes Histoires';

  @override
  String get sortByDate => 'Trier par Date';

  @override
  String get sortByTheme => 'Trier par Thème';

  @override
  String get sortByFavorites => 'Trier par Favoris';

  @override
  String get deleteStory => 'Supprimer l\'Histoire';

  @override
  String get deleteStoryConfirmation => 'Êtes-vous sûr de vouloir supprimer cette histoire ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get retry => 'Réessayer';

  @override
  String get noStoriesYet => 'Pas encore d\'histoires.\nGénérez votre première histoire !';

  @override
  String get justNow => 'À l\'instant';

  @override
  String minutesAgo(int minutes) {
    return 'il y a ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'il y a ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'il y a ${days}j';
  }
}
