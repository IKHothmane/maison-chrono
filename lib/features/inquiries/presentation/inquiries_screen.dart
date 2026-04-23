import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/inquiries_repository.dart';

class InquiriesScreen extends StatefulWidget {
  const InquiriesScreen({super.key});

  @override
  State<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends State<InquiriesScreen> {
  final _repo = const InquiriesRepository();
  int _reload = 0;
  RealtimeChannel? _channel;

  Future<void> _refresh() async {
    setState(() => _reload++);
  }

  @override
  void initState() {
    super.initState();
    _channel = Supabase.instance.client
        .channel('public:inquiries')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'inquiries',
          callback: (payload) {
            if (!mounted) return;
            setState(() => _reload++);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    final c = _channel;
    if (c != null) {
      Supabase.instance.client.removeChannel(c);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_reload),
      future: _repo.listInquiries(),
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
                      Icon(Icons.inbox_rounded, size: 48, color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 12),
                      Text('Aucune demande', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            );
          } else {
            child = ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final i = items[index];
                final name = i['name']?.toString() ?? '';
                final email = i['email']?.toString() ?? '';
                final phone = i['phone']?.toString();
                final city = i['city']?.toString() ?? '';
                final address = i['address']?.toString() ?? '';
                final createdAt = i['created_at']?.toString() ?? '';
                final dateStr = createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      splashColor: const Color(0xFFC9A96E).withValues(alpha: 0.06),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          builder: (context) {
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                  20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: const Color(0xFFC9A96E).withValues(alpha: 0.12),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.person_rounded, size: 20, color: Color(0xFFC9A96E)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                            ),
                                            if (dateStr.isNotEmpty)
                                              Text(
                                                dateStr,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white.withValues(alpha: 0.4),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Contact info
                                  if (email.isNotEmpty || (phone != null && phone.isNotEmpty))
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white.withValues(alpha: 0.04),
                                      ),
                                      child: Column(
                                        children: [
                                          if (email.isNotEmpty)
                                            Row(
                                              children: [
                                                Icon(Icons.email_outlined, size: 16,
                                                    color: Colors.white.withValues(alpha: 0.5)),
                                                const SizedBox(width: 8),
                                                Text(email, style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.7))),
                                              ],
                                            ),
                                          if (email.isNotEmpty && phone != null && phone.isNotEmpty)
                                            const SizedBox(height: 8),
                                          if (phone != null && phone.isNotEmpty)
                                            Row(
                                              children: [
                                                Icon(Icons.phone_outlined, size: 16,
                                                    color: Colors.white.withValues(alpha: 0.5)),
                                                const SizedBox(width: 8),
                                                Text(phone, style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.7))),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  if (city.isNotEmpty || address.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Text(
                                      'Livraison',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        color: const Color(0xFFC9A96E).withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (city.isNotEmpty)
                                      Text(
                                        'Ville: $city',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          height: 1.5,
                                        ),
                                      ),
                                    if (address.isNotEmpty)
                                      Text(
                                        'Adresse: $address',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          height: 1.5,
                                        ),
                                      ),
                                  ],
                                  const SizedBox(height: 14),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFC9A96E).withValues(alpha: 0.1),
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFFC9A96E),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      if (phone != null && phone.isNotEmpty) phone,
                                      if (city.isNotEmpty) city,
                                      if (email.isNotEmpty) email,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
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
    );
  }
}
