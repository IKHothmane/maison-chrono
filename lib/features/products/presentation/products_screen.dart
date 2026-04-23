import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../data/products_repository.dart';
import 'client_product_preview_screen.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repo = const ProductsRepository();
  String _search = '';
  int _reload = 0;

  Future<void> _toggleWebVisible({required String productId, required bool currentVisible}) async {
    if (productId.trim().isEmpty) return;
    await _repo.setPublished(productId, !currentVisible);
    if (!mounted) return;
    setState(() => _reload++);
  }

  Future<void> _refresh() async {
    setState(() => _reload++);
  }

  Future<List<Map<String, dynamic>>> _load() async {
    return _repo.listForAdmin(search: _search.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Rechercher un produit…',
                  prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFFC9A96E).withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
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
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.watch_off_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              Text('Aucun produit', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    child = GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final p = items[index];
                        final images = (p['images'] as List?)?.cast<String>() ?? const [];
                        final imageUrl = images.isNotEmpty ? images.first : null;
                        final price = Formatters.formatDh(p['price']);
                        final compareAtRaw = p['compare_at_price'];
                        final compareAt =
                            compareAtRaw is num ? compareAtRaw : num.tryParse(compareAtRaw?.toString() ?? '');
                        final brandName = (p['brands']?['name'] ?? '') as String;
                        final categoryName = (p['categories']?['name'] ?? '') as String;
                        final isPublished = p['is_published'] == null ? true : p['is_published'] == true;
                        final current = (p['price'] is num)
                            ? (p['price'] as num)
                            : num.tryParse(p['price']?.toString() ?? '');
                        final hasDiscount = compareAt != null && current != null && compareAt > current;

                        return _ProductItemCard(
                          name: p['name']?.toString() ?? '',
                          imageUrl: imageUrl,
                          price: price,
                          brandName: brandName,
                          categoryName: categoryName,
                          isPublished: isPublished,
                          hasDiscount: hasDiscount,
                          compareAt: compareAt,
                          onTap: () async {
                            final id = p['id']?.toString();
                            if (id == null || id.isEmpty) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ClientProductPreviewScreen(productId: id)),
                            );
                            if (!mounted) return;
                            setState(() => _reload++);
                          },
                          onToggleVisibility: () => _toggleWebVisible(
                            productId: p['id']?.toString() ?? '',
                            currentVisible: isPublished,
                          ),
                          index: index,
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
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: FloatingActionButton.extended(
          heroTag: 'fab-products',
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductFormScreen()),
            );
            if (!mounted) return;
            setState(() => _reload++);
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajouter'),
        ),
      ),
    );
  }
}

class _ProductItemCard extends StatefulWidget {
  const _ProductItemCard({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.brandName,
    required this.categoryName,
    required this.isPublished,
    required this.hasDiscount,
    required this.compareAt,
    required this.onTap,
    required this.onToggleVisibility,
    this.index = 0,
  });

  final String name;
  final String? imageUrl;
  final String price;
  final String brandName;
  final String categoryName;
  final bool isPublished;
  final bool hasDiscount;
  final num? compareAt;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final int index;

  @override
  State<_ProductItemCard> createState() => _ProductItemCardState();
}

class _ProductItemCardState extends State<_ProductItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 50 + widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      [widget.brandName, widget.categoryName].where((e) => e.trim().isNotEmpty).join(' · '),
      if (widget.hasDiscount) 'Ancien: ${Formatters.formatDh(widget.compareAt)}',
    ].where((e) => e.trim().isNotEmpty).toList();

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: const Color(0xFFC9A96E).withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: widget.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF252525),
                                          Color(0xFF1A1A1A),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF252525),
                                        Color(0xFF1A1A1A),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.watch_rounded,
                                    color: Colors.white.withValues(alpha: 0.1),
                                    size: 24,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          subtitleParts.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),

                    // Price and Visibility Action
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.price,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Color(0xFFC9A96E),
                              ),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: widget.isPublished
                                  ? const Color(0xFFC9A96E).withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.04),
                            ),
                            child: IconButton(
                              tooltip: widget.isPublished ? 'Visible sur le site' : 'Masqué du site',
                              icon: Icon(
                                widget.isPublished ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                size: 14,
                                color: widget.isPublished
                                    ? const Color(0xFFC9A96E)
                                    : Colors.white.withValues(alpha: 0.35),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                              onPressed: widget.onToggleVisibility,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
