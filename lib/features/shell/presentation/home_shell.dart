import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../brands/presentation/brands_screen.dart';
import '../../catalog/presentation/categories_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../inquiries/presentation/inquiries_screen.dart';
import '../../products/presentation/products_screen.dart';
import '../../promos/presentation/promos_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  RealtimeChannel? _inquiriesChannel;

  final _tabs = const [
    _TabSpec(label: 'Dashboard', icon: Icons.dashboard_rounded, activeIcon: Icons.dashboard_rounded),
    _TabSpec(label: 'Produits', icon: Icons.watch_outlined, activeIcon: Icons.watch_rounded),
    _TabSpec(label: 'Catalogue', icon: Icons.widgets_outlined, activeIcon: Icons.widgets_rounded),
    _TabSpec(label: 'Demandes', icon: Icons.mail_outline_rounded, activeIcon: Icons.mail_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _initPush();
    _inquiriesChannel = Supabase.instance.client
        .channel('public:inquiries_global')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'inquiries',
          callback: (payload) {
            if (!mounted) return;
            final record = payload.newRecord;
            final name = record['name']?.toString().trim();
            final productId = record['product_id']?.toString().trim();
            final label = name == null || name.isEmpty ? 'Nouvelle demande' : 'Nouvelle demande: $name';
            final extra = productId == null || productId.isEmpty ? '' : ' (produit)';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFFC9A96E), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('$label$extra')),
                  ],
                ),
                action: SnackBarAction(
                  label: 'Voir',
                  textColor: const Color(0xFFC9A96E),
                  onPressed: () => setState(() => _index = 3),
                ),
              ),
            );
          },
        )
        .subscribe();
  }

  Future<void> _initPush() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.subscribeToTopic('admin_inquiries');
    } catch (_) {}
  }

  @override
  void dispose() {
    final c = _inquiriesChannel;
    if (c != null) {
      Supabase.instance.client.removeChannel(c);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'MAISON CHRONO',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            Text(
              _tabs[_index].label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: IconButton(
              tooltip: 'Déconnexion',
              icon: const Icon(Icons.logout_rounded, size: 20),
              onPressed: () => Supabase.instance.client.auth.signOut(),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: IndexedStack(
          key: ValueKey(_index),
          index: _index,
          children: [
            DashboardScreen(onNavigate: (toIndex) => setState(() => _index = toIndex)),
            const ProductsScreen(),
            const _CatalogueHubScreen(),
            const InquiriesScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: const Color(0xFFC9A96E).withValues(alpha: 0.1)),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          animationDuration: const Duration(milliseconds: 400),
          destinations: _tabs
              .map(
                (t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.label, required this.icon, required this.activeIcon});

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _CatalogueHubScreen extends StatelessWidget {
  const _CatalogueHubScreen();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _HubCard(
          title: 'Marques',
          subtitle: 'Ajouter / supprimer des marques',
          icon: Icons.stars_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BrandsScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _HubCard(
          title: 'Catégories',
          subtitle: 'Ajouter / supprimer des catégories',
          icon: Icons.category_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CategoriesScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _HubCard(
          title: 'Promos',
          subtitle: 'Créer / supprimer des promos',
          icon: Icons.local_offer_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PromosScreen()),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFC9A96E).withValues(alpha: 0.2),
                  width: 1.5,
                ),
                color: const Color(0xFF252525),
              ),
              child: Center(
                child: Icon(icon, color: const Color(0xFFC9A96E).withValues(alpha: 0.75)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}
