import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AutoImagePager extends StatefulWidget {
  const AutoImagePager({super.key, required this.imageUrls, this.interval = const Duration(seconds: 3)});

  final List<String> imageUrls;
  final Duration interval;

  @override
  State<AutoImagePager> createState() => _AutoImagePagerState();
}

class _AutoImagePagerState extends State<AutoImagePager> {
  late PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _initController();
    _start();
  }

  @override
  void didUpdateWidget(covariant AutoImagePager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length) {
      _timer?.cancel();
      _timer = null;
      _controller.dispose();
      _initController();
      _restart();
    }
  }

  void _initController() {
    final len = widget.imageUrls.length;
    final startPage = len <= 1 ? 0 : len * 1000;
    _page = startPage;
    _controller = PageController(initialPage: startPage);
  }

  void _restart() {
    _timer?.cancel();
    _timer = null;
    _start();
  }

  void _start() {
    if (widget.imageUrls.length <= 1) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      if (!_controller.hasClients) return;
      if (widget.imageUrls.length <= 1) return;
      final next = _page + 1;
      _page = next;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final len = widget.imageUrls.length;
    return PageView.builder(
      controller: _controller,
      onPageChanged: (value) => _page = value,
      itemBuilder: (context, pageIndex) {
        return CachedNetworkImage(
          imageUrl: len == 0 ? '' : widget.imageUrls[pageIndex % len],
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        );
      },
    );
  }
}
