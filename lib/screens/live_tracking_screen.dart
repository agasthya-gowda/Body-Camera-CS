import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';
import 'location_history_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _locations = [];
  bool _isLoading = true;
  String? _errorMsg;
  Timer? _refreshTimer;
  String _lastUpdated = '';

  static const LatLng _defaultCenter = LatLng(12.9716, 77.5946);

  bool get _isDark => AppTheme.isDark(context);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadDeviceList();
    await _refreshLocations();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshLocations());
  }

  Future<void> _loadDeviceList() async {
    final result = await _apiService.getOnlineDevices();
    if (result['code'] == 200) {
      final companies = List<Map<String, dynamic>>.from(
        result['data']?['total'] ?? [],
      );
      List<Map<String, dynamic>> devices = [];
      for (var company in companies) {
        if (company['sub'] != null) {
          devices.addAll(List<Map<String, dynamic>>.from(company['sub']));
        }
      }
      setState(() {
        _devices = devices.where((d) => d['lineon']?.toString() == '1').toList();
      });
    }
  }

  Future<void> _refreshLocations() async {
    if (_devices.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'No online devices to track';
      });
      return;
    }

    final ids = _devices.map((d) => d['did'].toString()).toList();
    final result = await _apiService.getRealtimeLocation(ids);

    if (!mounted) return;

    if (result['code'] == 200) {
      final now = DateTime.now();
      setState(() {
        _locations = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _isLoading = false;
        _errorMsg = null;
        _lastUpdated =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMsg = result['msg']?.toString() ?? 'Failed to load locations';
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  LatLng _mapCenter() {
    if (_locations.isEmpty) return _defaultCenter;
    final lat = double.tryParse(_locations[0]['lat'].toString()) ?? _defaultCenter.latitude;
    final lng = double.tryParse(_locations[0]['lng'].toString()) ?? _defaultCenter.longitude;
    return LatLng(lat, lng);
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: _isDark ? Colors.white : const Color(0xFF0A1628), size: 16),
      ),
    );
  }

  void _selectOfficer(String deviceId, String officerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationHistoryScreen(hostbody: deviceId, officerName: officerName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF0A1628) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(bottom: BorderSide(color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(Icons.arrow_back, color: _isDark ? Colors.white : const Color(0xFF0A1628), size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Live GPS Tracking',
                                style: TextStyle(
                                    color: _isDark ? Colors.white : const Color(0xFF0A1628),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Color(0xFF4A9EFF), shape: BoxShape.circle),
                            ),
                          ],
                        ),
                        Text('5s Polling • Updated $_lastUpdated',
                            style: TextStyle(color: _isDark ? Colors.white38 : Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _refreshLocations,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A9EFF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A9EFF)),
                                )
                              : const Icon(Icons.refresh, size: 16, color: Color(0xFF4A9EFF)),
                          const SizedBox(width: 6),
                          const Text('Refresh',
                              style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMsg != null)
              Container(
                width: double.infinity,
                color: Colors.orange.withOpacity(0.15),
                padding: const EdgeInsets.all(10),
                child: Text(_errorMsg!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A9EFF)))
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _mapCenter(),
                            initialZoom: 15,
                            minZoom: 10,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.chipscape.bwc_app',
                            ),
                            MarkerLayer(
                              markers: _locations.map((loc) {
                                final lat = double.tryParse(loc['lat'].toString()) ?? 0.0;
                                final lng = double.tryParse(loc['lng'].toString()) ?? 0.0;
                                final name = loc['name']?.toString() ?? 'Unknown';
                                final deviceId = loc['id']?.toString() ?? '';
                                return Marker(
                                  point: LatLng(lat, lng),
                                  width: 120,
                                  height: 60,
                                  child: GestureDetector(
                                    onTap: () => _selectOfficer(deviceId, name),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _isDark ? const Color(0xFF0A1628) : Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                                color: _isDark ? Colors.white : const Color(0xFF0A1628),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.location_on, color: Colors.redAccent, size: 34),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.navigation, size: 13, color: Color(0xFF4A9EFF)),
                                    const SizedBox(width: 5),
                                    Text('ACTIVE PATROL BEACONS (${_locations.length})',
                                        style: const TextStyle(
                                            color: Color(0xFF4A9EFF),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace')),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text('Tap any marker to inspect historical route',
                                    style: TextStyle(color: _isDark ? Colors.white38 : Colors.grey[500], fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Column(
                            children: [
                              _zoomButton(Icons.add, () {
                                final zoom = _mapController.camera.zoom;
                                _mapController.move(_mapController.camera.center, zoom + 1);
                              }),
                              const SizedBox(height: 6),
                              _zoomButton(Icons.remove, () {
                                final zoom = _mapController.camera.zoom;
                                _mapController.move(_mapController.camera.center, zoom - 1);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(top: BorderSide(color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIVE FIELD UNITS IN SECTOR',
                      style: TextStyle(
                          color: _isDark ? Colors.white38 : Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _locations.isEmpty
                        ? Center(
                            child: Text('No active units',
                                style: TextStyle(color: _isDark ? Colors.white38 : Colors.grey[500], fontSize: 12)))
                        : ListView.builder(
                            itemCount: _locations.length,
                            itemBuilder: (context, index) {
                              final loc = _locations[index];
                              final name = loc['name']?.toString() ?? 'Unknown';
                              final deviceId = loc['id']?.toString() ?? '';
                              return GestureDetector(
                                onTap: () => _selectOfficer(deviceId, name),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4A9EFF).withOpacity(0.15),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.3)),
                                        ),
                                        child: const Icon(Icons.podcasts, size: 16, color: Color(0xFF4A9EFF)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('$name (BWC-$deviceId)',
                                                style: TextStyle(
                                                    color: _isDark ? Colors.white : const Color(0xFF0A1628),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12),
                                                overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            const Row(
                                              children: [
                                                Text('Live',
                                                    style: TextStyle(
                                                        color: Colors.greenAccent,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Text('History',
                                          style: TextStyle(
                                              color: Color(0xFF4A9EFF), fontSize: 11, fontWeight: FontWeight.w600)),
                                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFF4A9EFF)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}