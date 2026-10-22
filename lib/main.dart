import 'package:flutter/material.dart';

import 'ads.dart';
import 'generate_page.dart';
import 'history.dart';
import 'history_page.dart';
import 'scan_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HistoryStore.instance.load();
  AdService.instance.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  static const _titles = ['Crear QR', 'Escanear', 'Historial'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_tab])),
      body: IndexedStack(
        index: _tab,
        children: [
          const GeneratePage(),
          ScanPage(active: _tab == 1),
          const HistoryPage(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.qr_code_2), label: 'Crear'),
              NavigationDestination(
                  icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
              NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
            ],
          ),
        ],
      ),
    );
  }
}
