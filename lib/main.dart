import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n/app_localizations.dart';
import 'providers/story_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/form_data_provider.dart';
import 'screens/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => FormDataProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Magical Stories',
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('es'), // Spanish
              Locale('fr'), // French
              Locale('vi'), // Vietnamese
            ],
            locale: settings.locale, // Get the current locale from settings
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
                brightness:
                    settings.isDarkMode ? Brightness.dark : Brightness.light,
              ),
              textTheme: TextTheme(
                bodyLarge: TextStyle(fontSize: settings.fontSize),
                bodyMedium: TextStyle(fontSize: settings.fontSize),
              ),
              useMaterial3: true,
            ),
            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}
