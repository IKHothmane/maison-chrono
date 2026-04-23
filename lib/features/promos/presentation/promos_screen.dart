import 'package:flutter/material.dart';

import '../data/promos_repository.dart';
import 'promo_create_screen.dart';

class PromosScreen extends StatefulWidget {
  const PromosScreen({super.key});

  @override
  State<PromosScreen> createState() => _PromosScreenState();
}

class _PromosScreenState extends State<PromosScreen> {
  final _repo = const PromosRepository();
  int _reload = 0;

  Future<void> _refresh() async {
    setState(() => _reload++);
  }

  Future<void> _create() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PromoCreateScreen()),
    );
    if (!mounted) return;
    if (ok == true) setState(() => _reload++);
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer la promo ?'),
            content: const Text('Cette action est définitive.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await _repo.deletePromo(id);
    if (!mounted) return;
    setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promos'),
        actions: [
          IconButton(
            tooltip: 'Créer',
            icon: const Icon(Icons.add),
            onPressed: _create,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(_reload),
        future: _repo.listPromoCodes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(snapshot.error.toString()),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('Aucune promo'));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = items[index];
                final id = p['id']?.toString() ?? '';
                final code = p['code']?.toString() ?? '';
                final isActive = p['is_active'] == true;
                final used = p['used_count']?.toString() ?? '0';
                final maxUses = p['max_uses']?.toString() ?? '1';
                final percent = p['discount_percent'];
                final amount = p['discount_amount'];
                final discountLabel = percent != null ? '-$percent%' : amount != null ? '-$amount DH' : '';

                return Card(
                  child: ListTile(
                    title: Text(code, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('$discountLabel · $used/$maxUses'),
                    leading: Icon(isActive ? Icons.local_offer : Icons.local_offer_outlined),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'toggle') {
                          await _repo.setActive(promoCodeId: id, isActive: !isActive);
                          if (!mounted) return;
                          setState(() => _reload++);
                        }
                        if (value == 'delete') {
                          await _delete(id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(isActive ? 'Désactiver' : 'Activer'),
                        ),
                        const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

