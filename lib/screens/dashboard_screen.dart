// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'live_view_screen.dart';
// import 'recording_screen.dart';
// import 'videos_list_screen.dart';
// import 'upload_screen.dart';
// import 'settings_screen.dart';
// import 'login_screen.dart';
// import '../services/api_service.dart';
// import 'dart:async';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   int _selectedIndex = 0;
//   String _username = 'Officer';
//   bool _cameraConnected = false;
//   int _batteryLevel = 0;
//   double _storageUsed = 0.0;
//   double _storageTotal = 0.0;
//   String _signalType = '';
//   String _signalStrength = '';
//   String _deviceLat = '';
//   String _deviceLng = '';
//   String _deviceHostname = '';
//   String _deviceHostcode = '';
//   String _deviceUnitname = '';
//   String _deviceHostbody = '';
//   String _deviceImei = '';
//   String _deviceMobile = '';
//   int _recordingsToday = 0;
//   String _totalDuration = '00:00';
//   bool _gpsActive = false;
//   bool _isLoadingDevices = true;
//   List<Map<String, dynamic>> _onlineDevices = [];
//   final ApiService _apiService = ApiService();
//   Timer? _heartbeatTimer;

//   @override
//   void initState() {
//     super.initState();
//     _loadUsername();
//     _startHeartbeat();
//     _loadOnlineDevices();
//   }

//   void _startHeartbeat() {
//     _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
//       final success = await _apiService.sendHeartbeat();
//       if (!success && mounted) {
//         timer.cancel();
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.clear();
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Session expired. Please log in again.')),
//           );
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const LoginScreen()),
//           );
//         }
//       }
//     });
//   }

//   Future<void> _loadOnlineDevices() async {
//     try {
//       // Step 1: Get online device list (hierarchical: company -> sub devices)
//       final result = await _apiService.getOnlineDevices();
//       if (result['code'] == 200) {
//         final companies = List<Map<String, dynamic>>.from(result['data'] ?? []);

//         // Flatten: pull all devices out of each company's "sub" array
//         List<Map<String, dynamic>> devices = [];
//         for (var company in companies) {
//           if (company['sub'] != null) {
//             devices.addAll(List<Map<String, dynamic>>.from(company['sub']));
//           }
//         }

//         setState(() {
//           _onlineDevices = devices;
//         });

//         if (devices.isNotEmpty) {
//           final firstDevice = devices[0];
//           setState(() {
//             _cameraConnected = firstDevice['lineon'] == 1;
//             _gpsActive = true;
//           });

//           // Step 2: Get device detail (battery, storage, signal) for this device
//           // Per doc Section 5, item 22: request uses device SN (did/hostbody), not imei
//           final detailResult = await _apiService.getDeviceDetail([firstDevice['did'] ?? '']);

//           if (detailResult['code'] == 200) {
//             final detailData = List<Map<String, dynamic>>.from(detailResult['data'] ?? []);
//             if (detailData.isNotEmpty) {
//               final detail = detailData[0];
//               setState(() {
//                 _batteryLevel = int.tryParse(detail['electric']?.toString() ?? '0') ?? 0;
//                 _storageUsed = (double.tryParse(detail['capacity']?.toString() ?? '0') ?? 0) / 1000;
//                 _storageTotal = (double.tryParse(detail['totalcapacity']?.toString() ?? '0') ?? 0) / 1000;
//                 _signalType = detail['signal_cate']?.toString() ?? '';
//                 _signalStrength = detail['signal']?.toString() ?? '';
//                 _deviceLat = detail['latitude']?.toString() ?? '';
//                 _deviceLng = detail['longitude']?.toString() ?? '';
//                 _deviceHostname = detail['hostname']?.toString() ?? '';
//                 _deviceHostcode = detail['hostcode']?.toString() ?? '';
//                 _deviceUnitname = detail['unitname']?.toString() ?? '';
//                 _deviceHostbody = detail['hostbody']?.toString() ?? '';
//                 _deviceImei = detail['imei']?.toString() ?? '';
//                 _deviceMobile = detail['mobile']?.toString() ?? '';
//               });
//             }
//           }
//         }

//         setState(() => _isLoadingDevices = false);
//       } else {
//         setState(() => _isLoadingDevices = false);
//       }
//     } catch (e) {
//       setState(() => _isLoadingDevices = false);
//     }
//   }

//   Future<void> _loadUsername() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _username = prefs.getString('username') ?? 'Officer';
//     });
//   }

//   @override
//   void dispose() {
//     _heartbeatTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _logout() async {
//     _heartbeatTimer?.cancel();
//     await _apiService.logout();
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     if (mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginScreen()),
//       );
//     }
//   }

//   void _showDeviceInfoSheet() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text('Device Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.pop(context),
//                   padding: EdgeInsets.zero,
//                   constraints: const BoxConstraints(),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Text('OFFICER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.8)),
//             const SizedBox(height: 8),
//             _infoRow(Icons.badge_outlined, 'Officer', '$_deviceHostname ($_deviceHostcode)'),
//             _infoRow(Icons.apartment_outlined, 'Unit', _deviceUnitname),
//             const SizedBox(height: 12),
//             Text('DEVICE STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.8)),
//             const SizedBox(height: 8),
//             _infoRow(
//               _signalType == 'mobile_signal' ? Icons.signal_cellular_alt : Icons.wifi,
//               'Signal',
//               '${_signalType == 'mobile_signal' ? 'Mobile' : 'WiFi'} · Strength $_signalStrength/5',
//             ),
//             _infoRow(Icons.my_location_outlined, 'Device Location', '$_deviceLat, $_deviceLng'),
//             _infoRow(Icons.videocam_outlined, 'Device ID', _deviceHostbody),
//             _infoRow(Icons.confirmation_number_outlined, 'IMEI', _deviceImei),
//             _infoRow(Icons.sim_card_outlined, 'SIM Number', _deviceMobile),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showAuditLog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Audit Log'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView(
//             shrinkWrap: true,
//             children: [
//               _buildAuditItem('Video uploaded', 'REC_20260810_143207', '14:32'),
//               _buildAuditItem('Video viewed', 'REC_20260809_091530', '13:15'),
//               _buildAuditItem('Login', 'Officer on Duty', '09:00'),
//               _buildAuditItem('Video recorded', 'REC_20260808_173401', '08:45'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAuditItem(String action, String detail, String time) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.history, size: 16, color: Color(0xFF1A3A6B)),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(action, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
//                 Text(detail, style: const TextStyle(color: Colors.grey, fontSize: 12)),
//               ],
//             ),
//           ),
//           Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
//         ],
//       ),
//     );
//   }

//   void _showCameraPair() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Pair Camera'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 16),
//             const Text('Scanning for BWC devices...'),
//             const SizedBox(height: 16),
//             ListTile(
//               leading: const Icon(Icons.videocam, color: Color(0xFF1A3A6B)),
//               title: const Text('BWC-2024-07'),
//               subtitle: const Text('Signal: Strong'),
//               trailing: ElevatedButton(
//                 onPressed: () {
//                   setState(() => _cameraConnected = true);
//                   Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('BWC-2024-07 connected!'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1A3A6B),
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Pair'),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: _selectedIndex == 0
//           ? _buildHome()
//           : _selectedIndex == 1
//               ? const VideosListScreen()
//               : _selectedIndex == 2
//                   ? const UploadScreen()
//                   : const SettingsScreen(),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.15),
//               blurRadius: 10,
//               offset: const Offset(0, -4),
//             ),
//           ],
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: (index) => setState(() => _selectedIndex = index),
//           type: BottomNavigationBarType.fixed,
//           selectedItemColor: const Color(0xFF1A3A6B),
//           unselectedItemColor: Colors.grey,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home_outlined),
//               activeIcon: Icon(Icons.home),
//               label: 'Home',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.video_library_outlined),
//               activeIcon: Icon(Icons.video_library),
//               label: 'Videos',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.cloud_upload_outlined),
//               activeIcon: Icon(Icons.cloud_upload),
//               label: 'Upload',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.settings_outlined),
//               activeIcon: Icon(Icons.settings),
//               label: 'Settings',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHome() {
//     return SafeArea(
//       child: SingleChildScrollView(
//         child: Column(
//           children: [
//             _buildHeader(),
//             _buildCameraStatusCard(),
//             _buildStatsRow(),
//             _buildStorageCard(),
//             _buildQuickActions(),
//             _buildRecentRecordings(),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF0A1628), Color(0xFF1A3A6B)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(28),
//           bottomRight: Radius.circular(28),
//         ),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: 22,
//                 backgroundColor: const Color(0xFF4A9EFF).withOpacity(0.2),
//                 child: Text(
//                   _username.isNotEmpty ? _username[0].toUpperCase() : 'O',
//                   style: const TextStyle(
//                     color: Color(0xFF4A9EFF),
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Welcome, ',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const Text(
//                       'Field Officer · On Duty',
//                       style: TextStyle(
//                         color: Color(0xFF4A9EFF),
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: _gpsActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.gps_fixed, color: _gpsActive ? Colors.green : Colors.red, size: 12),
//                         const SizedBox(width: 4),
//                         Text(
//                           'GPS',
//                           style: TextStyle(
//                             color: _gpsActive ? Colors.green : Colors.red,
//                             fontSize: 11,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   IconButton(
//                     onPressed: _logout,
//                     icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCameraStatusCard() {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: _cameraConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               Icons.videocam,
//               color: _cameraConnected ? Colors.green : Colors.red,
//               size: 26,
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'BWC-2024-07',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 15,
//                     color: Color(0xFF0A1628),
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Container(
//                       width: 7,
//                       height: 7,
//                       decoration: BoxDecoration(
//                         color: _cameraConnected ? Colors.green : Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 5),
//                     Text(
//                       _cameraConnected ? 'Connected' : 'Not Connected',
//                       style: TextStyle(
//                         color: _cameraConnected ? Colors.green : Colors.red,
//                         fontSize: 12,
//                       ),
//                     ),
//                     if (_cameraConnected) ...[
//                       const SizedBox(width: 12),
//                       const Icon(Icons.battery_charging_full, size: 14, color: Colors.green),
//                       const SizedBox(width: 2),
//                       Text(
//                         '$_batteryLevel%',
//                         style: const TextStyle(color: Colors.green, fontSize: 12),
//                       ),
//                     ],
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => setState(() => _cameraConnected = !_cameraConnected),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _cameraConnected ? Colors.red[50] : const Color(0xFF1A3A6B),
//               foregroundColor: _cameraConnected ? Colors.red : Colors.white,
//               elevation: 0,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             ),
//             child: Text(_cameraConnected ? 'Disconnect' : 'Connect'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsRow() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildStatCard(
//               icon: Icons.info_outline,
//               label: 'Device Info',
//               value: '',
//               color: const Color(0xFF1A3A6B),
//               onTap: _showDeviceInfoSheet,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _buildStatCard(
//               icon: Icons.timer,
//               label: 'Total Duration',
//               value: _totalDuration,
//               color: Colors.purple,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _buildStatCard(
//               icon: Icons.cloud_done,
//               label: 'Uploaded',
//               value: '2/3',
//               color: Colors.teal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard({
//     required IconData icon,
//     required String label,
//     required String value,
//     required Color color,
//     VoidCallback? onTap,
//   }) {
//     final card = Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.08),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 10,
//               color: Colors.grey,
//             ),
//           ),
//         ],
//       ),
//     );
//     if (onTap == null) return card;
//     return GestureDetector(onTap: onTap, child: card);
//   }

//   // Widget _buildDeviceInfoCard() {
//   //   if (_deviceHostname.isEmpty) return const SizedBox.shrink();
//   //   return Container(
//   //     margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//   //     padding: const EdgeInsets.all(16),
//   //     decoration: BoxDecoration(
//   //       color: Colors.white,
//   //       borderRadius: BorderRadius.circular(16),
//   //       boxShadow: [
//   //         BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
//   //       ],
//   //     ),
//   //     child: Column(
//   //       crossAxisAlignment: CrossAxisAlignment.start,
//   //       children: [
//   //         const Row(
//   //           children: [
//   //             Icon(Icons.info_outline, color: Color(0xFF1A3A6B), size: 18),
//   //             SizedBox(width: 8),
//   //             Text('Device Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0A1628))),
//   //           ],
//   //         ),
//   //         const SizedBox(height: 12),
//   //         _infoRow(Icons.badge_outlined, 'Officer', '$_deviceHostname ($_deviceHostcode)'),
//   //         _infoRow(Icons.apartment_outlined, 'Unit', _deviceUnitname),
//   //         _infoRow(
//   //           _signalType == 'mobile_signal' ? Icons.signal_cellular_alt : Icons.wifi,
//   //           'Signal',
//   //           '${_signalType == 'mobile_signal' ? 'Mobile' : 'WiFi'} · Strength $_signalStrength/5',
//   //         ),
//   //         _infoRow(Icons.my_location_outlined, 'Device Location', '$_deviceLat, $_deviceLng'),
//   //         _infoRow(Icons.videocam_outlined, 'Device ID', _deviceHostbody),
//   //         _infoRow(Icons.confirmation_number_outlined, 'IMEI', _deviceImei),
//   //         _infoRow(Icons.sim_card_outlined, 'SIM Number', _deviceMobile),
//   //       ],
//   //     ),
//   //   );
//   // }

//   Widget _infoRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: Colors.grey[500]),
//           const SizedBox(width: 8),
//           Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0A1628)),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStorageCard() {
//     final usedPercent = _storageTotal > 0 ? _storageUsed / _storageTotal : 0.0;
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.08),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Row(
//                 children: [
//                   Icon(Icons.storage, color: Color(0xFF1A3A6B), size: 18),
//                   SizedBox(width: 8),
//                   Text(
//                     'Device Storage',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                       color: Color(0xFF0A1628),
//                     ),
//                   ),
//                 ],
//               ),
//               Text(
//                 '${_storageUsed.toStringAsFixed(1)} / ${_storageTotal.toStringAsFixed(1)} GB',
//                 style: const TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(6),
//             child: LinearProgressIndicator(
//               value: usedPercent,
//               backgroundColor: Colors.grey[200],
//               valueColor: AlwaysStoppedAnimation<Color>(
//                 usedPercent > 0.8 ? Colors.red : const Color(0xFF1A3A6B),
//               ),
//               minHeight: 8,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             '${(_storageTotal - _storageUsed).toStringAsFixed(1)} GB free',
//             style: TextStyle(
//               color: usedPercent > 0.8 ? Colors.red : Colors.grey,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActions() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Quick Actions',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF0A1628),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildActionCard(
//                   icon: Icons.play_circle_outline,
//                   label: 'Live View',
//                   color: const Color(0xFF1A3A6B),
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const LiveViewScreen()),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildActionCard(
//                   icon: Icons.fiber_manual_record,
//                   label: 'Record',
//                   color: Colors.red,
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const RecordingScreen()),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildActionCard(
//                   icon: Icons.bluetooth_searching,
//                   label: 'Pair Camera',
//                   color: Colors.blue,
//                   onTap: _showCameraPair,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildActionCard(
//                   icon: Icons.history,
//                   label: 'Audit Log',
//                   color: Colors.orange,
//                   onTap: _showAuditLog,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionCard({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: color, size: 22),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF0A1628),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentRecordings() {
//     final recentVideos = [
//       {'name': 'REC_20260810_143207', 'duration': '12:34', 'size': '4.2 GB', 'isEvidence': true},
//       {'name': 'REC_20260809_091530', 'duration': '08:17', 'size': '2.1 GB', 'isEvidence': false},
//     ];

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Recent Recordings',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF0A1628),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () => setState(() => _selectedIndex = 1),
//                 child: const Text(
//                   'View all',
//                   style: TextStyle(color: Color(0xFF1A3A6B)),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           ...recentVideos.map((video) => Container(
//             margin: const EdgeInsets.only(bottom: 10),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.08),
//                   blurRadius: 8,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 52,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF0A1628),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(Icons.play_circle_outline, color: Color(0xFF4A9EFF), size: 24),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               video['name'] as String,
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF0A1628),
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           if (video['isEvidence'] as bool)
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: Colors.red[50],
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 'Evidence',
//                                 style: TextStyle(color: Colors.red[700], fontSize: 9),
//                               ),
//                             ),
//                         ],
//                       ),
//                       const SizedBox(height: 3),
//                       Text(
//                         ' · ',
//                         style: const TextStyle(color: Colors.grey, fontSize: 11),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
//               ],
//             ),
//           )),
//         ],
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'live_grid_screen.dart';
import 'recording_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'officer_list_screen.dart';
import 'live_tracking_screen.dart';
import 'device_list_screen.dart';
import 'messages_list_screen.dart';
import 'message_history_screen.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';
import '../widgets/responsive_content.dart';
import 'dart:async';

// ---- Restyled palette to match the "tactical fleet management" visual direction ----
const Color kBgDark = Color(0xFF070E22);

// Draws the GPS Tracking card's perspective grid, glowing waypoint route,
// and a position dot that travels the route on a loop.
class _GpsRoutePainter extends CustomPainter {
  final double progress; // 0..1, looping
  _GpsRoutePainter({required this.progress});

  static const double _vbW = 220;
  static const double _vbH = 170;

  Offset _pt(Size size, double x, double y) => Offset(x / _vbW * size.width, y / _vbH * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Perspective horizontal lines
    const hLines = [
      [20.0, 50.0, 200.0, 50.0, 0.30],
      [10.0, 78.0, 210.0, 78.0, 0.45],
      [0.0, 112.0, 220.0, 112.0, 0.60],
      [-15.0, 154.0, 235.0, 154.0, 0.75],
    ];
    for (final l in hLines) {
      gridPaint.color = const Color(0xFF7552D4).withOpacity(l[4]);
      canvas.drawLine(_pt(size, l[0], l[1]), _pt(size, l[2], l[3]), gridPaint);
    }

    // Perspective converging vertical lines
    const vLines = [
      [25.0, 160.0, 68.0, 38.0],
      [72.0, 160.0, 94.0, 38.0],
      [120.0, 160.0, 120.0, 38.0],
      [168.0, 160.0, 146.0, 38.0],
      [212.0, 160.0, 172.0, 38.0],
    ];
    gridPaint.color = const Color(0xFF553A94).withOpacity(0.5);
    for (final l in vLines) {
      canvas.drawLine(_pt(size, l[0], l[1]), _pt(size, l[2], l[3]), gridPaint);
    }

    // Route waypoints
    const routePts = [
      [45.0, 125.0],
      [82.0, 90.0],
      [128.0, 128.0],
      [152.0, 114.0],
      [180.0, 68.0],
    ];
    final path = Path()..moveTo(_pt(size, routePts[0][0], routePts[0][1]).dx, _pt(size, routePts[0][0], routePts[0][1]).dy);
    for (var i = 1; i < routePts.length; i++) {
      final p = _pt(size, routePts[i][0], routePts[i][1]);
      path.lineTo(p.dx, p.dy);
    }

    final basePaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, basePaint);

    // Waypoint dots
    final dotPaint = Paint()..color = Colors.white;
    final dotBorder = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < routePts.length - 1; i++) {
      final p = _pt(size, routePts[i][0], routePts[i][1]);
      canvas.drawCircle(p, 3, dotPaint);
      canvas.drawCircle(p, 3, dotBorder);
    }

    // Destination bullseye
    final target = _pt(size, routePts.last[0], routePts.last[1]);
    final ring = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.6)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawOval(Rect.fromCenter(center: target, width: 22, height: 11), ring..color = const Color(0xFF00E5FF).withOpacity(0.5));
    canvas.drawOval(Rect.fromCenter(center: target, width: 14, height: 7), ring..color = const Color(0xFF00E5FF).withOpacity(0.8));
    canvas.drawCircle(target, 4, dotPaint);
    canvas.drawCircle(target, 4, dotBorder..strokeWidth = 2.5);

    // Moving position dot, traveling along the route on a loop
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
      final targetDist = totalLength * progress;
      double covered = 0;
      for (final m in metrics) {
        if (targetDist <= covered + m.length) {
          final tangent = m.getTangentForOffset(targetDist - covered);
          if (tangent != null) {
            final glowPaint = Paint()
              ..color = const Color(0xFF00E5FF).withOpacity(0.5)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
            canvas.drawCircle(tangent.position, 6, glowPaint);
            canvas.drawCircle(tangent.position, 4.5, dotPaint);
            canvas.drawCircle(tangent.position, 4.5, dotBorder..strokeWidth = 2);
          }
          break;
        }
        covered += m.length;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GpsRoutePainter oldDelegate) => oldDelegate.progress != progress;
}
const Color kSurfaceDark = Color(0xFF112543);
const Color kBannerStart = Color(0xFF1A3A6B);
const Color kBannerEnd = Color(0xFF2A5298);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  // Drives the Live Feed card's rotating radar sweep and breathing play-button glow.
  late final AnimationController _radarController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat();
  late final AnimationController _glowController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  // Two staggered ripple controllers so the "live" pulse rings on both cards
  // don't all expand in lockstep.
  late final AnimationController _rippleController1 =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  late final AnimationController _rippleController2 =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
        ..forward(from: 0.5)
        ..repeat();
  // Drives the GPS card's moving position dot and its arrival sonar pulses.
  late final AnimationController _gpsDotController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3800))..repeat();
  late final AnimationController _gpsRippleController1 =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
  late final AnimationController _gpsRippleController2 =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
        ..forward(from: 0.5)
        ..repeat();

  int _selectedIndex = 0;
  String _username = 'Officer';
  bool _cameraConnected = false;
  int _batteryLevel = 0;
  double _storageUsed = 0.0;
  double _storageTotal = 0.0;
  String _signalType = '';
  String _signalStrength = '';
  String _deviceLat = '';
  String _deviceLng = '';
  String _deviceHostname = '';
  String _deviceHostcode = '';
  String _deviceUnitname = '';
  String _deviceHostbody = '';
  String _deviceImei = '';
  String _deviceMobile = '';
  int _recordingsToday = 0;
  String _totalDuration = '00:00';
  bool _gpsActive = false;
  bool _isLoadingDevices = true;
  List<Map<String, dynamic>> _onlineDevices = [];
  // Per-device detail cache so the "Active Camera" banner can be swiped
  // through every online camera instead of only ever showing one - purely
  // a UI addition, reuses the existing _fetchOnlineDeviceDetails() call that
  // already powers the Device Info sheet.
  List<Map<String, dynamic>> _deviceDetails = [];
  final PageController _bannerPageController = PageController();
  int _bannerPageIndex = 0;
  final ApiService _apiService = ApiService();
  Timer? _heartbeatTimer;
  Timer? _deviceRefreshTimer;
  Timer? _autoSwipeTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // Visual-only theme toggle, shared app-wide via ThemeController (no backend/logic impact)
  bool get _isDark => AppTheme.isDark(context);

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _startHeartbeat();
    _loadOnlineDevices();
    // Cameras go on/off-line in real time - refresh the online device
    // list/count on its own fast cadence (independent of the 20s session
    // heartbeat) so "ACTIVE CAMERA" reflects who's actually online right now.
    _deviceRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadOnlineDevices();
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _startAutoSwipe();
  }

  // Auto-advances the "Active Camera" banner through every online device so
  // a large fleet is visible without the user having to swipe manually.
  // Restarted after every manual swipe so it doesn't fight the user's own
  // page change.
  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerPageController.hasClients) return;
      final count = _deviceDetails.length;
      if (count <= 1) return;
      final next = (_bannerPageIndex + 1) % count;
      _bannerPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (
      timer,
    ) async {
      final success = await _apiService.sendHeartbeat();
      if (!success && mounted) {
        timer.cancel();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }

  Future<void> _loadOnlineDevices() async {
    try {
      // Step 1: Get online device list (hierarchical: company -> sub devices)
      // Real server wraps the company list under data.total (data itself is an
      // object also containing a separate "lineon" list), not a bare list.
      final result = await _apiService.getOnlineDevices();
      if (!mounted) return;
      if (result['code'] == 200) {
        final companies = List<Map<String, dynamic>>.from(
          result['data']?['total'] ?? [],
        );

        // Flatten: pull all devices out of each company's "sub" array
        List<Map<String, dynamic>> devices = [];
        for (var company in companies) {
          if (company['sub'] != null) {
            devices.addAll(List<Map<String, dynamic>>.from(company['sub']));
          }
        }

        setState(() {
          _onlineDevices = devices;
        });

        if (devices.isNotEmpty) {
          // Prefer an actually-online device over just taking index 0 - the
          // server doesn't guarantee "sub" is ordered by online status.
          final firstDevice = devices.firstWhere(
            (d) => d['lineon']?.toString() == '1',
            orElse: () => devices[0],
          );
          setState(() {
            _cameraConnected = firstDevice['lineon']?.toString() == '1';
            _gpsActive = true;
          });

          // Step 2: Get device detail (battery, storage, signal) for this device
          // Per doc Section 5, item 22: request uses device SN (did/hostbody), not imei
          final detailResult = await _apiService.getDeviceDetail([
            firstDevice['did'] ?? '',
          ]);
          if (!mounted) return;

          if (detailResult['code'] == 200) {
            final detailData = List<Map<String, dynamic>>.from(
              detailResult['data'] ?? [],
            );
            if (detailData.isNotEmpty) {
              final detail = detailData[0];
              setState(() {
                _batteryLevel =
                    int.tryParse(detail['electric']?.toString() ?? '0') ?? 0;
                // Real server returns capacity/totalcapacity already in GB
                // (e.g. "57.65G", 57.79) - not MB, so no /1000 conversion.
                // capacity is a string with a trailing unit letter (e.g. "G"),
                // so strip anything that isn't part of the number first.
                _storageUsed = double.tryParse(
                      detail['capacity']
                              ?.toString()
                              .replaceAll(RegExp(r'[^0-9.]'), '') ??
                          '0',
                    ) ??
                    0;
                _storageTotal = double.tryParse(
                      detail['totalcapacity']
                              ?.toString()
                              .replaceAll(RegExp(r'[^0-9.]'), '') ??
                          '0',
                    ) ??
                    0;
                _signalType = detail['signal_cate']?.toString() ?? '';
                _signalStrength = detail['signal']?.toString() ?? '';
                _deviceLat = detail['latitude']?.toString() ?? '';
                _deviceLng = detail['longitude']?.toString() ?? '';
                _deviceHostname = detail['hostname']?.toString() ?? '';
                _deviceHostcode = detail['hostcode']?.toString() ?? '';
                _deviceUnitname = detail['unitname']?.toString() ?? '';
                _deviceHostbody = detail['hostbody']?.toString() ?? '';
                _deviceImei = detail['imei']?.toString() ?? '';
                _deviceMobile = detail['mobile']?.toString() ?? '';
              });
            }
          }
        }

        // Additive, UI-only: fetch detail for every online device (not just
        // the first) so the banner can be swiped through all of them. Reuses
        // the same helper the Device Info sheet already calls.
        final allDetails = await _fetchOnlineDeviceDetails();
        if (!mounted) return;
        setState(() {
          _deviceDetails = allDetails;
          if (_bannerPageIndex >= allDetails.length) {
            _bannerPageIndex = 0;
          }
        });
        if (_bannerPageController.hasClients) {
          _bannerPageController.jumpToPage(_bannerPageIndex);
        }

        setState(() => _isLoadingDevices = false);
      } else {
        setState(() => _isLoadingDevices = false);
      }
    } catch (e) {
      setState(() => _isLoadingDevices = false);
    }
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Officer';
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _deviceRefreshTimer?.cancel();
    _autoSwipeTimer?.cancel();
    _clockTimer?.cancel();
    _radarController.dispose();
    _glowController.dispose();
    _rippleController1.dispose();
    _rippleController2.dispose();
    _gpsDotController.dispose();
    _gpsRippleController1.dispose();
    _gpsRippleController2.dispose();
    _bannerPageController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    _heartbeatTimer?.cancel();
    _deviceRefreshTimer?.cancel();
    _autoSwipeTimer?.cancel();
    await _apiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Guards against a second tap opening a duplicate sheet while the first
  // tap's device-detail fetch (or the sheet itself) is still in progress -
  // reset automatically once the sheet closes.
  bool _isDeviceInfoSheetOpen = false;

  Future<List<Map<String, dynamic>>> _fetchOnlineDeviceDetails() async {
    final onlineIds = _onlineDevices
        .where((d) => d['lineon']?.toString() == '1')
        .map((d) => d['did']?.toString() ?? d['hostbody']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (onlineIds.isEmpty) return [];
    final result = await _apiService.getDeviceDetail(onlineIds);
    if (result['code'] == 200) {
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    }
    return [];
  }

  void _showDeviceInfoSheet() {
    if (_isDeviceInfoSheetOpen) return;
    _isDeviceInfoSheetOpen = true;

    // Open the sheet immediately (instant feedback on tap) and fetch the
    // device details inside it via FutureBuilder, rather than waiting for
    // the network call to finish before showing anything - that gap with no
    // visible feedback is what made the button feel unresponsive.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? kSurfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchOnlineDeviceDetails(),
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final details = snapshot.data ?? [];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isLoading ? 'Device Info' : 'Device Info (${details.length} online)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isDark ? Colors.white : const Color(0xFF0A1628),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: _isDark ? Colors.white70 : Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : details.isEmpty
                            ? Center(
                                child: Text(
                                  'No cameras currently online',
                                  style: TextStyle(
                                    color: _isDark ? Colors.white54 : Colors.grey[600],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: details.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: _isDark ? Colors.white12 : Colors.black12,
                                  height: 28,
                                ),
                                itemBuilder: (context, index) => _buildDeviceInfoBlock(details[index]),
                              ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).whenComplete(() {
      _isDeviceInfoSheetOpen = false;
    });
  }

  Widget _buildDeviceInfoBlock(Map<String, dynamic> detail) {
    final hostbody = detail['hostbody']?.toString() ?? '';
    final hostname = detail['hostname']?.toString() ?? 'Unknown';
    final hostcode = detail['hostcode']?.toString() ?? '';
    final signalCate = detail['signal_cate']?.toString() ?? '';
    final battery = detail['electric']?.toString() ?? '0';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.podcasts, size: 14, color: Colors.greenAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'BWC-$hostbody',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _isDark ? Colors.white : const Color(0xFF0A1628),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _sectionLabel('OFFICER'),
        const SizedBox(height: 8),
        _infoRow(Icons.badge_outlined, 'Officer', '$hostname ($hostcode)'),
        _infoRow(Icons.apartment_outlined, 'Unit', detail['unitname']?.toString() ?? ''),
        const SizedBox(height: 12),
        _sectionLabel('DEVICE STATUS'),
        const SizedBox(height: 8),
        _infoRow(Icons.battery_full, 'Battery', '$battery%'),
        _infoRow(
          signalCate == 'mobile_signal' ? Icons.signal_cellular_alt : Icons.wifi,
          'Signal',
          '${signalCate == 'mobile_signal' ? 'Mobile' : 'WiFi'} · Strength ${detail['signal']?.toString() ?? '0'}/5',
        ),
        _infoRow(
          Icons.my_location_outlined,
          'Device Location',
          '${detail['latitude']}, ${detail['longitude']}',
        ),
        _infoRow(Icons.videocam_outlined, 'Device ID', hostbody),
        _infoRow(Icons.confirmation_number_outlined, 'IMEI', detail['imei']?.toString() ?? ''),
        _infoRow(Icons.sim_card_outlined, 'SIM Number', detail['mobile']?.toString() ?? ''),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF4A9EFF),
        letterSpacing: 0.8,
      ),
    );
  }

  void _showCameraPair() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? kSurfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pair Camera',
          style: TextStyle(
            color: _isDark ? Colors.white : const Color(0xFF0A1628),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Scanning for BWC devices...',
              style: TextStyle(
                color: _isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.videocam, color: Color(0xFF4A9EFF)),
              title: Text(
                'BWC-2024-07',
                style: TextStyle(
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Signal: Strong',
                style: TextStyle(color: _isDark ? Colors.white54 : Colors.grey),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() => _cameraConnected = true);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('BWC-2024-07 connected!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBannerStart,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Pair'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDark ? kBgDark : const Color(0xFFF1F5F9);
    return Scaffold(
      backgroundColor: bgColor,
      body: _selectedIndex == 0
          ? _buildHome()
          : SettingsScreen(onBack: () => setState(() => _selectedIndex = 0)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _isDark ? kSurfaceDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4A9EFF),
          unselectedItemColor: _isDark ? Colors.white38 : Colors.grey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _profileNavIcon(selected: _selectedIndex == 1),
              activeIcon: _profileNavIcon(selected: true),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Bottom-nav "Settings" tab shows the logged-in user's own initial instead
  // of a generic gear icon - a quick visual "who's signed in" cue.
  Widget _profileNavIcon({required bool selected}) {
    final initial = _username.isNotEmpty ? _username[0].toUpperCase() : 'O';
    final color = selected
        ? const Color(0xFF4A9EFF)
        : (_isDark ? Colors.white38 : Colors.grey);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.18),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildHome() {
    final isWideDesktop = MediaQuery.of(context).size.width > 960;
    return SafeArea(
      child: Column(
        children: [
          _buildTopAppBar(),
          Expanded(
            child: Stack(
              children: [
                if (isWideDesktop) ...[
                  Positioned(
                    left: -160,
                    top: 20,
                    child: IgnorePointer(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                        child: Container(
                          width: 420,
                          height: 420,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -160,
                    top: 220,
                    child: IgnorePointer(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                        child: Container(
                          width: 420,
                          height: 420,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ResponsiveContent(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGradientBanner(),
                        const SizedBox(height: 14),
                        _buildActionCardsRow(),
                        const SizedBox(height: 14),
                        _buildAdminShortcuts(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Top App Bar: branding + officer identity ----
  Widget _buildTopAppBar() {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: _isDark ? kBannerStart : Colors.white,
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
                Text(
                  'ChipScape',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: _isDark ? Colors.white : kBannerStart,
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
    // Green (the "live/on-duty" status color used elsewhere) across the
    // whole clock - fitting, since this whole block is live/ticking data.
    const green = Colors.greenAccent;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF4A9EFF).withOpacity(_isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.35)),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: hh, style: const TextStyle(color: green)),
                const TextSpan(text: ':', style: TextStyle(color: green)),
                TextSpan(text: mm, style: const TextStyle(color: green)),
                const TextSpan(text: ':', style: TextStyle(color: green)),
                TextSpan(text: ss, style: const TextStyle(color: green)),
              ],
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: weekday,
                style: TextStyle(
                  color: _isDark ? Colors.white : kBannerStart,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: restOfDate,
                style: TextStyle(color: _isDark ? Colors.white : kBannerStart),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ---- Gradient banner: active camera(s) + quick controls ----
  Widget _buildGradientBanner() {
    final devices = _deviceDetails;
    final hasMultiple = devices.length > 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? const [kBannerStart, kBannerEnd]
              : const [Color(0xFFF3F8FF), Color(0xFFE0EBFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.25 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.videocam,
                      color: _isDark ? const Color(0xFFA9C6FF) : kBannerStart,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE CAMERA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: _isDark
                            ? Colors.white.withOpacity(0.75)
                            : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (_isDark ? Colors.greenAccent : Colors.green)
                            .withOpacity(_isDark ? 0.18 : 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${devices.length} ONLINE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          color: _isDark ? Colors.greenAccent : Colors.green[800],
                        ),
                      ),
                    ),
                    if (hasMultiple) ...[
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          '${_bannerPageIndex + 1}/${devices.length}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: (_isDark ? Colors.white : Colors.black87)
                                .withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 78,
                  child: devices.isEmpty
                      ? _bannerDeviceContent(
                          hostbody: _deviceHostbody,
                          battery: _batteryLevel,
                          onInfoTap: _showDeviceInfoSheet,
                        )
                      : PageView.builder(
                          controller: _bannerPageController,
                          itemCount: devices.length,
                          onPageChanged: (i) {
                            setState(() => _bannerPageIndex = i);
                            _startAutoSwipe();
                          },
                          itemBuilder: (context, index) {
                            final d = devices[index];
                            final hostbody =
                                d['hostbody']?.toString() ?? '';
                            final battery = int.tryParse(
                                  d['electric']?.toString() ?? '0',
                                ) ??
                                0;
                            return _bannerDeviceContent(
                              hostbody: hostbody,
                              battery: battery,
                              onInfoTap: () => _showSingleDeviceInfoSheet(d),
                            );
                          },
                        ),
                ),
                if (hasMultiple) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      devices.length,
                      (i) => Container(
                        margin: const EdgeInsets.only(right: 5),
                        width: i == _bannerPageIndex ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: (_isDark ? Colors.white : Colors.black87)
                              .withOpacity(
                            i == _bannerPageIndex ? 0.9 : 0.3,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              _circleIconButton(
                icon: Icons.logout,
                onTap: _logout,
                dangerHover: true,
              ),
              const SizedBox(height: 8),
              _circleIconButton(
                icon: _isDark ? Icons.dark_mode : Icons.light_mode,
                onTap: () => AppTheme.toggle(context),
              ),
              const SizedBox(height: 8),
              _circleIconButton(
                icon: Icons.view_list,
                onTap: _showAllActiveCamerasSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerDeviceContent({
    required String hostbody,
    required int battery,
    required VoidCallback onInfoTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'BWC-${hostbody.isNotEmpty ? hostbody : "2024-07"} ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isDark ? Colors.white : const Color(0xFF0A1628),
                ),
              ),
              TextSpan(
                text: '$battery% Battery',
                style: TextStyle(
                  fontSize: 12,
                  color: (_isDark ? Colors.white : Colors.black).withOpacity(0.6),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _pillButton(
          label: 'Divice info',
          color: Colors.amber,
          textColor: kBgDark,
          onTap: onInfoTap,
        ),
      ],
    );
  }

  // Same look as _showDeviceInfoSheet, but for exactly one device - used by
  // the swipeable banner's "Divice info" button so it shows only the camera
  // currently on screen, instead of every online device.
  void _showSingleDeviceInfoSheet(Map<String, dynamic> detail) {
    if (_isDeviceInfoSheetOpen) return;
    _isDeviceInfoSheetOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? kSurfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Device Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDark ? Colors.white : const Color(0xFF0A1628),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: _isDark ? Colors.white70 : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildDeviceInfoBlock(detail),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      _isDeviceInfoSheetOpen = false;
    });
  }

  // Lists every online camera vertically (hostbody, battery, Divice-info
  // action) so it's easy to scan a large fleet instead of swiping through
  // each one individually.
  void _showAllActiveCamerasSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? kSurfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Cameras (${_deviceDetails.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDark ? Colors.white : const Color(0xFF0A1628),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: _isDark ? Colors.white70 : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _deviceDetails.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final detail = _deviceDetails[index];
                    final hostbody = detail['hostbody']?.toString() ?? '';
                    final battery = int.tryParse(
                          detail['electric']?.toString() ?? '0',
                        ) ??
                        0;
                    return _activeCameraListCard(
                      hostbody: hostbody,
                      battery: battery,
                      onInfoTap: () => _showSingleDeviceInfoSheet(detail),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeCameraListCard({
    required String hostbody,
    required int battery,
    required VoidCallback onInfoTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kBannerStart, kBannerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam, color: Color(0xFFA9C6FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            'BWC-${hostbody.isNotEmpty ? hostbody : "2024-07"} ',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: '$battery% Battery',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _pillButton(
                  label: 'Divice info',
                  color: Colors.amber,
                  textColor: kBgDark,
                  onTap: onInfoTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool dangerHover = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: _isDark ? Colors.white : const Color(0xFF0A1628),
          size: 18,
        ),
      ),
    );
  }

  // ---- Live Feed / GPS Tracking action cards ----
  Widget _buildActionCardsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: _liveFeedCard(),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: _gpsTrackingCard(),
          ),
        ),
      ],
    );
  }

  Widget _tacticalCardShell({
    required VoidCallback onTap,
    required List<Color> gradientColors,
    required Color borderColor,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.4 : 0.1),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _cardHeader({
    required IconData icon,
    required Color iconBg,
    required Color iconGlow,
    required String title,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: iconGlow, blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _isDark ? Colors.white : const Color(0xFF0A1628),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtitleColor),
        ),
      ],
    );
  }

  Widget _cardArrowButton(Color color) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.45), blurRadius: 10)],
        ),
        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 15),
      ),
    );
  }

  // ---- Live Feed card: rotating radar sweep, staggered ripples, breathing play button ----
  Widget _liveFeedCard() {
    return _tacticalCardShell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LiveGridScreen()),
      ),
      gradientColors: _isDark
          ? const [Color(0xFF133C8C), Color(0xFF0D2A6B), Color(0xFF071942)]
          : const [Color(0xFFEAF3FF), Color(0xFFD9E9FF), Color(0xFFCBDFFC)],
      borderColor: const Color(0xFF60A5FA).withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.videocam,
            iconBg: const Color(0xFF2979FF),
            iconGlow: const Color(0xFF2979FF).withOpacity(0.45),
            title: 'Live Feed',
            subtitle: 'RTSP Streaming',
            subtitleColor: _isDark
                ? const Color(0xFFBFDBFE).withOpacity(0.7)
                : const Color(0xFF3B5A8A),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_radarController, _glowController, _rippleController1, _rippleController2]),
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating radar sweep
                        Transform.rotate(
                          angle: _radarController.value * 2 * 3.14159265,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  const Color(0xFF60A5FA).withOpacity(0.45),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.75, 1.0, 1.0],
                              ),
                            ),
                          ),
                        ),
                        _ripplePulse(_rippleController1, 76, const Color(0xFF60A5FA)),
                        _ripplePulse(_rippleController2, 76, const Color(0xFF60A5FA)),
                        // Concentric rings
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF60A5FA).withOpacity(0.2)),
                          ),
                        ),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF60A5FA).withOpacity(0.3)),
                            color: const Color(0xFF3B82F6).withOpacity(0.06),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF60A5FA).withOpacity(0.45)),
                            color: const Color(0xFF3B82F6).withOpacity(0.12),
                          ),
                        ),
                        // Breathing center play button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1D63E0), Color(0xFF3B82F6)],
                            ),
                            border: Border.all(color: const Color(0xFF93C5FD).withOpacity(0.6)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2979FF).withOpacity(0.55 + 0.3 * _glowController.value),
                                blurRadius: 16 + 10 * _glowController.value,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          _cardArrowButton(const Color(0xFF2979FF)),
        ],
      ),
    );
  }

  Widget _ripplePulse(AnimationController controller, double baseSize, Color color) {
    final t = controller.value;
    final scale = 0.85 + t * 0.8;
    final opacity = (1 - t).clamp(0.0, 1.0) * 0.65;
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: baseSize,
          height: baseSize,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color)),
        ),
      ),
    );
  }

  // ---- GPS Tracking card: perspective grid, glowing route, moving position dot, sonar target ----
  Widget _gpsTrackingCard() {
    return _tacticalCardShell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LiveTrackingScreen()),
      ),
      gradientColors: _isDark
          ? const [Color(0xFF2A1B63), Color(0xFF1D114A), Color(0xFF0E072B)]
          : const [Color(0xFFF3EEFF), Color(0xFFE5D9FF), Color(0xFFD7C7FA)],
      borderColor: const Color(0xFF9C6EFF).withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.location_on,
            iconBg: const Color(0xFF7C4DFF),
            iconGlow: const Color(0xFF7C4DFF).withOpacity(0.45),
            title: 'GPS Tracking',
            subtitle: 'Real-time GIS',
            subtitleColor: _isDark
                ? const Color(0xFFD8CCFF).withOpacity(0.7)
                : const Color(0xFF5B4A8A),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _gpsDotController,
                    builder: (context, _) => CustomPaint(
                      painter: _GpsRoutePainter(progress: _gpsDotController.value),
                    ),
                  ),
                ),
                // Sonar ripple halos over the destination target (~top-right of the grid)
                Align(
                  alignment: const Alignment(0.64, -0.2),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_gpsRippleController1, _gpsRippleController2]),
                    builder: (context, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        _ripplePulse(_gpsRippleController1, 34, const Color(0xFF00E5FF)),
                        _ripplePulse(_gpsRippleController2, 34, const Color(0xFF00E5FF)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _cardArrowButton(const Color(0xFF7C4DFF)),
        ],
      ),
    );
  }

  // ---- Admin Shortcuts grid ----
  Widget _buildAdminShortcuts() {
    // No surrounding card here - the tiles sit directly on the page
    // background (each tile carries its own background/shadow), matching
    // the reference design instead of grouping them inside one big box.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADMIN SHORTCUTS & FLEET TOOLS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: const Color(0xFF4A9EFF),
          ),
        ),
        const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              _adminTile(
                icon: Icons.people,
                label: 'Manage Officers',
                color: Colors.greenAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfficerListScreen(),
                  ),
                ),
              ),
              _adminTile(
                icon: Icons.message,
                label: 'Dispatch Messages',
                color: Colors.purpleAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesListScreen(),
                  ),
                ),
              ),
              _adminTile(
                icon: Icons.videocam,
                label: 'Device Fleet',
                color: Colors.indigoAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeviceListScreen(),
                  ),
                ),
              ),
              _adminTile(
                icon: Icons.history,
                label: 'Message History',
                color: Colors.pinkAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessageHistoryScreen(),
                  ),
                ),
              ),
              _adminTile(
                icon: Icons.info,
                label: 'Device Detail',
                color: const Color(0xFF4A9EFF),
                onTap: _showDeviceInfoSheet,
              ),
            ],
          ),
        ],
      );
  }

  Widget _adminTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: _isDark ? Colors.white38 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: _isDark ? Colors.white38 : Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: _isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isDark ? Colors.white : const Color(0xFF0A1628),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
