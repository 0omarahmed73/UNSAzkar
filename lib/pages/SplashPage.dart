import 'dart:async';

import 'package:azkar_new_app/design/tokens.dart';
import 'package:azkar_new_app/pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  static String id = 'SplashPage';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.93, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FlutterNativeSplash.remove();
      if (!mounted) return;
      final reduced = MediaQuery.disableAnimationsOf(context);
      if (reduced) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      } else {
        await _controller.forward();
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomePage.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.navy : AppColors.ivory;
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icon-generated/splash/splash_1024.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.mosque_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'أُنس | UNS',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text('رفيق يومك',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
