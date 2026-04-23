import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../widgets/auto_image_pager.dart';
import '../../promos/presentation/promos_screen.dart';
import '../data/products_repository.dart';
import 'product_form_screen.dart';

class ClientPreviewScreen extends StatefulWidget {
  const ClientPreviewScreen({super.key});

  @override
  State<ClientPreviewScreen> createState() => _ClientPreviewScreenState();
}

class _ClientPreviewScreenState extends State<ClientPreviewScreen> {
  final _repo = const ProductsRepository();
  String _search = '';
  int _reload = 0;

  Future<void> _refresh() async {
    setState(() => _reload++);
  }

  Future<List<Map<String, dynamic>>> _load() async {
    return _repo.listForClient(search: _search.trim());
  }

  Future<void> _openEditor(String? productId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(productId: productId)),
    );
    if (!mounted) return;
    setState(() => _reload++);
  }

  Future<void> _deleteProduct(String productId) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer le produit ?'),
            content: const Text('Cette action est définitive.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await _repo.deleteById(productId);
    if (!mounted) return;
    setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PromosScreen()),
                      );
                    },
                    icon: const Icon(Icons.local_offer_outlined),
                    label: const Text('Promos'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Recherche',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey(_reload.toString() + _search),
              future: _load(),
              builder: (context, snapshot) {
                Widget child;

                if (snapshot.connectionState != ConnectionState.done) {
                  child = ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 240),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                } else if (snapshot.hasError) {
                  child = ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(snapshot.error.toString()),
                    ],
                  );
                } else {
                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    child = ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 240),
                        Center(child: Text('Aucun produit')),
                      ],
                    );
                  } else {
                    child = LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final crossAxisCount = w >= 720
                            ? 3
                            : w >= 420
                                ? 2
                                : 1;
                        return GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final p = items[index];
                            final id = p['id']?.toString() ?? '';
                            final images = (p['images'] as List?)?.cast<String>() ?? const [];
                            final brandName = (p['brands']?['name'] ?? '') as String;
                            final categoryName = (p['categories']?['name'] ?? '') as String;
                            final inStock = p['in_stock'] == true;

                            return Card(
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _openEditor(id),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: images.isEmpty
                                                ? Container(color: Colors.white.withValues(alpha: 0.06))
                                                : images.length == 1
                                                    ? CachedNetworkImage(imageUrl: images.first, fit: BoxFit.cover)
                                                    : AutoImagePager(imageUrls: images),
                                          ),
                                          if (images.length > 1)
                                            Positioned(
                                              left: 8,
                                              bottom: 8,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0A0A0A).withValues(alpha: 0.72),
                                                  borderRadius: BorderRadius.circular(999),
                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  child: Text(
                                                    '${images.length} photos',
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0A0A0A).withValues(alpha: 0.72),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                              ),
                                              child: PopupMenuButton<String>(
                                                padding: EdgeInsets.zero,
                                                tooltip: '',
                                                icon: const Icon(Icons.more_horiz, size: 18),
                                                onSelected: (value) async {
                                                  if (value == 'edit') await _openEditor(id);
                                                  if (value == 'delete') await _deleteProduct(id);
                                                },
                                                itemBuilder: (context) => const [
                                                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            [brandName, categoryName]
                                                .where((e) => e.trim().isNotEmpty)
                                                .join(' · ')
                                                .toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              letterSpacing: 1.0,
                                              color: Colors.white.withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            p['name']?.toString() ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  Formatters.formatDh(p['price']),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: gold.withValues(alpha: 0.95),
                                                  ),
                                                ),
                                              ),
                                              if (p['compare_at_price'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 10),
                                                  child: Text(
                                                    Formatters.formatDh(p['compare_at_price']),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.white.withValues(alpha: 0.7),
                                                    ),
                                                  ),
                                                ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(999),
                                                  border: Border.all(
                                                    color: inStock
                                                        ? gold.withValues(alpha: 0.22)
                                                        : Colors.white.withValues(alpha: 0.12),
                                                  ),
                                                  color: inStock
                                                      ? gold.withValues(alpha: 0.08)
                                                      : Colors.white.withValues(alpha: 0.06),
                                                ),
                                                child: Text(
                                                  inStock ? 'Disponible' : 'Sur demande',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: inStock
                                                        ? Colors.white.withValues(alpha: 0.92)
                                                        : Colors.white.withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: child,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-preview',
        onPressed: () => _openEditor(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
