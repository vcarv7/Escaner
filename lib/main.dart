import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/services/storage_service.dart';
import 'presentation/providers/scan_provider.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanProvider(),
      child: MaterialApp(
        title: 'Escáner',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const HomePage(),
      ),
    );
  }
}