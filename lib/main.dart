import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_controller.dart';
import 'data/frankfurter_client.dart';
import 'data/rates_cache.dart';
import 'data/rates_repository.dart';
import 'ui/converter_screen.dart';
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
    ThemeData theme(Brightness b) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: b,
      ),
    );
    return MaterialApp(
      title: 'Курсы валют',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
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

  static const _titles = [
    'Конвертер',
    'Сравнение за неделю',
    'Сравнение за месяц',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            ConverterScreen(controller: widget.controller),
            TrendScreen(
              controller: widget.controller,
              days: 7,
              title: 'Неделя',
            ),
            TrendScreen(
              controller: widget.controller,
              days: 30,
              title: 'Месяц',
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.currency_exchange),
            label: 'Конвертер',
          ),
          NavigationDestination(icon: Icon(Icons.date_range), label: 'Неделя'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Месяц',
          ),
        ],
      ),
    );
  }
}
