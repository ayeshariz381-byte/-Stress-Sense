import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../widgets/student_bottom_nav.dart';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _cameraReady = false;
  String? _errorMessage;
  bool _measuring = false;
  bool _fingerDetected = false;
  int _bpm = 0;
  int _countdown = 30;
  Timer? _countdownTimer;
  final List<double> _redValues = [];
  final List<DateTime> _timestamps = [];
  String? _stressLevel;
  int? _hrv;
  bool _resultReady = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  final List<double> _waveform = List.generate(60, (_) => 0.0);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.92,
      upperBound: 1.08,
    )..repeat(reverse: true);
    _pulseAnimation = _pulseController;
    _requestAndInit();
  }

  @override
  void dispose() {
    _stopMeasurement();
    _cameraController?.dispose();
    _pulseController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _requestAndInit() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _errorMessage =
          'Camera permission is required.\nGo to Settings > Apps > StressSense > Permissions and enable Camera.');
      return;
    }
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        rear,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);
    } catch (e) {
      setState(() => _errorMessage = 'Camera error: $e');
    }
  }

  Future<void> _startMeasurement() async {
    if (!_cameraReady || _cameraController == null) return;
    setState(() {
      _measuring = true;
      _resultReady = false;
      _stressLevel = null;
      _bpm = 0;
      _hrv = null;
      _countdown = 30;
      _redValues.clear();
      _timestamps.clear();
      _fingerDetected = false;
    });
    await WakelockPlus.enable();
    await _cameraController!.setFlashMode(FlashMode.torch);
    await _cameraController!.startImageStream(_processFrame);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _stopMeasurement();
        _computeResult();
      }
    });
  }

  void _stopMeasurement() {
    _countdownTimer?.cancel();
    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.setFlashMode(FlashMode.off).catchError((_) {});
    WakelockPlus.disable();
    if (mounted) setState(() => _measuring = false);
  }

  void _processFrame(CameraImage image) {
    final plane = image.planes[0];
    final bytes = plane.bytes;
    int sum = 0;
    for (int i = 0; i < bytes.length; i++) {
      sum += bytes[i];
    }
    final avg = sum / bytes.length;
    final normalized = avg / 255.0;
    final fingerOn = normalized > 0.35;
    if (mounted) {
      setState(() {
        _fingerDetected = fingerOn;
        _waveform.removeAt(0);
        _waveform.add(fingerOn ? normalized : 0.5);
      });
    }
    if (!fingerOn) return;
    _redValues.add(normalized);
    _timestamps.add(DateTime.now());
    if (_redValues.length > 90) {
      final liveBpm = _calculateBpm(_redValues, _timestamps);
      if (liveBpm > 0 && mounted) {
        setState(() => _bpm = liveBpm);
      }
    }
  }

  int _calculateBpm(List<double> values, List<DateTime> times) {
    if (values.length < 15) return 0;
    final smoothed = <double>[];
    for (int i = 2; i < values.length - 2; i++) {
      smoothed.add(
          (values[i - 2] + values[i - 1] + values[i] + values[i + 1] + values[i + 2]) / 5);
    }
    final mean = smoothed.reduce((a, b) => a + b) / smoothed.length;
    final peaks = <int>[];
    for (int i = 1; i < smoothed.length - 1; i++) {
      if (smoothed[i] > smoothed[i - 1] &&
          smoothed[i] > smoothed[i + 1] &&
          smoothed[i] > mean * 1.01) {
        if (peaks.isEmpty || i - peaks.last > 9) {
          peaks.add(i);
        }
      }
    }
    if (peaks.length < 2) return 0;
    final intervals = <int>[];
    for (int i = 1; i < peaks.length; i++) {
      intervals.add(peaks[i] - peaks[i - 1]);
    }
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final durationMs = times.last.difference(times.first).inMilliseconds.toDouble();
    final fps = (values.length / durationMs) * 1000;
    if (fps <= 0) return 0;
    final bpm = ((fps / avgInterval) * 60).round();
    return bpm.clamp(45, 180);
  }

  void _computeResult() {
    if (_redValues.length < 15) {
      setState(() {
        _errorMessage =
            'Not enough data. Please keep your finger firmly on the camera and flash for the full 30 seconds.';
        _measuring = false;
      });
      return;
    }
    final bpm = _calculateBpm(_redValues, _timestamps);
    final finalBpm = bpm > 0 ? bpm : 72;
    final hrv = _estimateHRV();
    String stress;
    if (finalBpm < 70 && hrv > 40) {
      stress = 'Low';
    } else if (finalBpm < 85 && hrv > 25) {
      stress = 'Moderate';
    } else {
      stress = 'High';
    }
    setState(() {
      _bpm = finalBpm;
      _hrv = hrv;
      _stressLevel = stress;
      _resultReady = true;
      _measuring = false;
    });
    _saveToFirestore(finalBpm, hrv, stress);
  }

  // ── Save to Firestore + Emergency Alert if High ───────────
  Future<void> _saveToFirestore(int bpm, int hrv, String stress) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save stress reading
      await FirebaseFirestore.instance.collection('stress_readings').add({
        'uid': user.uid,
        'email': user.email,
        'bpm': bpm,
        'hrv': hrv,
        'stressLevel': stress,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // If HIGH stress — save emergency alert for consultant
      if (stress == 'High') {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final studentName =
            userDoc.data()?['name'] ?? user.email ?? 'Unknown';

        await FirebaseFirestore.instance
            .collection('emergency_alerts')
            .add({
          'uid': user.uid,
          'email': user.email,
          'studentName': studentName,
          'bpm': bpm,
          'hrv': hrv,
          'stressLevel': stress,
          'timestamp': FieldValue.serverTimestamp(),
          'isResolved': false,
        });

        debugPrint('Emergency alert sent for $studentName');

        // Show emergency popup to student
        if (mounted) {
          _showEmergencyPopup(studentName);
        }
      }
    } catch (e) {
      debugPrint('Firestore save error: $e');
    }
  }

  // ── Emergency popup for student ───────────────────────────
  void _showEmergencyPopup(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFDE8E4),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.red, size: 56),
          const SizedBox(height: 12),
          const Text(
            'High Stress Detected!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your consultant has been notified automatically. Please take a moment to breathe.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.air, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Try: Breathe in 4 counts, hold 4, breathe out 4',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ]),
          ),
        ]),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I\'m OK'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/breathing');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white),
            icon: const Icon(Icons.air),
            label: const Text('Breathe'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/messaging', arguments: {
                'patientName': 'Dr. Sarah Jenkins',
                'patientInitials': 'SJ',
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white),
            icon: const Icon(Icons.chat),
            label: const Text('Talk to Doctor'),
          ),
        ],
      ),
    );
  }

  int _estimateHRV() {
    if (_redValues.length < 15) return 30;
    final mean = _redValues.reduce((a, b) => a + b) / _redValues.length;
    final variance = _redValues
            .map((v) => pow(v - mean, 2))
            .reduce((a, b) => a + b) /
        _redValues.length;
    final std = sqrt(variance);
    return (std * 2000).clamp(15, 80).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const StudentBottomNav(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Text('Heart Rate',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_bpm > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$_bpm BPM',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
              ]),
              const SizedBox(height: 4),
              const Text(
                  'Place your finger firmly over the camera lens and flash',
                  style: TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: Colors.red))),
                    IconButton(
                      onPressed: () {
                        setState(() => _errorMessage = null);
                        _requestAndInit();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.red),
                    )
                  ]),
                ),
              if (_errorMessage == null) ...[
                _buildSensorCard(),
                const SizedBox(height: 16),
                _buildWaveformCard(),
                const SizedBox(height: 16),
                if (_resultReady) _buildResultCard(),
                if (!_resultReady && !_measuring) _buildInstructionsCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEE8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Center(
          child: ScaleTransition(
            scale: _measuring && _fingerDetected
                ? _pulseAnimation
                : const AlwaysStoppedAnimation(1.0),
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _fingerDetected
                      ? Colors.red.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _fingerDetected
                      ? Colors.red.shade400
                      : AppColors.primary,
                ),
                child: _measuring && _fingerDetected
                    ? const Icon(Icons.favorite,
                        color: Colors.white, size: 48)
                    : const Icon(Icons.fingerprint,
                        color: Colors.white, size: 48),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        if (_measuring) ...[
          Text(
            _fingerDetected ? 'Measuring...' : 'Place finger on camera',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color:
                  _fingerDetected ? Colors.red.shade600 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fingerDetected
                ? 'Hold still — $_countdown seconds remaining'
                : 'Cover the camera and flash completely',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (30 - _countdown) / 30,
              minHeight: 8,
              backgroundColor: Colors.black12,
              color: _fingerDetected
                  ? Colors.red.shade400
                  : AppColors.primary,
            ),
          ),
        ] else if (_resultReady) ...[
          Text(
            '$_bpm BPM',
            style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: AppColors.darkGreen),
          ),
          Text(
            _stressLevel == 'Low'
                ? 'Relaxed ✓'
                : _stressLevel == 'Moderate'
                    ? 'Slightly Stressed'
                    : 'High Stress Detected',
            style: TextStyle(
              fontSize: 16,
              color: _stressLevel == 'Low'
                  ? AppColors.primary
                  : _stressLevel == 'Moderate'
                      ? Colors.orange
                      : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else ...[
          const Text('Ready to Measure',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Tap Start and cover the camera with your finger',
              style: TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _measuring
              ? ElevatedButton.icon(
                  onPressed: _stopMeasurement,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Stop'),
                )
              : ElevatedButton.icon(
                  onPressed: _cameraReady ? _startMeasurement : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  icon: const Icon(Icons.favorite_border),
                  label: Text(_resultReady
                      ? 'Measure Again'
                      : 'Start Measurement'),
                ),
        ),
      ]),
    );
  }

  Widget _buildWaveformCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PULSE WAVEFORM',
            style: TextStyle(
                fontSize: 11, color: Colors.black45, letterSpacing: 1)),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: CustomPaint(
            painter: _WaveformPainter(
              values: List<double>.from(_waveform),
              color: _fingerDetected
                  ? Colors.red.shade400
                  : AppColors.primary,
            ),
            size: Size.infinite,
          ),
        ),
        if (_bpm > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              _statChip('BPM', '$_bpm'),
              const SizedBox(width: 8),
              _statChip('HRV', _hrv != null ? '${_hrv}ms' : '--'),
              const SizedBox(width: 8),
              _statChip('Stress', _stressLevel ?? '--'),
            ]),
          ),
      ]),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(label,
            style: const TextStyle(fontSize: 9, color: Colors.black45)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGreen)),
      ]),
    );
  }

  Widget _buildResultCard() {
    final isHigh = _stressLevel == 'High';
    final isMod = _stressLevel == 'Moderate';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHigh
            ? const Color(0xFFFDE8E4)
            : isMod
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
            isHigh
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: isHigh
                ? Colors.red
                : isMod
                    ? Colors.orange
                    : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isHigh
                ? 'High Stress Detected'
                : isMod
                    ? 'Moderate Stress'
                    : 'You\'re Calm',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isHigh
                  ? Colors.red
                  : isMod
                      ? Colors.orange
                      : AppColors.primary,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _metricRow('Heart Rate', '$_bpm BPM'),
        _metricRow('HRV Score', _hrv != null ? '${_hrv}ms' : '--'),
        _metricRow('Stress Level', _stressLevel ?? '--'),
        const SizedBox(height: 12),
        if (isHigh || isMod)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/breathing'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white),
              icon: const Icon(Icons.air),
              label: const Text('Start Guided Breathing'),
            ),
          ),
        if (!isHigh)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/healing-audio'),
              icon: const Icon(Icons.music_note_outlined),
              label: const Text('Continue with Healing Audio'),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/analysis',
              arguments: {
                'bpm': _bpm,
                'hrv': _hrv,
                'stressLevel': _stressLevel,
              },
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.bar_chart),
            label: const Text('View Full Analysis'),
          ),
        ),
      ]),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('HOW IT WORKS',
            style: TextStyle(
                fontSize: 11, color: Colors.black45, letterSpacing: 1)),
        const SizedBox(height: 10),
        _step('1', 'Tap "Start Measurement"'),
        _step('2', 'Cover the rear camera AND flash with your fingertip'),
        _step('3',
            'Hold still for 30 seconds — keep pressure light & steady'),
        _step('4',
            'Your BPM and stress level will be calculated automatically'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '💡 Tip: Make sure the flash is ON and you\'re in a dimly-lit area for best accuracy.',
            style: TextStyle(fontSize: 12, color: AppColors.darkGreen),
          ),
        ),
      ]),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary,
          child: Text(num,
              style:
                  const TextStyle(color: Colors.white, fontSize: 11)),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _WaveformPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final step = size.width / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      final x = i * step;
      final normalized = ((values[i] - 0.5) * 4).clamp(0.0, 1.0);
      final y = size.height -
          (normalized * size.height * 0.85) -
          size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final gradient = LinearGradient(
      colors: [
        color.withValues(alpha: 0.3),
        color,
        color.withValues(alpha: 0.3)
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint..shader = gradient);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.values != values;
}