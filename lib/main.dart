import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'data/services/storage_service.dart';
import 'domain/entities/scan_item.dart';
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
    return MaterialApp(
      title: 'Escáner',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<List<ScanItem>>(
        future: StorageService.loadItems(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          return HomePage(initialItems: items);
        },
      ),
    );
  }
}