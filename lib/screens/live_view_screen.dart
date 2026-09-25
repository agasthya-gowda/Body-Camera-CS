// import 'package:flutter/material.dart';
// import 'recording_screen.dart';
// import '../services/api_service.dart';

// class LiveViewScreen extends StatefulWidget {
//   const LiveViewScreen({super.key});

//   @override
//   State<LiveViewScreen> createState() => _LiveViewScreenState();
// }

// class _LiveViewScreenState extends State<LiveViewScreen> {
//   bool _isMuted = false;
//   bool _isRecording = false;
//   String _currentTime = '';
//   String _location = '12.9716° N, 77.5946° E · MG Road, Bengaluru';
//   final ApiService _apiService = ApiService();
//   bool _isStreaming = false;
//   bool _isConnecting = true;
//   String? _rtspUrl;
//   String? _wsIp;
//   String? _wsPort;
//   String _streamError = '';
//   // TODO: This should come from the selected device on dashboard, hardcoded for now
//   final String _hostbody = "0300098";
//   final String _imei = "864156025728283";

//   @override
//   void initState() {
//     super.initState();
//     _updateTime();
//     _startStream();
//   }

//   Future<void> _startStream() async {
//     setState(() => _isConnecting = true);
//     final result = await _apiService.startVideoCall([_hostbody]);
//     final streams = result['streams'] as List<Map<String, dynamic>>;

//     if (result['code'] == 200 && streams.isNotEmpty) {
//       final streamData = streams[0];
//       setState(() {
//         _rtspUrl = streamData['rtsp'];
//         _wsIp = streamData['wsip'];
//         _wsPort = streamData['wsport'];
//         _isStreaming = true;
//         _isConnecting = false;
//       });
//       // Start audio alongside video, per "process for audio calls is same as video calls" (doc para 13)
//       await _apiService.startAudioCall([_hostbody]);
//     } else {
//       final failedDevices = result['failedDevices'] as List<Map<String, dynamic>>;
//       String errorMsg = result['msg'] ?? 'Failed to start video call';
//       if (failedDevices.isNotEmpty) {
//         errorMsg = failedDevices[0]['err_msg'] ?? errorMsg;
//       }
//       setState(() {
//         _streamError = errorMsg;
//         _isConnecting = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _apiService.stopVideoCall([_hostbody]);
//     _apiService.stopAudioCall([_hostbody], ["1"]);
//     super.dispose();
//   }

//   Future<void> _toggleMute() async {
//     final newMuteState = !_isMuted;
//     final commandType = newMuteState ? "startmute" : "stopmute";
//     final result = await _apiService.sendCommand(_imei, commandType);
//     if (result['code'] == 200) {
//       setState(() => _isMuted = newMuteState);
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to ${newMuteState ? "mute" : "unmute"}: ${result['msg']}')),
//         );
//       }
//     }
//   }

//   Future<void> _takeRemotePhoto() async {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Capturing photo...'), duration: Duration(seconds: 1)),
//     );
//     final result = await _apiService.remoteKickoff(_imei, "takephoto");
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(result['code'] == 200 ? 'Photo captured' : 'Failed: ${result['msg']}'),
//         backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
//       ),
//     );
//   }

//   Future<void> _startRemoteVideo() async {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Starting remote recording...'), duration: Duration(seconds: 1)),
//     );
//     final result = await _apiService.remoteKickoff(_imei, "startvideo");
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(result['code'] == 200 ? 'Remote recording started' : 'Failed: ${result['msg']}'),
//         backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
//       ),
//     );
//   }

//   Future<void> _confirmRestart() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Restart Device'),
//         content: const Text('This will remotely restart the camera. The live stream will be interrupted. Continue?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
//             child: const Text('Restart'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed != true || !mounted) return;

//     final result = await _apiService.remoteRestart(_imei, _hostbody);
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(result['code'] == 200 ? 'Restart command sent' : 'Failed: ${result['msg']}'),
//         backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
//       ),
//     );
//   }

//   void _updateTime() {
//     final now = DateTime.now();
//     setState(() {
//       _currentTime =
//           '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
//     });
//     Future.delayed(const Duration(seconds: 1), _updateTime);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         foregroundColor: Colors.white,
//         title: const Text('Live View'),
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 8),
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.red,
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Text(
//               'LIVE',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.more_vert, color: Colors.white),
//             onSelected: (value) {
//               if (value == 'restart') _confirmRestart();
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                 value: 'restart',
//                 child: Row(
//                   children: [
//                     Icon(Icons.restart_alt, color: Colors.red, size: 20),
//                     SizedBox(width: 8),
//                     Text('Restart Device', style: TextStyle(color: Colors.red)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Stack(
//               children: [
//                 Container(
//                   width: double.infinity,
//                   color: const Color(0xFF111111),
//                   child: const Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.videocam_off,
//                         size: 80,
//                         color: Color(0xFF333333),
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         'Camera Feed',
//                         style: TextStyle(
//                           color: Color(0xFF444444),
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Positioned(
//                   top: 16,
//                   right: 16,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black54,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       _currentTime,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontFamily: 'monospace',
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(20),
//             color: const Color(0xFF0A1628),
//             child: Column(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF112240),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.location_on,
//                         color: Colors.green,
//                         size: 16,
//                       ),
//                       const SizedBox(width: 6),
//                       Expanded(
//                         child: Text(
//                           _location,
//                           style: const TextStyle(
//                             color: Colors.white70,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildControlButton(
//                       icon: Icons.camera_alt_outlined,
//                       label: 'Photo',
//                       color: Colors.white,
//                       onTap: _takeRemotePhoto,
//                     ),
//                     _buildControlButton(
//                       icon: Icons.videocam_outlined,
//                       label: 'Remote Rec',
//                       color: Colors.white,
//                       onTap: _startRemoteVideo,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildControlButton(
//                       icon: _isMuted ? Icons.mic_off : Icons.mic,
//                       label: _isMuted ? 'Unmute' : 'Mute',
//                       color: _isMuted ? Colors.red : Colors.white,
//                       onTap: _toggleMute,
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const RecordingScreen(),
//                           ),
//                         );
//                       },
//                       child: Container(
//                         width: 72,
//                         height: 72,
//                         decoration: BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                           border: Border.all(
//                             color: Colors.red.withOpacity(0.3),
//                             width: 4,
//                           ),
//                         ),
//                         child: const Icon(
//                           Icons.fiber_manual_record,
//                           color: Colors.white,
//                           size: 36,
//                         ),
//                       ),
//                     ),
//                     _buildControlButton(
//                       icon: Icons.bookmark_outline,
//                       label: 'Bookmark',
//                       color: Colors.white,
//                       onTap: () {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text('Bookmark added!'),
//                             backgroundColor: Colors.green,
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildControlButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             width: 50,
//             height: 50,
//             decoration: BoxDecoration(
//               color: const Color(0xFF112240),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 24),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';

class LiveViewScreen extends StatefulWidget {
  final String hostbody;
  final String imei;
  final String officerName;

  final String? location;
  final int? batteryLevel;

  // When opened from a screen that's already streaming this camera (e.g. the
  // Live Feed grid), pass its already-initialized controller here so this
  // screen just displays it instead of starting a second, redundant RTSP
  // connection to the same camera from scratch.
  final VideoPlayerController? existingController;

  const LiveViewScreen({
    super.key,
    required this.hostbody,
    required this.imei,
    this.officerName = 'Officer',
    this.location,
    this.batteryLevel,
    this.existingController,
  });

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  bool _isMuted = false;
  // Local, phone-side speaker mute - separate from _isMuted (which sends a
  // real command to the camera itself). This just silences this stream's own
  // video player volume on this phone and never touches the server.
  bool _isSpeakerMuted = false;
  bool _isRecording = false;
  String _currentTime = '';
  final ApiService _apiService = ApiService();
  bool _isStreaming = false;
  bool _isConnecting = true;
  String? _rtspUrl;
  String? _wsIp;
  String? _wsPort;
  String _streamError = '';
  String? _lastAction;
  bool _isMenuOpen = false;
  VideoPlayerController? _videoController;
  bool _isBuffering = false;
  int _bufferAttempt = 0;
  static const int _maxBufferAttempts = 3;
  // False when reusing a controller the grid screen already owns - in that
  // case this screen must not dispose it or stop the video/audio call on
  // exit, since the grid keeps streaming it in the background.
  bool _ownsController = true;
  String get _hostbody => widget.hostbody;
  String get _imei => widget.imei;
  String get _officerName => widget.officerName;
  String get _location => widget.location ?? 'Location unavailable';

  @override
  void initState() {
    super.initState();
    _updateTime();
    final existing = widget.existingController;
    if (existing != null && existing.value.isInitialized) {
      _ownsController = false;
      _videoController = existing;
      _isStreaming = true;
      _isConnecting = false;
      // Reflect whatever local speaker-mute state this controller already
      // has (e.g. muted from the grid screen before opening full-screen).
      _isSpeakerMuted = existing.value.volume == 0.0;
    } else {
      _startStream();
    }
  }

  Future<void> _startStream() async {
    setState(() => _isConnecting = true);
    final result = await _apiService.startVideoCall([_hostbody]);
    final streams = result['streams'] as List<Map<String, dynamic>>;

    if (result['code'] == 200 && streams.isNotEmpty) {
      final streamData = streams[0];
      // "rtsp" is the server's own internal loopback address (127.0.0.1) -
      // meant for the server's own use, unreachable from any other device.
      // "mapped_rtsp" is the externally-reachable address; that's what an
      // actual phone/browser needs to connect to.
      final rtspUrl = streamData['mapped_rtsp']?.toString() ?? streamData['rtsp']?.toString();
      setState(() {
        _rtspUrl = rtspUrl;
        _wsIp = streamData['wsip'];
        _wsPort = streamData['wsport'];
        _isStreaming = true;
        _isConnecting = false;
      });
      // Vendor confirmed RTSP over the app's own player (their WebSocket player
      // protocol isn't available to us) - browsers can't play RTSP, so this only
      // renders on Android/iOS. fvp adds RTSP support to video_player (the
      // stock package can't play RTSP on its own).
      if (!kIsWeb && rtspUrl != null && rtspUrl.isNotEmpty) {
        // Real IP cameras often aren't instantly ready to stream the moment
        // startLive succeeds, so a fresh RTSP connection can transiently fail
        // - retry a couple of times before surfacing an error to the user.
        for (var attempt = 1; attempt <= _maxBufferAttempts; attempt++) {
          setState(() {
            _isBuffering = true;
            _bufferAttempt = attempt;
          });
          final controller = VideoPlayerController.networkUrl(Uri.parse(rtspUrl));
          try {
            await controller.initialize();
            if (!mounted) {
              controller.dispose();
              return;
            }
            await controller.play();
            setState(() {
              _videoController = controller;
              _streamError = '';
              _isBuffering = false;
            });
            break;
          } catch (e) {
            controller.dispose();
            if (attempt == _maxBufferAttempts) {
              if (mounted) {
                setState(() {
                  _streamError = 'Video playback error: $e';
                  _isBuffering = false;
                });
              }
            } else {
              await Future.delayed(const Duration(seconds: 2));
            }
          }
        }
      }
      // Start audio alongside video, per "process for audio calls is same as video calls" (doc para 13)
      await _apiService.startAudioCall([_hostbody]);
    } else {
      final failedDevices = result['failedDevices'] as List<Map<String, dynamic>>;
      String errorMsg = result['msg'] ?? 'Failed to start video call';
      if (failedDevices.isNotEmpty) {
        errorMsg = failedDevices[0]['err_msg'] ?? errorMsg;
      }
      setState(() {
        _streamError = errorMsg;
        _isConnecting = false;
      });
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _videoController?.dispose();
      _apiService.stopVideoCall([_hostbody]);
      _apiService.stopAudioCall([_hostbody], ["1"]);
    }
    super.dispose();
  }

  // Local-only: silences/restores this screen's own video player volume on
  // this phone. Doesn't call any API - guaranteed to work regardless of
  // what the server-side mute command actually does.
  void _toggleSpeaker() {
    setState(() {
      _isSpeakerMuted = !_isSpeakerMuted;
      _videoController?.setVolume(_isSpeakerMuted ? 0.0 : 1.0);
    });
  }

  Future<void> _toggleMute() async {
    final newMuteState = !_isMuted;
    final commandType = newMuteState ? "startmute" : "stopmute";
    final result = await _apiService.sendCommand(_imei, commandType);
    if (result['code'] == 200) {
      setState(() {
        _isMuted = newMuteState;
        _lastAction = newMuteState ? 'Audio feed silenced' : 'Two-way audio restored';
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${newMuteState ? "mute" : "unmute"}: ${result['msg']}')),
        );
      }
    }
  }

  Future<void> _takeRemotePhoto() async {
    final result = await _apiService.remoteKickoff(_imei, "takephoto");
    if (!mounted) return;
    if (result['code'] == 200) {
      setState(() => _lastAction = 'High-resolution snapshot captured and saved to evidence buffer');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['code'] == 200 ? 'Photo captured' : 'Failed: ${result['msg']}'),
        backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _startRemoteVideo() async {
    final result = await _apiService.remoteKickoff(_imei, "startvideo");
    if (!mounted) return;
    if (result['code'] == 200) {
      setState(() {
        _isRecording = true;
        _lastAction = 'Remote video recording command initiated on body camera';
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['code'] == 200 ? 'Remote recording started' : 'Failed: ${result['msg']}'),
        backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _confirmRestart() async {
    setState(() => _isMenuOpen = false);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
              ),
              const SizedBox(height: 12),
              const Text('Restart Body Camera?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                        text: 'This will send a hardware reboot command to device ',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    TextSpan(
                        text: 'BWC-$_hostbody',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                    const TextSpan(
                        text: '. Live telemetry will momentarily drop.',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm Restart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await _apiService.remoteRestart(_imei, _hostbody);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['code'] == 200 ? 'Restart command sent' : 'Failed: ${result['msg']}'),
        backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
      ),
    );
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  Widget _buildVideoContent() {
    if (kIsWeb) {
      return _videoStatusMessage(
        icon: Icons.desktop_access_disabled,
        title: 'Live video not supported on web',
        subtitle: 'This vendor only provides RTSP streaming, which browsers '
            'cannot play. Use the Android app to view BWC-$_hostbody live.',
      );
    }
    if (_isConnecting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4A9EFF)),
            SizedBox(height: 16),
            Text('Connecting to camera…', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      );
    }
    if (_isBuffering) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4A9EFF)),
            const SizedBox(height: 16),
            Text(
              _bufferAttempt > 1
                  ? 'Buffering video stream… (attempt $_bufferAttempt of $_maxBufferAttempts)'
                  : 'Buffering video stream…',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }
    if (_streamError.isNotEmpty) {
      return _videoStatusMessage(
        icon: Icons.videocam_off,
        title: 'Camera unavailable',
        subtitle: _streamError,
      );
    }
    if (_isStreaming && _videoController != null && _videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    return _videoStatusMessage(
      icon: Icons.videocam_off,
      title: 'Camera Feed',
      subtitle: 'RTSP stream negotiated with hardware unit BWC-$_hostbody',
    );
  }

  Widget _videoStatusMessage({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(icon, size: 36, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // ---- Main video area with tactical HUD ----
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Real RTSP video when available, otherwise a status placeholder.
                        Positioned.fill(child: _buildVideoContent()),

                        // HUD top-left telemetry
                        Positioned(
                          top: 60,
                          left: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.podcasts, size: 13, color: Colors.greenAccent),
                                  const SizedBox(width: 4),
                                  Text('BWC-$_hostbody • $_officerName',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace')),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text('RES: 1080P @ 30FPS • AES-256',
                                  style: TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace')),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.battery_charging_full, size: 11, color: Colors.greenAccent),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${widget.batteryLevel != null ? '${widget.batteryLevel}%' : '--'} • Buffer Active',
                                    style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Last action toast overlay
                        if (_lastAction != null)
                          Positioned(
                            top: 110,
                            left: 24,
                            right: 24,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_lastAction!,
                                        style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Top overlay bar: back, LIVE badge, clock, menu
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _hudIconButton(Icons.arrow_back, () => Navigator.pop(context)),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.circle, size: 6, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text('LIVE',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.access_time, size: 12, color: Color(0xFF4A9EFF)),
                                          const SizedBox(width: 4),
                                          Text(_currentTime,
                                              style: const TextStyle(
                                                  color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      color: const Color(0xFF0F172A),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      icon: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white24),
                                        ),
                                        child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'restart') _confirmRestart();
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'restart',
                                          child: Row(
                                            children: [
                                              Icon(Icons.restart_alt, color: Colors.redAccent, size: 18),
                                              SizedBox(width: 8),
                                              Text('Restart Device',
                                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom GPS location bar
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _location,
                                          style: const TextStyle(
                                              color: Color(0xFF4A9EFF),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'monospace'),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text('22 km/h',
                                    style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- Bottom control panel ----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF020617),
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roundIconButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.redAccent : Colors.white70,
                    background: _isMuted ? Colors.red.withOpacity(0.15) : const Color(0xFF0F172A),
                    border: _isMuted ? Colors.red.withOpacity(0.4) : const Color(0xFF1E293B),
                    onTap: _toggleMute,
                  ),
                  _roundIconButton(
                    icon: _isSpeakerMuted ? Icons.volume_off : Icons.volume_up,
                    color: _isSpeakerMuted ? Colors.redAccent : Colors.white70,
                    background: _isSpeakerMuted ? Colors.red.withOpacity(0.15) : const Color(0xFF0F172A),
                    border: _isSpeakerMuted ? Colors.red.withOpacity(0.4) : const Color(0xFF1E293B),
                    onTap: _toggleSpeaker,
                  ),
                  GestureDetector(
                    onTap: _startRemoteVideo,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFBE123C), Color(0xFFF43F5E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF020617), width: 4),
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 16)],
                      ),
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ),
                  _roundIconButton(
                    icon: Icons.camera_alt,
                    color: const Color(0xFF4A9EFF),
                    background: const Color(0xFF0F172A),
                    border: const Color(0xFF1E293B),
                    onTap: _takeRemotePhoto,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required Color color,
    required Color background,
    required Color border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}