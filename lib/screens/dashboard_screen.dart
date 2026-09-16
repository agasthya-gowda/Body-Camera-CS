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
import 'videos_list_screen.dart';
import 'upload_screen.dart';
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
const Color kBgDark = Color(0xFF0A1628);
const Color kSurfaceDark = Color(0xFF112543);
const Color kBannerStart = Color(0xFF1A3A6B);
const Color kBannerEnd = Color(0xFF2A5298);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
  final ApiService _apiService = ApiService();
  Timer? _heartbeatTimer;

  // Visual-only theme toggle, shared app-wide via ThemeController (no backend/logic impact)
  bool get _isDark => AppTheme.isDark(context);

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _startHeartbeat();
    _loadOnlineDevices();
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (
      timer,
    ) async {
      final success = await _apiService.sendHeartbeat();
      if (success) {
        // Cameras go on/off-line in real time - refresh the dashboard's
        // battery/storage/GPS on the same cadence as the heartbeat so it
        // doesn't keep showing whichever device happened to be first/online
        // when the screen first opened.
        _loadOnlineDevices();
      }
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
    super.dispose();
  }

  Future<void> _logout() async {
    _heartbeatTimer?.cancel();
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

  void _showAuditLog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? kSurfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Audit Log',
          style: TextStyle(
            color: _isDark ? Colors.white : const Color(0xFF0A1628),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildAuditItem('Video uploaded', 'REC_20260810_143207', '14:32'),
              _buildAuditItem('Video viewed', 'REC_20260809_091530', '13:15'),
              _buildAuditItem('Login', 'Officer on Duty', '09:00'),
              _buildAuditItem('Video recorded', 'REC_20260808_173401', '08:45'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditItem(String action, String detail, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 16, color: Color(0xFF4A9EFF)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    color: _isDark ? Colors.white54 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: _isDark ? Colors.white54 : Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
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
          : _selectedIndex == 1
          ? const VideosListScreen()
          : _selectedIndex == 2
          ? const UploadScreen()
          : const SettingsScreen(),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library_outlined),
              activeIcon: Icon(Icons.video_library),
              label: 'Videos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload_outlined),
              activeIcon: Icon(Icons.cloud_upload),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
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
      height: 72,
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
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.shield, color: kBannerStart),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'BWC MOBILE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: _isDark ? Colors.white : kBannerStart,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isDark
                            ? const Color(0xFF7FB3FF)
                            : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tactical Fleet Management',
                  style: TextStyle(
                    fontSize: 10,
                    color: _isDark ? const Color(0xFF7FB3FF) : Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Officer $_username',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Text(
                    'FIELD ON-DUTY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF4A9EFF),
            child: Text(
              _username.isNotEmpty ? _username[0].toUpperCase() : 'O',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Gradient banner: active camera + quick controls ----
  Widget _buildGradientBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kBannerStart, kBannerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
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
                    const Icon(
                      Icons.videocam,
                      color: Color(0xFFA9C6FF),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE CAMERA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            'BWC-${_deviceHostbody.isNotEmpty ? _deviceHostbody : "2024-07"} ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: '$_batteryLevel% Battery',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pillButton(
                      label: _cameraConnected ? 'Disconnect' : 'Reconnect',
                      onTap: () =>
                          setState(() => _cameraConnected = !_cameraConnected),
                    ),
                    _pillButton(
                      label: 'Divice info',
                      color: Colors.amber,
                      textColor: kBgDark,
                      onTap: _showDeviceInfoSheet,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              _circleIconButton(
                icon: _isDark ? Icons.dark_mode : Icons.light_mode,
                onTap: () => AppTheme.toggle(context),
              ),
              const SizedBox(height: 8),
              _circleIconButton(
                icon: Icons.settings,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              const SizedBox(height: 8),
              _circleIconButton(
                icon: Icons.logout,
                onTap: _logout,
                dangerHover: true,
              ),
            ],
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
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ---- Live Feed / GPS Tracking action cards ----
  Widget _buildActionCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _bigActionCard(
            title: 'Live Feed',
            subtitle: 'RTSP Streaming',
            icon: Icons.videocam,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LiveGridScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _bigActionCard(
            title: 'GPS Tracking',
            subtitle: 'Real-time GIS',
            icon: Icons.location_on,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LiveTrackingScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bigActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _isDark ? kBannerStart : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _isDark ? const Color(0xFF9FC1FF) : kBannerStart,
                  ),
                ),
              ],
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: _isDark ? Colors.white : kBannerStart,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Admin Shortcuts grid ----
  Widget _buildAdminShortcuts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isDark ? kSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
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
                icon: Icons.description,
                label: 'Audit Log',
                color: Colors.amberAccent,
                onTap: _showAuditLog,
              ),
              _adminTile(
                icon: Icons.info,
                label: 'Device Detail',
                color: const Color(0xFF4A9EFF),
                onTap: _showDeviceInfoSheet,
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
            ],
          ),
        ],
      ),
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
          color: _isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.15),
          ),
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
