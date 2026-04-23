import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../data/promos_repository.dart';
import 'product_picker_screen.dart';

class PromoCreateScreen extends StatefulWidget {
  const PromoCreateScreen({super.key});

  @override
  State<PromoCreateScreen> createState() => _PromoCreateScreenState();
}

class _PromoCreateScreenState extends State<PromoCreateScreen> {
  final _repo = const PromosRepository();
  final _code = TextEditingController();
  final _value = TextEditingController();

  String _type = 'percent';
  bool _saving = false;
  String? _error;
  final _selectedProductIds = <String>{};

  @override
  void dispose() {
    _code.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _pickProducts() async {
    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => ProductPickerScreen(initialSelectedIds: _selectedProductIds),
      ),
    );
    if (selected == null) return;
    setState(() {
      _selectedProductIds
        ..clear()
        ..addAll(selected);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _error = null);

    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Code obligatoire.');
      return;
    }

    final n = Formatters.parseNum(_value.text);
    if (n == null || n <= 0) {
      setState(() => _error = 'Valeur invalide.');
      return;
    }

    setState(() => _saving = true);
    try {
      final promo = await _repo.createPromoCode(
        code: code,
        discountPercent: _type == 'percent' ? n.round() : null,
        discountAmount: _type == 'amount' ? n : null,
        maxUses: 1,
        startsAt: null,
        endsAt: null,
        isActive: true,
      );

      await _repo.setPromoProducts(
        promoCodeId: promo['id']?.toString() ?? '',
        productIds: _selectedProductIds.toList(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _selectedProductIds.isEmpty ? 'Tous les produits' : '${_selectedProductIds.length} produits';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer promo'),
      ),
      body: Padding(
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
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Code (ex: MAISON10)'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'percent', label: Text('%')),
                ButtonSegment(value: 'amount', label: Text('-DH')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _value,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: _type == 'percent' ? 'Pourcentage' : 'Montant (DH)'),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Valable une seule fois'),
                subtitle: const Text('Max utilisations = 1'),
                trailing: const Icon(Icons.check_circle),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Produits'),
                subtitle: Text(selectedLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickProducts,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Enregistrement…' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

