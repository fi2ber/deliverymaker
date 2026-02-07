import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/ios_theme.dart';
import 'features/driver/screens/route_screen.dart';
import 'features/sales/screens/sales_home_screen.dart';

/// Main app entry point with role-based navigation
class DeliveryApp extends StatelessWidget {
  final UserRole userRole;

  const DeliveryApp({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for iOS look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: IOSTheme.bgSecondary,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'DeliveryMaker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Manrope',
        scaffoldBackgroundColor: IOSTheme.bgPrimary,
        colorScheme: const ColorScheme.light(
          primary: IOSTheme.systemBlue,
          secondary: IOSTheme.systemIndigo,
          error: IOSTheme.systemRed,
          surface: IOSTheme.bgSecondary,
          background: IOSTheme.bgPrimary,
        ),
      ),
      home: RoleRouter(role: userRole),
    );
  }
}

/// User roles in the system
enum UserRole {
  driver,
  sales,
  manager,
  admin,
}

/// Routes user to appropriate interface based on role
class RoleRouter extends StatelessWidget {
  final UserRole role;

  const RoleRouter({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.driver:
        return const DriverNavigation();
      case UserRole.sales:
        return const SalesNavigation();
      case UserRole.manager:
        return const ManagerNavigation();
      case UserRole.admin:
        return const AdminNavigation();
    }
  }
}

/// Driver navigation - map and deliveries
class DriverNavigation extends StatefulWidget {
  const DriverNavigation({super.key});

  @override
  State<DriverNavigation> createState() => _DriverNavigationState();
}

class _DriverNavigationState extends State<DriverNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    RouteScreen(),
    _PlaceholderScreen(title: 'Мои доставки'),
    _PlaceholderScreen(title: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map,
                  label: 'Маршрут',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                _NavItem(
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping,
                  label: 'Доставки',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Профиль',
                  isActive: _currentIndex == 2,
                  onTap: () => _onTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex != index) {
      IOSTheme.lightImpact();
      setState(() => _currentIndex = index);
    }
  }
}

/// Sales navigation - catalog and clients
class SalesNavigation extends StatefulWidget {
  const SalesNavigation({super.key});

  @override
  State<SalesNavigation> createState() => _SalesNavigationState();
}

class _SalesNavigationState extends State<SalesNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    SalesHomeScreen(),
    _PlaceholderScreen(title: 'Заказы'),
    _PlaceholderScreen(title: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Главная',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag,
                  label: 'Заказы',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Профиль',
                  isActive: _currentIndex == 2,
                  onTap: () => _onTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex != index) {
      IOSTheme.lightImpact();
      setState(() => _currentIndex = index);
    }
  }
}

/// Manager navigation - dashboard and stats
class ManagerNavigation extends StatelessWidget {
  const ManagerNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(title: 'Manager Dashboard');
  }
}

/// Admin navigation - full access
class AdminNavigation extends StatelessWidget {
  const AdminNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(title: 'Admin Panel');
  }
}

/// Bottom navigation item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? IOSTheme.systemBlue.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? IOSTheme.systemBlue : IOSTheme.labelSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? IOSTheme.systemBlue : IOSTheme.labelSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for unimplemented screens
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: IOSTheme.title2,
        ),
      ),
    );
  }
}
