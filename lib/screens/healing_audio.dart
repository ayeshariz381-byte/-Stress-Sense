import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/app_colors.dart';

class _Track {
  final String title;
  final String surah;
  final String duration;
  final String url;

  const _Track({
    required this.title,
    required this.surah,
    required this.duration,
    required this.url,
  });
}

class HealingAudioScreen extends StatefulWidget {
  const HealingAudioScreen({super.key});

  @override
  State<HealingAudioScreen> createState() => _HealingAudioScreenState();
}

class _HealingAudioScreenState extends State<HealingAudioScreen> {
  final _player = AudioPlayer();

  // ── Each surah has its own correct MP3 URL ──────────────────────
  // Using Mishary Rashid Alafasy recitation from quranicaudio.com
  final List<_Track> _tracks = const [
    _Track(
      title: 'Surah Al-Fatiha',
      surah: 'The Opening • Chapter 1',
      duration: '0:50',
      url: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/001.mp3',
    ),
    _Track(
      title: 'Surah Yaseen',
      surah: 'Ya-Sin • Chapter 36',
      duration: '15:00',
      url: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/036.mp3',
    ),
    _Track(
      title: 'Surah Ar-Rahman',
      surah: 'The Beneficent • Chapter 55',
      duration: '12:45',
      url: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/055.mp3',
    ),
    _Track(
      title: 'Surah Al-Waqiah',
      surah: 'The Inevitable • Chapter 56',
      duration: '8:00',
      url: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/056.mp3',
    ),
    _Track(
      title: 'Surah Al-Mulk',
      surah: 'The Sovereignty • Chapter 67',
      duration: '7:00',
      url: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/067.mp3',
    ),
    _Track(
      title: 'Surah Ad-Duha',
      surah: 'The Morning Hours • Chapter 93',
      duration: '1:00',
      url: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/093.mp3',
    ),
    _Track(
      title: 'Surah Al-Ikhlas',
      surah: 'The Sincerity • Chapter 112',
      duration: '0:25',
      url: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/112.mp3',
    ),
    _Track(
      title: 'Surah Al-Falaq',
      surah: 'The Daybreak • Chapter 113',
      duration: '0:30',
      url: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/113.mp3',
    ),
    _Track(
      title: 'Surah An-Nas',
      surah: 'Mankind • Chapter 114',
      duration: '0:35',
      url: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/114.mp3',
    ),
  ];

  int _currentIndex = 0;
  bool _playing = false;
  bool _loading = false;
  String? _errorMsg;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _total = dur);
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) _playNext();
    });
    _loadTrack(_currentIndex);
  }

  Future<void> _loadTrack(int index, {bool autoPlay = false}) async {
    setState(() {
      _loading = true;
      _playing = false;
      _errorMsg = null;
      _position = Duration.zero;
      _total = Duration.zero;
    });
    try {
      await _player.stop();
      await _player.setUrl(_tracks[index].url);
      if (autoPlay) {
        await _player.play();
        if (mounted) setState(() => _playing = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg =
            'Could not load "${_tracks[index].title}". Check your internet.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _playNext() {
    if (_currentIndex < _tracks.length - 1) {
      setState(() => _currentIndex++);
      _loadTrack(_currentIndex, autoPlay: true);
    }
  }

  void _playPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _loadTrack(_currentIndex, autoPlay: true);
    }
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    if (mounted) setState(() => _playing = !_playing);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _tracks[_currentIndex];
    final progress = _total.inSeconds > 0
        ? (_position.inSeconds / _total.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.deepDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ──
              Row(children: [
                BackButton(color: Colors.white),
                const Text('Healing Audio',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.more_horiz, color: Colors.white),
              ]),
              const Text('A BIOACOUSTIC STRESS ACTIVATOR',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 12),

              // ── Calm state banner ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF184534),
                    borderRadius: BorderRadius.circular(12)),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle, color: Colors.greenAccent),
                  title: Text('Calm State Detected',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                      'Your heart rate is stabilizing. Perfect time for Quran recitation.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 14),

              // ── Error message ──
              if (_errorMsg != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.red.shade800,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12))),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.refresh,
                          color: Colors.white, size: 18),
                      onPressed: () => _loadTrack(_currentIndex),
                    )
                  ]),
                ),

              // ── Track list ──
              Expanded(
                child: ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, i) {
                    final isSelected = i == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentIndex = i);
                        _loadTrack(i, autoPlay: true);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF184534)
                              : const Color(0xFF113426),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: Colors.greenAccent, width: 1)
                              : null,
                        ),
                        child: ListTile(
                          leading: Icon(
                            isSelected && _playing
                                ? Icons.play_circle_fill
                                : Icons.music_note,
                            color: isSelected
                                ? Colors.greenAccent
                                : Colors.white70,
                          ),
                          title: Text(_tracks[i].title,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              )),
                          subtitle: Text(
                            isSelected && _playing
                                ? 'Playing • ${_fmt(_position)}'
                                : _tracks[i].surah,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                          trailing: isSelected && _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.greenAccent,
                                      strokeWidth: 2),
                                )
                              : Text(
                                  _tracks[i].duration,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Player bar ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF184534),
                    borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(current.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          Text(current.surah,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _currentIndex > 0 ? _playPrev : null,
                      icon: Icon(Icons.skip_previous,
                          color: _currentIndex > 0
                              ? Colors.white
                              : Colors.white30),
                    ),
                    _loading
                        ? const SizedBox(
                            width: 38,
                            height: 38,
                            child: CircularProgressIndicator(
                                color: Colors.greenAccent, strokeWidth: 2),
                          )
                        : IconButton(
                            onPressed: _togglePlay,
                            icon: Icon(
                              _playing
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              color: Colors.greenAccent,
                              size: 42,
                            ),
                          ),
                    IconButton(
                      onPressed: _currentIndex < _tracks.length - 1
                          ? _playNext
                          : null,
                      icon: Icon(Icons.skip_next,
                          color: _currentIndex < _tracks.length - 1
                              ? Colors.white
                              : Colors.white30),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  // ── Seek bar ──
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: progress,
                      activeColor: Colors.greenAccent,
                      inactiveColor: Colors.white24,
                      onChanged: (v) async {
                        final pos = Duration(
                            seconds: (v * _total.inSeconds).round());
                        await _player.seek(pos);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(_position),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                      Text(_fmt(_total),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}