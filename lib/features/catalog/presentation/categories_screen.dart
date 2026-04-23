import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _repo = const CatalogRepository();
  int _reload = 0;

  Future<void> _refresh() async {
    setState(() => _reload++);
  }

  String _slugify(String input) {
    final s = input.trim().toLowerCase();
    final map = <String, String>{
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'œ': 'oe',
      'æ': 'ae',
    };

    final out = StringBuffer();
    for (final ch in s.split('')) {
      out.write(map[ch] ?? ch);
    }

    final normalized = out.toString();
    final dashed = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final trimmed = dashed.replaceAll(RegExp(r'^-+'), '').replaceAll(RegExp(r'-+$'), '');
    return trimmed;
  }

  Future<void> _create() async {
    final name = TextEditingController();
    final slug = TextEditingController();

    try {
      final data = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ajouter une catégorie'),
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
                  controller: slug,
                  decoration: const InputDecoration(labelText: 'Slug (optionnel)'),
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
                  'slug': slug.text,
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

      final vSlug = (data['slug'] ?? '').trim().isEmpty ? _slugify(vName) : (data['slug'] ?? '').trim();
      if (vSlug.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slug invalide')),
        );
        return;
      }

      await _repo.createCategory(name: vName, slug: vSlug);

      if (!mounted) return;
      setState(() => _reload++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      name.dispose();
      slug.dispose();
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer la catégorie ?'),
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
      await _repo.deleteCategoryById(categoryId);
      if (!mounted) return;
      setState(() => _reload++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(_reload),
        future: _repo.listCategories(),
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
                        Icon(Icons.category_outlined, size: 48, color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        Text('Aucune catégorie', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
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
                  final c = items[index];
                  final id = c['id']?.toString() ?? '';
                  final name = c['name']?.toString() ?? '';
                  final slug = c['slug']?.toString() ?? '';

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
                            child: Center(
                              child: Icon(Icons.category_rounded, color: const Color(0xFFC9A96E).withValues(alpha: 0.7)),
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
                                  slug,
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
                              if (value == 'delete') await _deleteCategory(id);
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
        heroTag: 'fab-categories',
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }
}
