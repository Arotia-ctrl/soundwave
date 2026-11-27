import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/navigation/main_shell.dart';
import '../../../core/theme/app_colors.dart';

/// Affiche l'animation, puis passe en fondu à l'application.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _done
          ? const MainShell(key: ValueKey('main'))
          : SplashScreen(
              key: const ValueKey('splash'),
              onFinished: () {
                if (mounted) setState(() => _done = true);
              },
            ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Durée totale. L'animation occupe les 85 premiers %, le reste est une
  // courte pause sur l'image finale. Réduis la valeur pour un démarrage plus vif.
  static const int _totalMs = 2600;
  static const double _animatedPart = 0.85;

  // Logo du pied de page
  static const String _footerLogo = 'assets/images/footer_logo.png';
  static const double _footerLogoHeight = 40;

  late final AnimationController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: _totalMs),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _finish();
        });
    _controller.forward();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish, // un toucher passe l'animation
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = (_controller.value / _animatedPart).clamp(0.0, 1.0);
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 90,
                        child: CustomPaint(painter: _BarsPainter(t)),
                      ),
                      const SizedBox(height: 36),
                      _Wordmark(t: t),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: Curves.easeOut.transform(
                          ((t - 0.8) / 0.17).clamp(0.0, 1.0),
                        ),
                        child: const Text(
                          appTagline,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Logo en pied de page, qui apparaît en fondu
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Opacity(
                        opacity: Curves.easeOut.transform(
                          ((t - 0.6) / 0.25).clamp(0.0, 1.0),
                        ),
                        child: Image.asset(
                          _footerLogo,
                          height: _footerLogoHeight,
                          // Si le fichier est absent ou mal nommé : rien ne s'affiche,
                          // mais l'application ne plante pas
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Le mot SOUNDWAVE : les lettres apparaissent l'une après l'autre.
class _Wordmark extends StatelessWidget {
  final double t;
  const _Wordmark({required this.t});

  static const String _word = 'SOUNDWAVE';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < _word.length; i++) _letter(i)],
    );
  }

  Widget _letter(int i) {
    final start = 0.45 + i * 0.04;
    final p = Curves.easeOutCubic.transform(
      ((t - start) / 0.2).clamp(0.0, 1.0),
    );
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, (1 - p) * 14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: Text(
            _word[i],
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              // SOUND en blanc, WAVE en violet clair
              color: i < 5 ? AppColors.text : AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sept barres d'égaliseur : elles dansent, puis se calent en une forme
/// symétrique qui sert de logo.
class _BarsPainter extends CustomPainter {
  final double t;
  const _BarsPainter(this.t);

  static const List<double> _finalShape = [
    0.35,
    0.6,
    0.85,
    1.0,
    0.85,
    0.6,
    0.35,
  ];
  static const double _barWidth = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final n = _finalShape.length;
    final gap = (size.width - n * _barWidth) / (n - 1);
    final appear = Curves.easeOut.transform((t / 0.2).clamp(0.0, 1.0));
    final settle = Curves.easeInOut.transform(
      ((t - 0.55) / 0.3).clamp(0.0, 1.0),
    );

    final paint = Paint()
      ..strokeWidth = _barWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < n; i++) {
      final wave = 0.3 + 0.7 * sin(t * 2 * pi * 3 + i * 0.8).abs();
      final height =
          size.height *
          ((1 - settle) * wave + settle * _finalShape[i]) *
          appear;
      final x = i * (_barWidth + gap) + _barWidth / 2;
      final cy = size.height / 2;

      paint.color = Color.lerp(
        AppColors.primary,
        AppColors.accent,
        i / (n - 1),
      )!;
      canvas.drawLine(
        Offset(x, cy - height / 2),
        Offset(x, cy + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.t != t;
}
