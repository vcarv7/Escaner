import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/scan_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/evento_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/persona_provider.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => EventoProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PersonaProvider()),
      ],
      child: Consumer2<AuthProvider, SettingsProvider>(
        builder: (context, auth, settings, _) {
          return MaterialApp(
            title: 'Escáner',
            theme: AppTheme.getTheme(false),
            darkTheme: AppTheme.getTheme(true),
            themeMode: settings.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: auth.isAuthenticated ? const HomePage() : const LoginPage(),
          );
        },
      ),
    );
  }
}