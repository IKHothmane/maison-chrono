import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/brands_repository.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  final _repo = const BrandsRepository();
  int _reload = 0;

  Future<void> _refresh() async {
    setState(() => _reload++);
  }

  Future<void> _create() async {
    final name = TextEditingController();
    final logoUrl = TextEditingController();
    final description = TextEditingController();

    try {
      final data = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ajouter une marque'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: logoUrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Logo URL (optionnel)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': name.text,
                  'logoUrl': logoUrl.text,
                  'description': description.text,
                });
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (data == null) return;

      final vName = (data['name'] ?? '').trim();
      if (vName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le nom est obligatoire')),
        );
        return;
      }

      await _repo.createBrand(
        name: vName,
        logoUrl: data['logoUrl'],
        description: data['description'],
      );

      if (!mounted) return;
      setState(() => _reload++);
    } finally {
      name.dispose();
      logoUrl.dispose();
      description.dispose();
    }
  }

  Future<void> _deleteBrand(String brandId) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer la marque ?'),
            content: const Text('Cette action est définitive.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    try {
      await _repo.deleteBrandById(brandId);
      if (!mounted) return;
      setState(() => _reload++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marques'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(_reload),
        future: _repo.listBrands(),
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
                children: [
                  const SizedBox(height: 200),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.stars_outlined, size: 48, color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        Text('Aucune marque', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              child = ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final b = items[index];
                  final id = b['id']?.toString() ?? '';
                  final logoUrl = b['logo_url']?.toString();
                  final name = b['name']?.toString() ?? '';

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFC9A96E).withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              color: const Color(0xFF252525),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: (logoUrl != null && logoUrl.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: logoUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Center(
                                        child: Icon(
                                          Icons.stars_rounded,
                                          size: 20,
                                          color: const Color(0xFFC9A96E).withValues(alpha: 0.4),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: Color(0xFFC9A96E),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Marque',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFFC9A96E).withValues(alpha: 0.6),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: Colors.white.withValues(alpha: 0.5), size: 20),
                            onSelected: (value) async {
                              if (value == 'delete') await _deleteBrand(id);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          }

          return RefreshIndicator(
            color: const Color(0xFFC9A96E),
            onRefresh: _refresh,
            child: child,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-brands',
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }
}
