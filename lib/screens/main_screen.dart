import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';
import 'medications_screen.dart';
import 'ai_insights_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  static const String routeName = '/main';

  const MainScreen();

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // which tab is currently open, 0 = home
  int _currentIndex = 0;

  // switches tabs, passed down to child screens
  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // accent colour for the active nav icons
    final themeColor = ref.watch(themeProvider);

    // HomeScreen gets a callback so its buttons can jump to the Meds tab
    final List<Widget> screens = [
      HomeScreen(onGoToMeds: () => _switchTab(1)),
      const MedicationsScreen(),
      const AiInsightsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.bottomNavBg,
          selectedItemColor: themeColor,
          unselectedItemColor: AppColors.textMedium,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            // home
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.nextMedCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.home, color: themeColor),
              ),
              label: 'Home',
            ),
            // Meds
            BottomNavigationBarItem(
              icon: const Icon(Icons.medication_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.nextMedCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.medication, color: themeColor),
              ),
              label: 'Meds',
            ),
            // AI Insights
            BottomNavigationBarItem(
              icon: const Icon(Icons.auto_awesome_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.nextMedCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, color: themeColor),
              ),
              label: 'AI Insights',
            ),
          ],
        ),
      ),
    );
  }
}
