import 'package:flutter/material.dart';

import '../data/dashboard_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  final void Function(int toIndex) onNavigate;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = const DashboardRepository();
  int _reload = 0;

  Future<void> _refresh() async {
    setState(() => _reload++);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _greetingLine() {
    return '${_greeting()} EL MIOROUN OUSSAMA';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      key: ValueKey(_reload),
      future: _repo.loadCounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return RefreshIndicator(
            color: const Color(0xFFC9A96E),
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 240),
                Center(child: CircularProgressIndicator()),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return RefreshIndicator(
            color: const Color(0xFFC9A96E),
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(snapshot.error.toString()),
              ],
            ),
          );
        }

        final counts = snapshot.data ?? const {'products': 0, 'inquiries': 0};

        return RefreshIndicator(
          color: const Color(0xFFC9A96E),
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              // Greeting header
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingLine(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 26,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MAISON CHRONO · Admin',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFC9A96E).withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats grid
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 2 : 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatCard(
                    title: 'Produits',
                    value: counts['products']?.toString() ?? '0',
                    icon: Icons.watch_rounded,
                    gradient: const [Color(0xFF1E3A2F), Color(0xFF0D1F18)],
                    accentColor: const Color(0xFF4CAF50),
                    onTap: () => widget.onNavigate(1),
                    index: 0,
                  ),
                  _StatCard(
                    title: 'Demandes',
                    value: counts['inquiries']?.toString() ?? '0',
                    icon: Icons.mail_rounded,
                    gradient: const [Color(0xFF2A2215), Color(0xFF1A150D)],
                    accentColor: const Color(0xFFC9A96E),
                    onTap: () => widget.onNavigate(3),
                    index: 1,
                  ),
                  _StatCard(
                    title: 'Promos',
                    value: '',
                    icon: Icons.local_offer_rounded,
                    gradient: const [Color(0xFF1A1A2E), Color(0xFF10101C)],
                    accentColor: const Color(0xFF7C4DFF),
                    onTap: () => widget.onNavigate(2),
                    index: 2,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    this.onTap,
    this.index = 0,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback? onTap;
  final int index;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    ));

    Future.delayed(Duration(milliseconds: 100 + widget.index * 120), () {
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(18),
              splashColor: widget.accentColor.withValues(alpha: 0.08),
              highlightColor: widget.accentColor.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: widget.accentColor.withValues(alpha: 0.12),
                      ),
                      child: Icon(widget.icon, size: 24, color: widget.accentColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (widget.value.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.value,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: widget.accentColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.3),
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
