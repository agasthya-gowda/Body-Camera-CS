import 'dart:async';
import 'package:flutter/material.dart';
import '../theme_controller.dart';

const Color kHeaderBannerStart = Color(0xFF1A3A6B);

/// Shared top header (company logo + live clock) used on the Dashboard and
/// any other top-level screen, e.g. Settings, that should look the same.
/// Pass [onBack] to also show a back arrow before the logo.
class AppHeader extends StatefulWidget {
  final VoidCallback? onBack;
  const AppHeader({super.key, this.onBack});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  bool get _isDark => AppTheme.isDark(context);

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: _isDark ? kHeaderBannerStart : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.onBack != null) ...[
            IconButton(
              onPressed: widget.onBack,
              icon: Icon(
                Icons.arrow_back,
                color: _isDark ? Colors.white : kHeaderBannerStart,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                'assets/images/chipscape_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Chip',
                        style: TextStyle(
                          color: _isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      TextSpan(
                        text: 'Scape',
                        style: TextStyle(
                          color: _isDark ? Colors.white : kHeaderBannerStart,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Security Management System',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _isDark ? const Color(0xFF9FC1FF) : Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildHeaderClock(),
        ],
      ),
    );
  }

  Widget _buildHeaderClock() {
    String p2(int n) => n.toString().padLeft(2, '0');
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hh = p2(_now.hour);
    final mm = p2(_now.minute);
    final ss = p2(_now.second);
    final weekday = weekdays[_now.weekday - 1];
    final restOfDate = ', ${months[_now.month - 1]} ${_now.day}';
    // Same rounded capsule treatment in both themes - cyan on a dark-tinted
    // pill in dark mode, blue on a soft-blue pill in light mode.
    const lightClockAccent = Color(0xFF2F6FE0);
    const darkClockAccent = Color(0xFF4DE8E0);
    final clockColor = _isDark ? darkClockAccent : lightClockAccent;
    final clockText = Text(
      '$hh:$mm:$ss',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        fontFamily: 'monospace',
        letterSpacing: 0.5,
        color: clockColor,
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: clockColor.withOpacity(_isDark ? 0.15 : 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time_filled, size: 13, color: clockColor),
              const SizedBox(width: 5),
              clockText,
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: weekday,
                style: TextStyle(
                  color: _isDark ? Colors.white : kHeaderBannerStart,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: restOfDate,
                style: TextStyle(color: _isDark ? Colors.white : kHeaderBannerStart),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
