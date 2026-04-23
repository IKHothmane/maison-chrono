import 'dart:math';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../catalog/data/catalog_repository.dart';
import '../data/product_images_repository.dart';
import '../data/product_videos_repository.dart';
import '../data/products_repository.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _catalogRepo = const CatalogRepository();
  final _productsRepo = const ProductsRepository();
  final _imagesRepo = const ProductImagesRepository();
  final _videosRepo = const ProductVideosRepository();
  final _storage = const StorageService();

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _compareAtPrice = TextEditingController();
  final _bestSellerRank = TextEditingController();
  final _description = TextEditingController();
  final _reference = TextEditingController();
  final _material = TextEditingController();
  final _movement = TextEditingController();
  final _waterResistance = TextEditingController();
  final _diameter = TextEditingController();

  final List<String> _images = [];
  final List<String> _videos = [];
  final Map<String, bool> _videoOnHome = {};
  bool _videosSupported = true;
  String? _videosLoadError;
  bool _homeVideoFlagSupported = true;
  String? _brandId;
  String? _categoryId;
  bool _inStock = true;
  bool _isFeatured = false;
  bool _isPublished = true;
  String? _productId;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _productId = widget.productId;
    _bootstrap();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _compareAtPrice.dispose();
    _bestSellerRank.dispose();
    _description.dispose();
    _reference.dispose();
    _material.dispose();
    _movement.dispose();
    _waterResistance.dispose();
    _diameter.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _brands = await _catalogRepo.listBrandsForSelect();
      _categories = await _catalogRepo.listCategoriesForSelect();

      if (widget.productId != null) {
        final client = Supabase.instance.client;
        Map<String, dynamic>? prod;
        try {
          prod = await client
              .from('products')
              .select(
                  'id,name,brand_id,category_id,price,compare_at_price,is_published,best_seller_rank,description,images,reference,material,movement,water_resistance,diameter,in_stock,is_featured')
              .eq('id', widget.productId!)
              .maybeSingle();
        } catch (e) {
          final code = e is PostgrestException ? e.code : null;
          if (code == '42703') {
            try {
              prod = await client
                  .from('products')
                  .select(
                      'id,name,brand_id,category_id,price,compare_at_price,is_published,description,images,reference,material,movement,water_resistance,diameter,in_stock,is_featured')
                  .eq('id', widget.productId!)
                  .maybeSingle();
            } catch (e2) {
              final code2 = e2 is PostgrestException ? e2.code : null;
              if (code2 == '42703') {
                prod = await client
                    .from('products')
                    .select(
                        'id,name,brand_id,category_id,price,description,images,reference,material,movement,water_resistance,diameter,in_stock,is_featured')
                    .eq('id', widget.productId!)
                    .maybeSingle();
              } else {
                rethrow;
              }
            }
          } else {
            rethrow;
          }
        }

        if (prod != null) {
          _name.text = prod['name']?.toString() ?? '';
          _price.text = prod['price']?.toString() ?? '';
          _compareAtPrice.text = prod['compare_at_price']?.toString() ?? '';
          _bestSellerRank.text = prod['best_seller_rank']?.toString() ?? '';
          _description.text = prod['description']?.toString() ?? '';
          _reference.text = prod['reference']?.toString() ?? '';
          _material.text = prod['material']?.toString() ?? '';
          _movement.text = prod['movement']?.toString() ?? '';
          _waterResistance.text = prod['water_resistance']?.toString() ?? '';
          _diameter.text = prod['diameter']?.toString() ?? '';
          _brandId = prod['brand_id']?.toString();
          _categoryId = prod['category_id']?.toString();
          _inStock = prod['in_stock'] == true;
          _isFeatured = prod['is_featured'] == true;
          _isPublished = prod['is_published'] == null ? true : prod['is_published'] == true;

          final urls = _productId == null ? null : await _imagesRepo.tryLoadPublicUrls(_productId!);
          if (urls != null) {
            _images
              ..clear()
              ..addAll(urls);
          } else {
            _images
              ..clear()
              ..addAll((prod['images'] as List?)?.cast<String>() ?? const []);
          }

          final videoUrls =
              _productId == null ? const <String>[] : await _videosRepo.loadPublicUrls(_productId!);
          _videosSupported = true;
          _videosLoadError = null;
          _videos
            ..clear()
            ..addAll(videoUrls);

          final flags = _productId == null ? null : await _videosRepo.loadShowOnHomeFlags(_productId!);
          _homeVideoFlagSupported = flags != null;
          _videoOnHome
            ..clear()
            ..addAll(flags ?? const {});
        }
      }

      _brandId ??= _brands.isNotEmpty ? _brands.first['id']?.toString() : null;
      _categoryId ??= _categories.isNotEmpty ? _categories.first['id']?.toString() : null;
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42P01' || code == 'PGRST202') {
        _videosSupported = false;
        _videosLoadError = 'Vidéos non configurées (table product_videos manquante).';
        _videos.clear();
        _homeVideoFlagSupported = false;
        _videoOnHome.clear();
      } else if (code == '42501') {
        _videosSupported = false;
        _videosLoadError = 'Vidéos non autorisées (RLS Supabase).';
        _videos.clear();
        _homeVideoFlagSupported = false;
        _videoOnHome.clear();
      } else {
        _error = e.toString();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  num? _parsePrice(String v) {
    return Formatters.parseNum(v);
  }

  num? _parseCompareAtPrice(String v) {
    final n = Formatters.parseNum(v);
    return n;
  }

  num? _parseDiameter(String v) {
    return Formatters.parseNum(v);
  }

  int? _parseBestSellerRank(String v) {
    final s = v.trim();
    if (s.isEmpty) return null;
    final n = int.tryParse(s);
    return n;
  }

  Future<void> _syncImagesToProductRow() async {
    if (_productId == null) return;
    await _productsRepo.updateImages(_productId!, _images);
  }

  Future<void> _persistImageOrder() async {
    if (_productId == null) return;
    await _syncImagesToProductRow();
    await _imagesRepo.tryPersistSortOrder(productId: _productId!, urls: _images);
  }

  Future<void> _saveImagesField({bool manageSaving = true}) async {
    if (_productId == null) {
      setState(() => _error = 'Enregistre le produit avant d’ajouter des images.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistre le produit avant d’ajouter des images.')),
      );
      return;
    }
    if (manageSaving) {
      setState(() {
        _saving = true;
        _error = null;
      });
    }
    try {
      await _persistImageOrder();
    } catch (e) {
      setState(() => _error = e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur enregistrement images: $e')),
      );
      rethrow;
    } finally {
      if (manageSaving && mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_brandId == null || _categoryId == null) {
      setState(() => _error = 'Marque et catégorie sont obligatoires.');
      return;
    }

    final price = _parsePrice(_price.text);
    if (price == null) {
      setState(() => _error = 'Prix invalide.');
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'name': _name.text.trim(),
        'brand_id': _brandId,
        'category_id': _categoryId,
        'price': price,
        'compare_at_price': _parseCompareAtPrice(_compareAtPrice.text),
        'is_published': _isPublished,
        'best_seller_rank': _parseBestSellerRank(_bestSellerRank.text),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'images': _images,
        'reference': _reference.text.trim().isEmpty ? null : _reference.text.trim(),
        'material': _material.text.trim().isEmpty ? null : _material.text.trim(),
        'movement': _movement.text.trim().isEmpty ? null : _movement.text.trim(),
        'water_resistance': _waterResistance.text.trim().isEmpty ? null : _waterResistance.text.trim(),
        'diameter': _parseDiameter(_diameter.text),
        'in_stock': _inStock,
        'is_featured': _isFeatured,
      };

      if (_productId == null) {
        final res = await _productsRepo.insertReturningId(payload);
        _productId = res['id']?.toString();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit créé. Tu peux ajouter des images.')),
        );
        setState(() {});
      } else {
        await _productsRepo.update(_productId!, payload);
        if (!mounted) return;
        Navigator.of(context).pop(_productId);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_productId == null) return;
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
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _productsRepo.deleteById(_productId!);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addImageFromPicker() async {
    if (_productId == null) {
      setState(() => _error = 'Enregistre le produit avant d’importer une image.');
      return;
    }

    XFile? file;
    try {
      final picker = ImagePicker();
      file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } catch (e) {
      setState(() => _error = 'Import indisponible sur cet appareil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import indisponible: $e')),
      );
      return;
    }
    if (file == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final bytes = await file.readAsBytes();
      final rnd = Random().nextInt(1 << 32);
      final path = 'products/$_productId/${DateTime.now().millisecondsSinceEpoch}_$rnd.jpg';
      await _storage.uploadProductImage(path: path, bytes: bytes);
      final url = _storage.getPublicUrl(path);
      _images.add(url);
      await _imagesRepo.tryInsert(productId: _productId!, publicUrl: url, storagePath: path, sortOrder: _images.length);
      await _persistImageOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image enregistrée')),
      );
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur image: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addImageUrl() async {
    if (_productId == null) {
      setState(() => _error = 'Enregistre le produit avant d’ajouter des images.');
      return;
    }

    final ctrl = TextEditingController();
    try {
      final url = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ajouter une URL d’image'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'URL'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      );

      final v = (url ?? '').trim();
      if (v.isEmpty) return;

      setState(() => _images.add(v));
      await _imagesRepo.tryInsert(productId: _productId!, publicUrl: v, storagePath: null, sortOrder: _images.length);
      await _persistImageOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image enregistrée')),
      );
      setState(() {});
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _removeImage(String url) async {
    if (_productId == null) return;
    setState(() => _images.remove(url));
    final storagePath = await _imagesRepo.tryGetStoragePath(productId: _productId!, publicUrl: url);
    await _imagesRepo.tryDeleteRow(productId: _productId!, publicUrl: url);
    if (storagePath != null && storagePath.trim().isNotEmpty) {
      await _imagesRepo.tryRemoveStoragePath(storagePath);
    }
    await _persistImageOrder();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Images mises à jour')),
    );
    setState(() {});
  }

  Future<void> _persistVideoOrder() async {
    if (_productId == null) return;
    await _videosRepo.persistSortOrder(productId: _productId!, urls: _videos);
  }

  Future<void> _addVideoFromPicker() async {
    if (_productId == null) {
      setState(() => _error = 'Enregistre le produit avant d’importer une vidéo.');
      return;
    }
    if (!_videosSupported) {
      setState(() => _error = 'Vidéos non configurées côté Supabase.');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: false,
      );
      final path = result?.files.single.path;
      if (path == null || path.trim().isEmpty) return;

      setState(() {
        _saving = true;
        _error = null;
      });

      final rnd = Random().nextInt(1 << 32);
      final storagePath = 'products/$_productId/${DateTime.now().millisecondsSinceEpoch}_$rnd.mp4';
      await _storage.uploadProductVideoFile(path: storagePath, file: File(path));
      final url = _storage.getPublicVideoUrl(storagePath);
      _videos.add(url);
      await _videosRepo.insertVideo(
        productId: _productId!,
        publicUrl: url,
        storagePath: storagePath,
        sortOrder: _videos.length,
      );
      await _persistVideoOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vidéo enregistrée')),
      );
      setState(() {});
    } catch (e) {
      if (_videos.isNotEmpty) {
        _videos.removeLast();
      }
      setState(() => _error = 'Import vidéo indisponible: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur vidéo: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeVideo(String url) async {
    if (_productId == null) return;
    setState(() => _videos.remove(url));
    final storagePath = await _videosRepo.getStoragePath(productId: _productId!, publicUrl: url);
    await _videosRepo.deleteRow(productId: _productId!, publicUrl: url);
    if (storagePath != null && storagePath.trim().isNotEmpty) {
      await _videosRepo.removeStoragePath(storagePath);
    }
    await _persistVideoOrder();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vidéos mises à jour')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _productId != null;
    final canReturnId = widget.productId == null && _productId != null;
    return PopScope(
      canPop: !canReturnId,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (canReturnId) {
          Navigator.of(context).pop(_productId);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Modifier produit' : 'Ajouter produit'),
          actions: [
            if (isEdit)
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline),
                onPressed: _saving ? null : _delete,
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    if (_error != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(labelText: 'Nom'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _brandId,
                            items: _brands
                                .map(
                                  (b) => DropdownMenuItem<String>(
                                    value: b['id']?.toString(),
                                    child: Text(b['name']?.toString() ?? ''),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving ? null : (v) => setState(() => _brandId = v),
                            decoration: const InputDecoration(labelText: 'Marque'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _categoryId,
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c['id']?.toString(),
                                    child: Text(c['name']?.toString() ?? ''),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving ? null : (v) => setState(() => _categoryId = v),
                            decoration: const InputDecoration(labelText: 'Catégorie'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _price,
                            decoration: const InputDecoration(labelText: 'Prix (DH)'),
                            keyboardType: TextInputType.number,
                            validator: (v) => _parsePrice(v ?? '') == null ? 'Prix invalide' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _compareAtPrice,
                            decoration: const InputDecoration(labelText: 'Ancien prix (DH) (optionnel)'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _description,
                            decoration: const InputDecoration(labelText: 'Description'),
                            minLines: 2,
                            maxLines: 5,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _reference,
                            decoration: const InputDecoration(labelText: 'Référence'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _material,
                            decoration: const InputDecoration(labelText: 'Matériau'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _movement,
                            decoration: const InputDecoration(labelText: 'Mouvement'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _waterResistance,
                            decoration: const InputDecoration(labelText: 'Étanchéité'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _diameter,
                            decoration: const InputDecoration(labelText: 'Diamètre (mm)'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            value: _inStock,
                            onChanged: _saving ? null : (v) => setState(() => _inStock = v),
                            title: const Text('En stock'),
                          ),
                          SwitchListTile(
                            value: _isFeatured,
                            onChanged: _saving ? null : (v) => setState(() => _isFeatured = v),
                            title: const Text('Mis en avant'),
                          ),
                          SwitchListTile(
                            value: _isPublished,
                            onChanged: _saving ? null : (v) => setState(() => _isPublished = v),
                            title: const Text('Visible sur le site'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bestSellerRank,
                            decoration: const InputDecoration(labelText: 'Top ventes (rang) (optionnel)'),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Images', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            if (_images.isNotEmpty) ...[
                              SizedBox(
                                height: 220,
                                child: PageView.builder(
                                  itemCount: _images.length,
                                  itemBuilder: (context, index) {
                                    final url = _images[index];
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            Container(color: Colors.white.withValues(alpha: 0.06)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 96,
                                child: ReorderableListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  buildDefaultDragHandles: false,
                                  itemCount: _images.length,
                                  onReorder: _saving
                                      ? (_, __) {}
                                      : (oldIndex, newIndex) async {
                                          if (newIndex > oldIndex) newIndex -= 1;
                                          final moved = _images.removeAt(oldIndex);
                                          _images.insert(newIndex, moved);
                                          setState(() {});
                                          await _saveImagesField();
                                        },
                                  itemBuilder: (context, index) {
                                    final url = _images[index];
                                    return Padding(
                                      key: ValueKey(url),
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: SizedBox(
                                              width: 96,
                                              height: 96,
                                              child: CachedNetworkImage(
                                                imageUrl: url,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) =>
                                                    Container(color: Colors.white.withValues(alpha: 0.06)),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 6,
                                            top: 6,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0A0A0A).withValues(alpha: 0.72),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                              ),
                                              child: ReorderableDragStartListener(
                                                index: index,
                                                child: const Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Icon(Icons.drag_indicator, size: 16),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: IconButton(
                                              icon: const Icon(Icons.close, size: 18),
                                              onPressed: _saving ? null : () => _removeImage(url),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ] else
                              Container(
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                  color: Colors.white.withValues(alpha: 0.04),
                                ),
                                child: const Center(child: Text('Aucune image')),
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _saving ? null : _addImageUrl,
                                  icon: const Icon(Icons.link),
                                  label: const Text('Ajouter URL'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _saving ? null : _addImageFromPicker,
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text('Importer'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Vidéos', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            if (!_videosSupported)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                  color: Colors.white.withValues(alpha: 0.04),
                                ),
                                child: Text(_videosLoadError ?? 'Vidéos non configurées'),
                              )
                            else if (_videos.isEmpty)
                              Container(
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                  color: Colors.white.withValues(alpha: 0.04),
                                ),
                                child: const Center(child: Text('Aucune vidéo')),
                              )
                            else
                              ReorderableListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                buildDefaultDragHandles: false,
                                itemCount: _videos.length,
                                onReorder: _saving
                                    ? (_, __) {}
                                    : (oldIndex, newIndex) async {
                                        if (newIndex > oldIndex) newIndex -= 1;
                                        final moved = _videos.removeAt(oldIndex);
                                        _videos.insert(newIndex, moved);
                                        setState(() {});
                                        await _persistVideoOrder();
                                      },
                                itemBuilder: (context, index) {
                                  final url = _videos[index];
                                  return ListTile(
                                    key: ValueKey(url),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    leading: ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_indicator),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_homeVideoFlagSupported)
                                          IconButton(
                                            tooltip: 'Accueil',
                                            icon: Icon(
                                              (_videoOnHome[url] ?? false)
                                                  ? Icons.home_rounded
                                                  : Icons.home_outlined,
                                              size: 20,
                                            ),
                                            onPressed: _saving
                                                ? null
                                                : () async {
                                                    if (_productId == null) return;
                                                    final current = _videoOnHome[url] ?? false;
                                                    final ok = await _videosRepo.trySetShowOnHome(
                                                      productId: _productId!,
                                                      publicUrl: url,
                                                      showOnHome: !current,
                                                    );
                                                    if (!ok) {
                                                      if (!mounted) return;
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Option accueil indisponible (colonne show_on_home manquante).',
                                                          ),
                                                        ),
                                                      );
                                                      setState(() => _homeVideoFlagSupported = false);
                                                      return;
                                                    }
                                                    setState(() => _videoOnHome[url] = !current);
                                                  },
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 18),
                                          onPressed: _saving ? null : () => _removeVideo(url),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _saving ? null : _addVideoFromPicker,
                                  icon: const Icon(Icons.video_library_outlined),
                                  label: const Text('Importer'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
