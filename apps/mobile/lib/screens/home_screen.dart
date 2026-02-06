import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/sync/sync_bloc.dart';
import 'van_sale_screen.dart';
import 'truck_stock_screen.dart';
import 'finance_screen.dart';
import 'order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardView(),
    const VanSaleScreen(),
    const TruckStockScreen(),
    const FinanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Van Sale',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_outlined),
            selectedIcon: Icon(Icons.inventory),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
        ],
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => 
      bloc.state is AuthAuthenticated 
        ? (bloc.state as AuthAuthenticated).email 
        : 'User'
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('DeliveryMaker'),
        actions: [
          // Sync Status Indicator
          BlocBuilder<SyncBloc, SyncState>(
            builder: (context, state) {
              if (state is SyncOnline) {
                return Tooltip(
                  message: state.isSyncing 
                    ? 'Syncing...' 
                    : state.pendingItems > 0 
                      ? '${state.pendingItems} items pending'
                      : 'Online',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        if (state.isSyncing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else if (state.pendingItems > 0)
                          Badge(
                            label: Text('${state.pendingItems}'),
                            child: const Icon(Icons.sync),
                          )
                        else
                          const Icon(Icons.cloud_done),
                      ],
                    ),
                  ),
                );
              } else if (state is SyncOffline) {
                return Tooltip(
                  message: 'Offline - ${state.pendingItems} items pending',
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.cloud_off, color: Colors.orange),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<SyncBloc>().add(SyncRequested());
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      user,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _ActionCard(
                  icon: Icons.shopping_cart,
                  title: 'New Sale',
                  subtitle: 'Create van sale',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VanSaleScreen(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  icon: Icons.inventory,
                  title: 'Stock Check',
                  subtitle: 'View inventory',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TruckStockScreen(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  icon: Icons.receipt_long,
                  title: 'Orders',
                  subtitle: 'View history',
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to orders
                  },
                ),
                _ActionCard(
                  icon: Icons.sync,
                  title: 'Sync Now',
                  subtitle: 'Upload data',
                  color: Colors.purple,
                  onTap: () {
                    context.read<SyncBloc>().add(SyncRequested());
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sync Status
            BlocBuilder<SyncBloc, SyncState>(
              builder: (context, state) {
                if (state is SyncOnline) {
                  return Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.cloud_done, color: Colors.green),
                      title: const Text('Online'),
                      subtitle: Text(
                        state.lastSyncTime != null
                          ? 'Last sync: ${_formatDateTime(state.lastSyncTime!)}'
                          : state.pendingItems > 0
                            ? '${state.pendingItems} items pending sync'
                            : 'All data synced',
                      ),
                      trailing: state.isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              context.read<SyncBloc>().add(SyncRequested());
                            },
                          ),
                    ),
                  );
                } else if (state is SyncOffline) {
                  return Card(
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off, color: Colors.orange),
                      title: const Text('Offline Mode'),
                      subtitle: Text('${state.pendingItems} items queued for sync'),
                      trailing: const Icon(Icons.schedule),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
