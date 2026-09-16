import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../services/api_service.dart';

// ── Brand constants ──
const Color _kBrandNavy = Color(0xFF0A1628);

// Exact cubic-bezier curves from the reference animation
const Curve _kEaseOutQuint = Cubic(0.22, 1.0, 0.36, 1.0);
const Curve _kMaterialStandard = Cubic(0.4, 0.0, 0.2, 1.0);
const Curve _kEaseInAccelerate = Cubic(0.55, 0.055, 0.675, 0.19);

enum _SplashPhase {
  blankWhite,
  fallingLines,
  ballAndText,
  assembledRest,
  logoZoom,
}

class _WaferBar {
  final double width;
  final double y;
  final Color color;
  final Color darkColor;
  const _WaferBar({
    required this.width,
    required this.y,
    required this.color,
    required this.darkColor,
  });
}

// 7 layered wafer bars from top (widest, light blue) to bottom (narrowest, dark navy)
const List<_WaferBar> _kWaferBars = [
  _WaferBar(
    width: 140,
    y: 72,
    color: Color(0xFF68D8D6),
    darkColor: Color(0xFF60C5F8),
  ),
  _WaferBar(
    width: 126,
    y: 86,
    color: Color(0xFF4EA8DE),
    darkColor: Color(0xFF3B86F7),
  ),
  _WaferBar(
    width: 112,
    y: 100,
    color: Color(0xFF3A86FF),
    darkColor: Color(0xFF2563EB),
  ),
  _WaferBar(
    width: 98,
    y: 114,
    color: Color(0xFF1D63E8),
    darkColor: Color(0xFF1D4ED8),
  ),
  _WaferBar(
    width: 84,
    y: 128,
    color: Color(0xFF134EC2),
    darkColor: Color(0xFF1E40AF),
  ),
  _WaferBar(
    width: 70,
    y: 142,
    color: Color(0xFF0D3B94),
    darkColor: Color(0xFF1A365D),
  ),
  _WaferBar(
    width: 56,
    y: 156,
    color: Color(0xFF061C48),
    darkColor: Color(0xFF102A43),
  ),
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  _SplashPhase _phase = _SplashPhase.blankWhite;
  final List<Timer> _timers = [];

  // Bars: staggered fall, each 650ms, 180ms apart -> total span 1730ms
  late final AnimationController _linesController;

  // Ball + Wordmark: both 850ms, same ease
  late final AnimationController _ballTextController;

  // Zoom-out reveal: 1100ms umbrella controlling bg color, wave, logo scale/opacity
  late final AnimationController _zoomController;
  late final Animation<double> _bgFraction;
  late final Animation<double> _waveScale;
  late final Animation<double> _waveOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  bool get _barsVisible => _phase.index >= _SplashPhase.fallingLines.index;
  bool get _ballTextVisible => _phase.index >= _SplashPhase.ballAndText.index;
  bool get _isDark => _phase == _SplashPhase.logoZoom;

  // Kicked off immediately so it resolves well before the animation ends,
  // meaning re-opening the app doesn't feel slower even though it now checks
  // for a still-valid saved session.
  late final Future<bool> _sessionRestore = ApiService.restoreSession();

  @override
  void initState() {
    super.initState();

    _linesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1730),
    );
    _ballTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _bgFraction = CurvedAnimation(
      parent: _zoomController,
      curve: const Interval(0.0, 0.8636, curve: _kMaterialStandard),
    );
    _waveScale = Tween<double>(begin: 0.2, end: 32.0).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: const Interval(0.0, 0.9545, curve: _kMaterialStandard),
      ),
    );
    _waveOpacity = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: const Interval(0.0, 0.9545, curve: _kMaterialStandard),
      ),
    );
    _logoScale = Tween<double>(begin: 1.0, end: 30.0).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: const Interval(0.0, 1.0, curve: _kEaseInAccelerate),
      ),
    );
    _logoOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: const Interval(0.0909, 0.9545, curve: Curves.linear),
      ),
    );

    _runSequence();
  }

  void _runSequence() {
    // 0ms: blank white (initial state already set)

    // 500ms: bars start falling
    _timers.add(
      Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() => _phase = _SplashPhase.fallingLines);
        _linesController.forward(from: 0);
      }),
    );

    // 2400ms: ball drops + wordmark rises
    _timers.add(
      Timer(const Duration(milliseconds: 2400), () {
        if (!mounted) return;
        setState(() => _phase = _SplashPhase.ballAndText);
        _ballTextController.forward(from: 0);
      }),
    );

    // 3350ms: assembled logo rests
    _timers.add(
      Timer(const Duration(milliseconds: 3350), () {
        if (!mounted) return;
        setState(() => _phase = _SplashPhase.assembledRest);
      }),
    );

    // 4550ms: zoom + background transition to navy
    _timers.add(
      Timer(const Duration(milliseconds: 4550), () {
        if (!mounted) return;
        setState(() => _phase = _SplashPhase.logoZoom);
        _zoomController.forward(from: 0);
      }),
    );

    // 5650ms: reveal login (or the dashboard directly, if a saved session is
    // still valid) - no extra fade, matches reference.
    _timers.add(
      Timer(const Duration(milliseconds: 5650), () async {
        final hasValidSession = await _sessionRestore;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) =>
                hasValidSession ? const DashboardScreen() : const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _linesController.dispose();
    _ballTextController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _linesController,
        _ballTextController,
        _zoomController,
      ]),
      builder: (context, child) {
        final bgColor = _phase == _SplashPhase.logoZoom
            ? Color.lerp(Colors.white, _kBrandNavy, _bgFraction.value)!
            : Colors.white;

        return Scaffold(
          backgroundColor: bgColor,
          body: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Radial dark expansion wave (only during logoZoom) ──
                if (_phase == _SplashPhase.logoZoom)
                  Opacity(
                    opacity: _waveOpacity.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _waveScale.value,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: const BoxDecoration(
                          color: _kBrandNavy,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                // ── Logo choreography stage ──
                Opacity(
                  opacity: _phase == _SplashPhase.logoZoom
                      ? _logoOpacity.value.clamp(0.0, 1.0)
                      : 1.0,
                  child: Transform.scale(
                    scale: _phase == _SplashPhase.logoZoom
                        ? _logoScale.value
                        : 1.0,
                    child: Transform.scale(
                      scale: 1.35, // 'lg' size factor from reference
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIcon(),
                          const SizedBox(height: 12),
                          _buildWordmark(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    return SizedBox(
      width: 180,
      height: 185,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ambient glow
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withOpacity(0.30),
                    const Color(0xFF2563EB).withOpacity(0.14),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 0.75],
                ),
              ),
            ),
          ),

          // 7 wafer bars — fall in staggered from top
          for (int i = 0; i < _kWaferBars.length; i++) _buildBar(i),

          // Top orb — falls after bars
          _buildOrb(),
        ],
      ),
    );
  }

  Widget _buildBar(int idx) {
    final bar = _kWaferBars[idx];
    final startFraction = (idx * 180) / 1730;
    final endFraction = (idx * 180 + 650) / 1730;
    final t = _barsVisible
        ? CurvedAnimation(
            parent: _linesController,
            curve: Interval(
              startFraction.clamp(0.0, 1.0),
              endFraction.clamp(0.0, 1.0),
              curve: _kEaseOutQuint,
            ),
          ).value
        : 0.0;

    final dy = (1 - t) * -650;
    final x = 90 - bar.width / 2;

    return Positioned(
      left: x,
      top: bar.y + dy,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Container(
          width: bar.width,
          height: 8.5,
          decoration: BoxDecoration(
            color: _isDark ? bar.darkColor : bar.color,
            borderRadius: BorderRadius.circular(4.25),
          ),
        ),
      ),
    );
  }

  Widget _buildOrb() {
    final t = _ballTextVisible
        ? CurvedAnimation(
            parent: _ballTextController,
            curve: _kEaseOutQuint,
          ).value
        : 0.0;
    final dy = (1 - t) * -700;

    return Positioned(
      left: 66,
      top: 12 + dy,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDark
                  ? const [
                      Color(0xFFA5F3FC),
                      Color(0xFF67E8F9),
                      Color(0xFF38BDF8),
                    ]
                  : const [
                      Color(0xFF38BDF8),
                      Color(0xFF0EA5E9),
                      Color(0xFF0284C7),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordmark() {
    final t = _ballTextVisible
        ? CurvedAnimation(
            parent: _ballTextController,
            curve: _kEaseOutQuint,
          ).value
        : 0.0;
    final dy = (1 - t) * 450;

    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, dy),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Chip',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: _isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              TextSpan(
                text: 'Scape',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: _isDark ? Colors.white : _kBrandNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
