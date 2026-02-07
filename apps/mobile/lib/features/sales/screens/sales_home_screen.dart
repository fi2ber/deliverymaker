import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import 'catalog_screen.dart';
import 'customer_search_screen.dart';
import 'my_customers_screen.dart';

/// Sales home with dashboard stats
class SalesHomeScreen extends StatelessWidget {
  const SalesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добро пожаловать!',
                      style: IOSTheme.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sales Manager',
                      style: IOSTheme.title1,
                    ),
                  ],
                ),
              ),
            ),

            // Stats cards
            SliverToBoxAdapter(
              child: _buildStatsSection(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Быстрые действия',
                  style: IOSTheme.headline,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: _buildQuickActions(context),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recent activity
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Сегодня',
                  style: IOSTheme.headline,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Activity list placeholder
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: IOSTheme.labelTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Нет активности сегодня',
                      style: IOSTheme.bodyMedium.copyWith(
                        color: IOSTheme.labelTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Создайте первый заказ!',
                      style: IOSTheme.caption,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.people,
              value: '12',
              label: 'Мои клиенты',
              color: IOSTheme.systemBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle,
              value: '8',
              label: 'Подтверждено',
              color: IOSTheme.systemGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.shopping_bag,
              value: '5',
              label: 'Заказов',
              color: IOSTheme.systemOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _ActionCard(
            icon: Icons.storefront,
            title: 'Каталог продуктов',
            subtitle: 'Создать заказ из каталога',
            color: IOSTheme.systemBlue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CatalogScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.person_add,
            title: 'Новый клиент',
            subtitle: 'Зарегистрировать клиента',
            color: IOSTheme.systemGreen,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerSearchScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.people_outline,
            title: 'Мои клиенты',
            subtitle: 'Список и история',
            color: IOSTheme.systemPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyCustomersScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: IOSTheme.title2.copyWith(color: color),
          ),
          Text(
            label,
            style: IOSTheme.caption.copyWith(color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IOSCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: IOSTheme.headline),
                Text(subtitle, style: IOSTheme.caption),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}

/// My customers screen (placeholder)
class MyCustomersScreen extends StatelessWidget {
  const MyCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои клиенты'),
      ),
      body: const Center(
        child: Text('Список клиентов'),
      ),
    );
  }
}
