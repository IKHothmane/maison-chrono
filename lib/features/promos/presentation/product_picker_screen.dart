import 'package:flutter/material.dart';

import '../../products/data/products_repository.dart';

class ProductPickerScreen extends StatefulWidget {
  const ProductPickerScreen({super.key, required this.initialSelectedIds});

  final Set<String> initialSelectedIds;

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  final _productsRepo = const ProductsRepository();
  final _selected = <String>{};
  String _search = '';
  int _reload = 0;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelectedIds);
  }

  Future<List<Map<String, dynamic>>> _load() async {
    return _productsRepo.listForSelection(search: _search.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir produits'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selected.toList()),
            child: const Text('Valider'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Recherche',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() {
                _search = v;
                _reload++;
              }),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _selected.clear());
                    },
                    child: const Text('Tous les produits'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey(_reload.toString() + _search),
              future: _load(),
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
                if (items.isEmpty) return const Center(child: Text('Aucun produit'));

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = items[index];
                    final id = p['id']?.toString() ?? '';
                    final name = p['name']?.toString() ?? '';
                    final checked = _selected.contains(id);
                    return Card(
                      child: CheckboxListTile(
                        value: checked,
                        title: Text(name),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(id);
                            } else {
                              _selected.remove(id);
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
