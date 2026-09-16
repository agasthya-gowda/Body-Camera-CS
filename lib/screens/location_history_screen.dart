// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import '../services/api_service.dart';

// class LocationHistoryScreen extends StatefulWidget {
//   final String hostbody; // device SN, e.g. "0300098"
//   final String officerName;

//   const LocationHistoryScreen({super.key, required this.hostbody, required this.officerName});

//   @override
//   State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
// }

// class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
//   final ApiService _apiService = ApiService();
//   final MapController _mapController = MapController();

//   DateTime _startTime = DateTime.now().subtract(const Duration(hours: 2));
//   DateTime _endTime = DateTime.now();

//   List<Map<String, dynamic>> _points = [];
//   Map<String, dynamic> _measure = {};
//   bool _isLoading = false;
//   String? _errorMsg;

//   @override
//   void initState() {
//     super.initState();
//     _loadHistory();
//   }

//   Future<void> _loadHistory() async {
//     setState(() {
//       _isLoading = true;
//       _errorMsg = null;
//     });

//     final startTs = (_startTime.millisecondsSinceEpoch ~/ 1000).toString();
//     final endTs = (_endTime.millisecondsSinceEpoch ~/ 1000).toString();

//     final result = await _apiService.getGpsHistory(
//       historyHostbody: widget.hostbody,
//       startIn: startTs,
//       endIn: endTs,
//     );

//     if (!mounted) return;

//     if (result['code'] == 200) {
//       final data = result['data'] ?? {};
//       setState(() {
//         _points = List<Map<String, dynamic>>.from(data['gpsarray'] ?? []);
//         _measure = Map<String, dynamic>.from(data['measure'] ?? {});
//         _isLoading = false;
//       });
//       if (_points.isNotEmpty) {
//         final last = _points.last;
//         final lat = double.tryParse(last['lat'].toString()) ?? 12.9716;
//         final lng = double.tryParse(last['lng'].toString()) ?? 77.5946;
//         // Delay until after the current frame so FlutterMap has finished
//         // its first build before we try to move it (fixes "widget not
//         // rendered yet" crash when history loads during initState)
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             _mapController.move(LatLng(lat, lng), 15);
//           }
//         });
//       }
//     } else {
//       setState(() {
//         _isLoading = false;
//         _errorMsg = result['msg']?.toString() ?? 'Failed to load history';
//       });
//     }
//   }

//   Future<void> _pickDateTime({required bool isStart}) async {
//     final initial = isStart ? _startTime : _endTime;
//     final date = await showDatePicker(
//       context: context,
//       initialDate: initial,
//       firstDate: DateTime.now().subtract(const Duration(days: 90)),
//       lastDate: DateTime.now(),
//     );
//     if (date == null || !mounted) return;

//     final time = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.fromDateTime(initial),
//     );
//     if (time == null) return;

//     final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
//     setState(() {
//       if (isStart) {
//         _startTime = combined;
//       } else {
//         _endTime = combined;
//       }
//     });
//   }

//   List<LatLng> get _routePoints {
//     return _points.map((p) {
//       final lat = double.tryParse(p['lat'].toString()) ?? 0.0;
//       final lng = double.tryParse(p['lng'].toString()) ?? 0.0;
//       return LatLng(lat, lng);
//     }).toList();
//   }

//   String _formatDateTime(DateTime dt) {
//     return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
//         '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: Text('${widget.officerName} — Route History',
//             style: const TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () => _pickDateTime(isStart: true),
//                     icon: const Icon(Icons.access_time, size: 16),
//                     label: Text('From: ${_formatDateTime(_startTime)}', style: const TextStyle(fontSize: 11)),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () => _pickDateTime(isStart: false),
//                     icon: const Icon(Icons.access_time, size: 16),
//                     label: Text('To: ${_formatDateTime(_endTime)}', style: const TextStyle(fontSize: 11)),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _isLoading ? null : _loadHistory,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF1A3A6B),
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Icon(Icons.search, size: 18),
//                 ),
//               ],
//             ),
//           ),
//           if (_errorMsg != null)
//             Container(
//               width: double.infinity,
//               color: Colors.orange[50],
//               padding: const EdgeInsets.all(10),
//               child: Text(_errorMsg!, style: const TextStyle(color: Colors.orange)),
//             ),
//           Expanded(
//             flex: 3,
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _points.isEmpty
//                     ? const Center(child: Text('No GPS history in this time range'))
//                     : FlutterMap(
//                         mapController: _mapController,
//                         options: MapOptions(
//                           initialCenter: _routePoints.isNotEmpty ? _routePoints.last : const LatLng(12.9716, 77.5946),
//                           initialZoom: 15,
//                           minZoom: 5,
//                         ),
//                         children: [
//                           TileLayer(
//                             urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                             userAgentPackageName: 'com.chipscape.bwc_app',
//                           ),
//                           PolylineLayer(
//                             polylines: [
//                               Polyline(points: _routePoints, strokeWidth: 4, color: const Color(0xFF1A3A6B)),
//                             ],
//                           ),
//                           MarkerLayer(
//                             markers: [
//                               if (_routePoints.isNotEmpty)
//                                 Marker(
//                                   point: _routePoints.first,
//                                   width: 30,
//                                   height: 30,
//                                   child: const Icon(Icons.flag, color: Colors.green, size: 28),
//                                 ),
//                               if (_routePoints.isNotEmpty)
//                                 Marker(
//                                   point: _routePoints.last,
//                                   width: 30,
//                                   height: 30,
//                                   child: const Icon(Icons.location_on, color: Colors.red, size: 32),
//                                 ),
//                             ],
//                           ),
//                         ],
//                       ),
//           ),
//           if (_measure.isNotEmpty)
//             Container(
//               width: double.infinity,
//               color: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Text(
//                 'Speed thresholds (km/h) — Walk: <${_measure['walk']} · Bike: <${_measure['bike']} · Car: >${_measure['car']}',
//                 style: TextStyle(color: Colors.grey[600], fontSize: 11),
//               ),
//             ),
//           Expanded(
//             flex: 2,
//             child: _points.isEmpty
//                 ? const SizedBox.shrink()
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(12),
//                     itemCount: _points.length,
//                     itemBuilder: (context, index) {
//                       final p = _points[index];
//                       final isLbs = p['islbs'] == '1';
//                       return Card(
//                         margin: const EdgeInsets.only(bottom: 6),
//                         child: ListTile(
//                           dense: true,
//                           leading: Icon(
//                             isLbs ? Icons.cell_tower : Icons.gps_fixed,
//                             color: isLbs ? Colors.orange : Colors.green,
//                             size: 20,
//                           ),
//                           title: Text(p['gpstime']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
//                           subtitle: Text(
//                             'Lat: ${p['lat']}, Lng: ${p['lng']} · ${isLbs ? "Estimated (cell)" : "GPS fix"}',
//                             style: const TextStyle(fontSize: 11),
//                           ),
//                           trailing: Text('${p['speed']} km/h', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';

class LocationHistoryScreen extends StatefulWidget {
  final String hostbody;
  final String officerName;

  const LocationHistoryScreen({super.key, required this.hostbody, required this.officerName});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  bool get _isDark => AppTheme.isDark(context);

  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 3));
  DateTime _endTime = DateTime.now();

  List<Map<String, dynamic>> _points = [];
  Map<String, dynamic> _measure = {};
  bool _isLoading = false;
  String? _errorMsg;
  String? _selectedPointId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final startTs = (_startTime.millisecondsSinceEpoch ~/ 1000).toString();
    final endTs = (_endTime.millisecondsSinceEpoch ~/ 1000).toString();

    final result = await _apiService.getGpsHistory(
      historyHostbody: widget.hostbody,
      startIn: startTs,
      endIn: endTs,
    );

    if (!mounted) return;

    if (result['code'] == 200) {
      final data = result['data'] ?? {};
      setState(() {
        _points = List<Map<String, dynamic>>.from(data['gpsarray'] ?? []);
        _measure = Map<String, dynamic>.from(data['measure'] ?? {});
        _isLoading = false;
      });
      if (_points.isNotEmpty) {
        final last = _points.last;
        final lat = double.tryParse(last['lat'].toString()) ?? 12.9716;
        final lng = double.tryParse(last['lng'].toString()) ?? 77.5946;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(LatLng(lat, lng), 15);
          }
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMsg = result['msg']?.toString() ?? 'Failed to load history';
      });
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = combined;
      } else {
        _endTime = combined;
      }
    });
  }

  List<LatLng> get _routePoints {
    return _points.map((p) {
      final lat = double.tryParse(p['lat'].toString()) ?? 0.0;
      final lng = double.tryParse(p['lng'].toString()) ?? 0.0;
      return LatLng(lat, lng);
    }).toList();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _speedColor(double speed) {
    if (speed < 5) return const Color(0xFF60A5FA);
    if (speed < 15) return Colors.amberAccent;
    return Colors.redAccent;
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
                        Text('Location History',
                            style: TextStyle(
                                color: _isDark ? Colors.white : const Color(0xFF0A1628),
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: '${widget.officerName} • ',
                                  style: TextStyle(color: _isDark ? Colors.white38 : Colors.grey[500], fontSize: 11)),
                              TextSpan(
                                  text: 'BWC-${widget.hostbody}',
                                  style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(bottom: BorderSide(color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _dateField('From Timestamp', _startTime, () => _pickDateTime(isStart: true))),
                      const SizedBox(width: 10),
                      Expanded(child: _dateField('To Timestamp', _endTime, () => _pickDateTime(isStart: false))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadHistory,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search, size: 16),
                      label: Text(_isLoading ? 'Querying Patrol Trail...' : 'Search Location Route',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: _isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _legendItem(Icons.directions_walk, 'Walk <5 km/h', const Color(0xFF60A5FA)),
                  Text('•', style: TextStyle(color: Colors.grey.withOpacity(0.4))),
                  _legendItem(Icons.pedal_bike, 'Bike <15 km/h', Colors.amberAccent),
                  Text('•', style: TextStyle(color: Colors.grey.withOpacity(0.4))),
                  _legendItem(Icons.directions_car, 'Car >15 km/h', Colors.redAccent),
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
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A9EFF)))
                      : _points.isEmpty
                          ? Center(
                              child: Text('No GPS telemetry points found in selected time range.',
                                  style: TextStyle(color: _isDark ? Colors.white38 : Colors.grey[500], fontSize: 12)))
                          : FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter:
                                    _routePoints.isNotEmpty ? _routePoints.last : const LatLng(12.9716, 77.5946),
                                initialZoom: 15,
                                minZoom: 10,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.chipscape.bwc_app',
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(points: _routePoints, strokeWidth: 4, color: const Color(0xFF4A9EFF)),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    if (_routePoints.isNotEmpty)
                                      Marker(
                                        point: _routePoints.first,
                                        width: 30,
                                        height: 30,
                                        child: const Icon(Icons.flag, color: Colors.greenAccent, size: 28),
                                      ),
                                    if (_routePoints.isNotEmpty)
                                      Marker(
                                        point: _routePoints.last,
                                        width: 30,
                                        height: 30,
                                        child: const Icon(Icons.location_on, color: Colors.redAccent, size: 32),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                  if (_points.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            _dotLabel(Colors.greenAccent, 'Start'),
                            const SizedBox(width: 10),
                            _dotLabel(Colors.redAccent, 'End'),
                          ],
                        ),
                      ),
                    ),
                  if (_points.isNotEmpty)
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
            Expanded(
              child: Container(
                color: _isDark ? const Color(0xFF0A1628) : const Color(0xFFF1F5F9),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('RECORDED GPS POINTS (${_points.length})',
                            style: TextStyle(
                                color: _isDark ? Colors.white38 : Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6)),
                        if (_measure.isNotEmpty)
                          Text('Walk: ${_measure['walk']} • Car: ${_measure['car']}',
                              style: const TextStyle(color: Color(0xFF4A9EFF), fontSize: 10, fontFamily: 'monospace')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _points.isEmpty
                          ? Center(
                              child: Text('No GPS telemetry points found in selected time range.',
                                  style: TextStyle(color: _isDark ? Colors.white38 : Colors.grey[500], fontSize: 12)))
                          : ListView.builder(
                              itemCount: _points.length,
                              itemBuilder: (context, index) {
                                final p = _points[index];
                                final isLbs = p['islbs'] == '1';
                                final speed = double.tryParse(p['speed']?.toString() ?? '0') ?? 0;
                                final pointId = p['id']?.toString() ?? index.toString();
                                final isSelected = _selectedPointId == pointId;

                                return GestureDetector(
                                  onTap: () => setState(() => _selectedPointId = pointId),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2563EB).withOpacity(0.2)
                                          : (_isDark ? const Color(0xFF0F172A) : Colors.white),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF2563EB)
                                              : (_isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isLbs
                                                ? Colors.amberAccent.withOpacity(0.15)
                                                : Colors.greenAccent.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(isLbs ? Icons.wifi : Icons.navigation,
                                              size: 14, color: isLbs ? Colors.amberAccent : Colors.greenAccent),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(p['gpstime']?.toString() ?? '',
                                                      style: TextStyle(
                                                          color: _isDark ? Colors.white : const Color(0xFF0A1628),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 11,
                                                          fontFamily: 'monospace')),
                                                  const SizedBox(width: 6),
                                                  Text(isLbs ? 'Cell-Tower' : 'Satellite GPS',
                                                      style: TextStyle(
                                                          color: _isDark ? Colors.white38 : Colors.grey[500],
                                                          fontSize: 9)),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text('${p['lat']}, ${p['lng']}',
                                                  style: TextStyle(
                                                      color: _isDark ? Colors.white38 : Colors.grey[500],
                                                      fontSize: 10,
                                                      fontFamily: 'monospace')),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('${p['speed']} km/h',
                                                style: TextStyle(
                                                    color: _speedColor(speed),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    fontFamily: 'monospace')),
                                            Text('#Pt ${index + 1}',
                                                style: TextStyle(
                                                    color: _isDark ? Colors.white38 : Colors.grey[500], fontSize: 9)),
                                          ],
                                        ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: _isDark ? Colors.white38 : Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Text(_formatDateTime(value),
                style: TextStyle(color: _isDark ? Colors.white : const Color(0xFF0A1628), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: _isDark ? Colors.white : const Color(0xFF0A1628), size: 16),
      ),
    );
  }

  Widget _dotLabel(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}