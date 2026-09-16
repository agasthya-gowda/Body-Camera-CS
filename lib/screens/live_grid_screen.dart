import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';
import 'live_view_screen.dart';

class _CameraStream {
  VideoPlayerController? controller;
  bool isConnecting = true;
  String error = '';
}

class LiveGridScreen extends StatefulWidget {
  const LiveGridScreen({super.key});

  @override
  State<LiveGridScreen> createState() => _LiveGridScreenState();
}

class _LiveGridScreenState extends State<LiveGridScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _onlineDevices = [];
  bool _isLoadingList = true;
  final Set<String> _mutedHostbodies = {};
  final Set<String> _busyHostbodies = {};
  final Map<String, _CameraStream> _streams = {};

  bool get _isDark => AppTheme.isDark(context);

  @override
  void initState() {
    super.initState();
    _loadOnlineDevices();
  }

  @override
  void dispose() {
    for (final entry in _onlineDevices) {
      final hostbody = entry['hostbody']?.toString() ?? entry['did']?.toString() ?? '';
      if (hostbody.isEmpty) continue;
      _apiService.stopVideoCall([hostbody]);
      _apiService.stopAudioCall([hostbody], ["1"]);
    }
    for (final s in _streams.values) {
      s.controller?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOnlineDevices() async {
    setState(() => _isLoadingList = true);
    final result = await _apiService.getOnlineDevices();
    if (!mounted) return;
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
      final online = devices.where((d) => d['lineon']?.toString() == '1').toList();
      setState(() {
        _onlineDevices = online;
        _isLoadingList = false;
      });
      // Kick off a live stream for every online camera at once.
      for (final device in online) {
        _startCameraStream(device);
      }
    } else {
      setState(() => _isLoadingList = false);
    }
  }

  Future<void> _startCameraStream(Map<String, dynamic> device) async {
    final hostbody = device['hostbody']?.toString() ?? device['did']?.toString() ?? '';
    if (hostbody.isEmpty) return;

    final stream = _streams.putIfAbsent(hostbody, () => _CameraStream());
    setState(() {
      stream.isConnecting = true;
      stream.error = '';
    });

    if (kIsWeb) {
      setState(() {
        stream.isConnecting = false;
        stream.error = 'Live video not supported on web (RTSP only)';
      });
      return;
    }

    final result = await _apiService.startVideoCall([hostbody]);
    if (!mounted) return;
    final apiStreams = result['streams'] as List<Map<String, dynamic>>;

    if (result['code'] != 200 || apiStreams.isEmpty) {
      final failedDevices = result['failedDevices'] as List<Map<String, dynamic>>;
      String errorMsg = result['msg'] ?? 'Failed to start video call';
      if (failedDevices.isNotEmpty) {
        errorMsg = failedDevices[0]['err_msg'] ?? errorMsg;
      }
      setState(() {
        stream.isConnecting = false;
        stream.error = errorMsg;
      });
      return;
    }

    final streamData = apiStreams[0];
    // "rtsp" is the server's own internal loopback address - unreachable from
    // any other device. "mapped_rtsp" is the externally-reachable address.
    final rtspUrl = streamData['mapped_rtsp']?.toString() ?? streamData['rtsp']?.toString();
    if (rtspUrl == null || rtspUrl.isEmpty) {
      setState(() {
        stream.isConnecting = false;
        stream.error = 'No stream address returned';
      });
      return;
    }

    await _apiService.startAudioCall([hostbody]);

    // Real IP cameras aren't always instantly ready - retry a couple of times.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (!mounted) return;
      final controller = VideoPlayerController.networkUrl(Uri.parse(rtspUrl));
      try {
        await controller.initialize();
        if (!mounted) {
          controller.dispose();
          return;
        }
        await controller.play();
        setState(() {
          stream.controller = controller;
          stream.isConnecting = false;
          stream.error = '';
        });
        return;
      } catch (e) {
        controller.dispose();
        if (attempt == maxAttempts) {
          if (mounted) {
            setState(() {
              stream.isConnecting = false;
              stream.error = 'Video playback error: $e';
            });
          }
        } else {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  Future<void> _runQuickAction(Map<String, dynamic> device, String action) async {
    final imei = device['imei']?.toString() ?? '';
    final hostbody = device['hostbody']?.toString() ?? device['did']?.toString() ?? '';
    if (imei.isEmpty) return;

    setState(() => _busyHostbodies.add(hostbody));
    Map<String, dynamic> result;
    String successMsg;
    switch (action) {
      case 'takephoto':
        result = await _apiService.remoteKickoff(imei, 'takephoto');
        successMsg = 'Photo captured';
        break;
      case 'startvideo':
        result = await _apiService.remoteKickoff(imei, 'startvideo');
        successMsg = 'Remote recording started';
        break;
      case 'mute':
        final isMuted = _mutedHostbodies.contains(hostbody);
        result = await _apiService.sendCommand(imei, isMuted ? 'stopmute' : 'startmute');
        successMsg = isMuted ? 'Audio unmuted' : 'Audio muted';
        break;
      default:
        result = {'code': 500, 'msg': 'Unknown action'};
        successMsg = '';
    }

    if (!mounted) return;
    setState(() => _busyHostbodies.remove(hostbody));

    if (result['code'] == 200) {
      if (action == 'mute') {
        setState(() {
          if (_mutedHostbodies.contains(hostbody)) {
            _mutedHostbodies.remove(hostbody);
          } else {
            _mutedHostbodies.add(hostbody);
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
      );
    }
  }

  void _openFullScreen(Map<String, dynamic> device) {
    final hostbody = device['hostbody']?.toString() ?? device['did']?.toString() ?? '';
    final imei = device['imei']?.toString() ?? '';
    final officerName = device['hostname']?.toString() ?? 'Officer';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveViewScreen(
          hostbody: hostbody,
          imei: imei,
          officerName: officerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDark ? const Color(0xFF0A1628) : Colors.grey[50];
    final panelColor = _isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = _isDark ? Colors.white : const Color(0xFF0A1628);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: panelColor,
        foregroundColor: textColor,
        title: const Text('Live Cameras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOnlineDevices,
          ),
        ],
      ),
      body: _isLoadingList
          ? const Center(child: CircularProgressIndicator())
          : _onlineDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 56, color: Colors.grey[500]),
                      const SizedBox(height: 12),
                      Text(
                        'No cameras currently online',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _onlineDevices.length,
                  itemBuilder: (context, index) {
                    final device = _onlineDevices[index];
                    final hostbody = device['hostbody']?.toString() ?? device['did']?.toString() ?? '';
                    final stream = _streams[hostbody];
                    final isBusy = _busyHostbodies.contains(hostbody);
                    final isMuted = _mutedHostbodies.contains(hostbody);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                            child: Row(
                              children: [
                                const Icon(Icons.podcasts, size: 14, color: Colors.greenAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'BWC-$hostbody • ${device['hostname'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ---- Fixed-size live video area ----
                          GestureDetector(
                            onTap: () => _openFullScreen(device),
                            child: SizedBox(
                              width: double.infinity,
                              height: 220,
                              child: _buildStreamArea(stream),
                            ),
                          ),
                          // ---- Quick actions row ----
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: isBusy
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      _quickActionButton(
                                        icon: Icons.camera_alt,
                                        label: 'Photo',
                                        onTap: () => _runQuickAction(device, 'takephoto'),
                                      ),
                                      _quickActionButton(
                                        icon: isMuted ? Icons.mic_off : Icons.mic,
                                        label: isMuted ? 'Unmute' : 'Mute',
                                        onTap: () => _runQuickAction(device, 'mute'),
                                        color: isMuted ? Colors.red : null,
                                      ),
                                      _quickActionButton(
                                        icon: Icons.fiber_manual_record,
                                        label: 'Rec',
                                        onTap: () => _runQuickAction(device, 'startvideo'),
                                        color: Colors.redAccent,
                                      ),
                                      const Spacer(),
                                      _quickActionButton(
                                        icon: Icons.fullscreen,
                                        label: 'Full screen',
                                        onTap: () => _openFullScreen(device),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStreamArea(_CameraStream? stream) {
    if (stream == null || stream.isConnecting) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF4A9EFF)),
              SizedBox(height: 10),
              Text('Connecting…', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      );
    }
    if (stream.error.isNotEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off, color: Colors.white38, size: 28),
                const SizedBox(height: 8),
                Text(
                  stream.error,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (stream.controller != null && stream.controller!.value.isInitialized) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.zero),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: stream.controller!.value.size.width,
            height: stream.controller!.value.size.height,
            child: VideoPlayer(stream.controller!),
          ),
        ),
      );
    }
    return const ColoredBox(color: Colors.black);
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color ?? (_isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color ?? (_isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
