import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/utils/formatters.dart';
import '../../../widgets/auto_image_pager.dart';
import '../data/product_videos_repository.dart';
import '../data/products_repository.dart';
import 'product_form_screen.dart';

class ClientProductPreviewScreen extends StatefulWidget {
  const ClientProductPreviewScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ClientProductPreviewScreen> createState() => _ClientProductPreviewScreenState();
}

class _ClientProductPreviewScreenState extends State<ClientProductPreviewScreen> {
  final _repo = const ProductsRepository();
  final _videosRepo = const ProductVideosRepository();
  late Future<Map<String, dynamic>?> _productFuture;
  late Future<List<String>> _videosFuture;
  bool _deleting = false;
  bool _savingPublish = false;
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, String> _videoInitErrors = {};
  List<String> _videoUrls = const [];
  final PageController _videosPager = PageController();
  int _videosPage = 0;
  double _videosDragDx = 0;

  @override
  void initState() {
    super.initState();
    _productFuture = _repo.getById(widget.productId);
    _videosFuture = _videosRepo.loadPublicUrls(widget.productId);
  }

  void _reloadData() {
    setState(() {
      _productFuture = _repo.getById(widget.productId);
      _videosFuture = _videosRepo.loadPublicUrls(widget.productId);
    });
  }

  Future<void> _edit(String productId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(productId: productId)),
    );
    if (!mounted) return;
    _reloadData();
  }

  Future<void> _delete(String productId) async {
    if (_deleting) return;
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
    setState(() => _deleting = true);
    try {
      await _repo.deleteById(productId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  void dispose() {
    _videosPager.dispose();
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  Future<void> _pauseAllVideos() async {
    for (final c in _videoControllers.values) {
      if (c.value.isInitialized && c.value.isPlaying) {
        await c.pause();
      }
    }
  }

  void _syncVideoControllers(List<String> urls) {
    final nextUrls = urls.where((u) => u.trim().isNotEmpty).toList();
    final prevUrls = _videoUrls;
    if (prevUrls.length == nextUrls.length) {
      var same = true;
      for (var i = 0; i < nextUrls.length; i += 1) {
        if (nextUrls[i] != prevUrls[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }

    _videoUrls = nextUrls;

    final nextSet = nextUrls.toSet();
    final toRemove = _videoControllers.keys.where((k) => !nextSet.contains(k)).toList();
    for (final url in toRemove) {
      _videoControllers.remove(url)?.dispose();
      _videoInitErrors.remove(url);
    }

    for (final url in nextUrls) {
      if (_videoControllers.containsKey(url)) continue;
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoControllers[url] = controller;
      _initVideoController(url, controller);
    }

    if (_videosPage >= nextUrls.length) {
      _videosPage = nextUrls.isEmpty ? 0 : nextUrls.length - 1;
      if (_videosPager.hasClients) {
        _videosPager.jumpToPage(_videosPage);
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _initVideoController(String url, VideoPlayerController controller) async {
    try {
      await controller.initialize();
      await controller.setLooping(true);
      _videoInitErrors.remove(url);
    } catch (e) {
      _videoInitErrors[url] = e.toString();
    }
    if (!mounted) return;
    setState(() {});
  }

  Widget _videoCard({required String url}) {
    final controller = _videoControllers[url];
    final initError = _videoInitErrors[url];
    final initialized = controller?.value.isInitialized == true;
    final aspectRatio = initialized ? controller!.value.aspectRatio : (16 / 9);

    return AspectRatio(
      aspectRatio: aspectRatio <= 0 ? (16 / 9) : aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          color: Colors.white.withValues(alpha: 0.06),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (initialized)
                VideoPlayer(controller!)
              else if (initError != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Vidéo indisponible',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: controller == null
                        ? null
                        : () async {
                            if (!controller.value.isInitialized) return;
                            if (controller.value.isPlaying) {
                              await controller.pause();
                            } else {
                              for (final c in _videoControllers.values) {
                                if (c.value.isPlaying) {
                                  await c.pause();
                                }
                              }
                              await controller.play();
                            }
                            if (!mounted) return;
                            setState(() {});
                          },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Icon(
                        controller?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 28,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu produit'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _productFuture,
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
          final p = snapshot.data;
          if (p == null) return const Center(child: Text('Produit introuvable'));

          final images = (p['images'] as List?)?.cast<String>() ?? const [];
          final price = p['price'];
          final compareAt = p['compare_at_price'];
          final current = price is num ? price : num.tryParse(price?.toString() ?? '');
          final old = compareAt is num ? compareAt : num.tryParse(compareAt?.toString() ?? '');
          final hasDiscount = current != null && old != null && old > current;
          final brandName = (p['brands']?['name'] ?? '') as String;
          final categoryName = (p['categories']?['name'] ?? '') as String;
          final inStock = p['in_stock'] == true;
          final isPublished = p['is_published'] == null ? true : p['is_published'] == true;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    tooltip: isPublished ? 'Visible sur le site' : 'Masqué du site',
                    icon: Icon(isPublished ? Icons.visibility : Icons.visibility_off),
                    onPressed: _savingPublish
                        ? null
                        : () async {
                            setState(() => _savingPublish = true);
                            try {
                              await _repo.setPublished(widget.productId, !isPublished);
                              if (!mounted) return;
                              _reloadData();
                            } finally {
                              if (mounted) setState(() => _savingPublish = false);
                            }
                          },
                  ),
                ],
              ),
              AspectRatio(
                aspectRatio: 1.18,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: images.isEmpty
                      ? Container(color: Colors.white.withValues(alpha: 0.06))
                      : images.length == 1
                          ? CachedNetworkImage(imageUrl: images.first, fit: BoxFit.cover)
                          : AutoImagePager(imageUrls: images),
                ),
              ),
              FutureBuilder<List<String>>(
                future: _videosFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) return const SizedBox(height: 14);
                  if (snap.hasError) return const SizedBox(height: 14);
                  final urls = snap.data ?? const [];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _syncVideoControllers(urls);
                  });
                  if (urls.isEmpty) return const SizedBox(height: 14);

                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vidéos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = w / (16 / 9);
                            return Column(
                              children: [
                                SizedBox(
                                  height: h,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onHorizontalDragStart: (_) => _videosDragDx = 0,
                                    onHorizontalDragUpdate: (d) => _videosDragDx += d.delta.dx,
                                    onHorizontalDragEnd: (d) async {
                                      final v = d.primaryVelocity ?? 0;
                                      final goLeft = v < -250 || _videosDragDx < -60;
                                      final goRight = v > 250 || _videosDragDx > 60;
                                      if (!goLeft && !goRight) return;
                                      if (goLeft && _videosPage < urls.length - 1) {
                                        await _videosPager.nextPage(
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.easeOut,
                                        );
                                      } else if (goRight && _videosPage > 0) {
                                        await _videosPager.previousPage(
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    },
                                    child: PageView.builder(
                                      controller: _videosPager,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: urls.length,
                                      onPageChanged: (index) async {
                                        _videosPage = index;
                                        await _pauseAllVideos();
                                        if (!mounted) return;
                                        setState(() {});
                                      },
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: _videoCard(url: urls[index]),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                if (urls.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(urls.length, (i) {
                                        final active = i == _videosPage;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          width: active ? 18 : 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(999),
                                            color: active
                                                ? const Color(0xFFC9A96E).withValues(alpha: 0.95)
                                                : Colors.white.withValues(alpha: 0.18),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Text(
                [brandName, categoryName].where((e) => e.trim().isNotEmpty).join(' · ').toUpperCase(),
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.formatDh(price),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: gold.withValues(alpha: 0.95),
                          ),
                        ),
                        if (hasDiscount)
                          Text(
                            Formatters.formatDh(old),
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: inStock ? gold.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.12),
                      ),
                      color: inStock ? gold.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.06),
                    ),
                    child: Text(
                      inStock ? 'Disponible' : 'Sur demande',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: inStock ? Colors.white.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              if ((p['description']?.toString() ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  p['description']?.toString() ?? '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.86), height: 1.35),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleting ? null : () => _edit(p['id']?.toString() ?? ''),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleting ? null : () => _delete(p['id']?.toString() ?? ''),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(_deleting ? 'Suppression…' : 'Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
