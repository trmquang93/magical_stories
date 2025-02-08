import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Historias Mágicas';

  @override
  String get homeTab => 'Inicio';

  @override
  String get storiesTab => 'Historias';

  @override
  String get audioStoriesTab => 'Historias de Audio';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get createStory => 'Crear Historia';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get fontSize => 'Tamaño de Fuente';

  @override
  String get language => 'Idioma';

  @override
  String get myStories => 'Mis Historias';

  @override
  String get sortByDate => 'Ordenar por Fecha';

  @override
  String get sortByTheme => 'Ordenar por Tema';

  @override
  String get sortByFavorites => 'Ordenar por Favoritos';

  @override
  String get deleteStory => 'Eliminar Historia';

  @override
  String get deleteStoryConfirmation => '¿Estás seguro de que quieres eliminar esta historia?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get retry => 'Reintentar';

  @override
  String get noStoriesYet => 'Aún no hay historias.\n¡Genera tu primera historia!';

  @override
  String get justNow => 'Ahora mismo';

  @override
  String minutesAgo(int minutes) {
    return 'hace ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'hace ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'hace ${days}d';
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
