import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_controller.dart';
import 'data/frankfurter_client.dart';
import 'data/rates_cache.dart';
import 'data/rates_repository.dart';
import 'ui/converter_screen.dart';
import 'ui/theme.dart';
import 'ui/trend_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repository = RatesRepository(
    client: FrankfurterClient(),
    cache: RatesCache(prefs),
  );
  final controller = AppController(repository, prefs)..loadCurrencies();
  runApp(CurrencyApp(controller: controller));
}

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Курсы валют',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: HomeShell(controller: controller),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            ConverterScreen(controller: widget.controller),
            TrendScreen(
              controller: widget.controller,
              days: 7,
              title: 'За неделю',
            ),
            TrendScreen(
              controller: widget.controller,
              days: 30,
              title: 'За месяц',
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_rounded),
            label: 'Конвертер',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Неделя',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            label: 'Месяц',
          ),
        ],
      ),
    );
  }
}
