import 'package:flutter/material.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/protocols_screen.dart';
import 'screens/agenda_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/results_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MedControlV2App());
}

class MedControlV2App extends StatelessWidget {
  const MedControlV2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Protocolo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D7377)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D7377),
          brightness: Brightness.dark,
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _onboardingDone = false;
  bool _checkingOnboarding = true;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey();
  final GlobalKey<ProtocolsScreenState> _protocolsKey = GlobalKey();
  final GlobalKey<AgendaScreenState> _agendaKey = GlobalKey();
  final GlobalKey<ResultsScreenState> _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final profile = await StorageService.loadProfile();
    final done = profile != null &&
        profile.name.trim().isNotEmpty &&
        profile.heightCm != null &&
        profile.heightCm! > 0;
    if (mounted) {
      setState(() {
        _onboardingDone = done;
        _checkingOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingOnboarding) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_onboardingDone) {
      return OnboardingScreen(onCompleted: () {
        setState(() => _onboardingDone = true);
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(key: _homeKey),
          ProtocolsScreen(key: _protocolsKey),
          AgendaScreen(key: _agendaKey),
          const CalculatorScreen(),
          ResultsScreen(key: _resultsKey),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _homeKey.currentState?.reload();
          if (index == 1) _protocolsKey.currentState?.reload();
          if (index == 2) _agendaKey.currentState?.reload();
          if (index == 4) _resultsKey.currentState?.reload();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Protocolos',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Calculadora',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Resultados',
          ),
        ],
      ),
    );
  }
}