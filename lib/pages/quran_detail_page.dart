// ================================================================
// 📖 QURAN DETAIL PAGE — PRO+
// Fitur:
//  - Audio Full Surat & Per Ayat
//  - Auto Sync Highlight + Scroll
//  - Progress Mini per Ayat
//  - Dropdown Qari + Cache SharedPreferences
//  - Analisis Tilawah (statistik baca)
//  - Offline Mode (cache audio & data surat)
//  - Repeat / Shuffle Hafalan Mode
// ================================================================

import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/quran/ayat_card.dart';
import '../widgets/quran/quran_detail_header.dart';
import '../widgets/quran/quran_audio_player_card.dart';
import '../widgets/quran/quran_tilawah_stats_card.dart';
import 'package:bitaqwa/pages/quran_tafsir_page.dart';
import 'package:bitaqwa/model/quran_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranDetailPage extends StatefulWidget {
  final int suratId;
  final int? startAyat;
  const QuranDetailPage({super.key, required this.suratId, this.startAyat});

  @override
  State<QuranDetailPage> createState() => _QuranDetailPageState();
}

class _QuranDetailPageState extends State<QuranDetailPage> {
  Surat? surat;
  List<Ayat> ayatList = [];
  bool isLoading = true;
  bool isFullSurahPlaying = false;

  final AudioPlayer player = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  SharedPreferences? prefs;
  final String cacheKey = 'cachedSurat_';
  final String bookmarkKey = 'quran_bookmarks';
  String selectedQari = "05";
  List<String> bookmarks = [];

  int totalAyatRead = 0;
  Duration totalWaktuTilawah = Duration.zero;
  DateTime? lastRead;

  bool isAudioCached = false;
  double downloadProgress = 0;
  bool isDownloading = false;

  bool isRepeatMode = false;
  bool isShuffleMode = false;

  final ScrollController _scrollController = ScrollController();
  List<double> ayatDurasi = [];
  List<double> ayatMulai = [];

  int? currentAyatPlaying;
  double ayatProgress = 0;
  List<GlobalKey> ayatKeys = [];
  bool _hasJumped = false;
  int? _highlightedAyatId;

  final Map<String, String> qariList = {
    "01": "Abdullah Al-Juhany",
    "02": "Abdul-Muhsin Al-Qasim",
    "03": "Abdurrahman As-Sudais",
    "04": "Ibrahim Al-Dossari",
    "05": "Misyari Rasyid Al-Afasi",
  };

  @override
  void initState() {
    super.initState();
    initPrefs();
    setupAudioListeners();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    selectedQari = prefs?.getString('selectedQari') ?? "05";
    bookmarks = prefs?.getStringList(bookmarkKey) ?? [];
    await _loadTilawahStats();
    await fetchSuratDetail();
    await _checkAudioCached();
  }

  void _jumpToStartAyat() {
    if (ayatList.isEmpty || widget.startAyat == null || _hasJumped) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      int index = ayatList.indexWhere((a) => a.nomorAyat == widget.startAyat);
      if (index != -1) {
        debugPrint(
          "🚀 [JUMP] Triggered jump to index $index (Ayah ${widget.startAyat})",
        );
        _hasJumped = true;
        // Berikan sedikit delay tambahan agar ListView benar-benar siap
        await Future.delayed(const Duration(milliseconds: 300));
        _robustScrollToAyat(index);
      }
    });
  }

  Future<void> _robustScrollToAyat(int index) async {
    if (index < 0 || index >= ayatKeys.length) return;
    final targetKey = ayatKeys[index];
    final targetAyatId = ayatList[index].nomorAyat;

    if (mounted) setState(() => _highlightedAyatId = targetAyatId);

    // Progressive Strategy:
    // Menggunakan jumpTo (tanpa animasi) untuk mencari item agar tidak konflik animasi.
    // Menambah estimasi secara agresif jika item belum ditemukan (un-rendered).
    final List<double> heights = [450.0, 550.0, 650.0];
    int tryIdx = 0;

    for (int i = 0; i < 40; i++) {
      if (!mounted) break;

      final context = targetKey.currentContext;
      if (context != null) {
        debugPrint("✅ [SCROLL] Success! Item rendered. Pinning to top...");
        try {
          await Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutQuad,
            alignment: 0.0,
          );

          Future.delayed(const Duration(seconds: 4), () {
            if (mounted && _highlightedAyatId == targetAyatId) {
              setState(() => _highlightedAyatId = null);
            }
          });
          return; // LANGSUNG KELUAR jika sudah ketemu dan animasi jalan
        } catch (e) {
          debugPrint("⚠️ [SCROLL] ensureVisible error: $e");
        }
      }

      // Setiap 3 iterasi tanpa hasil, lakukan jump instan ke lokasi baru
      if (i % 3 == 0 && _scrollController.hasClients) {
        double currentH = heights[tryIdx % heights.length];
        double headerH = 600.0;
        double targetPos = headerH + (index * currentH);
        double max = _scrollController.position.maxScrollExtent;

        debugPrint("🔄 [SCROLL] Searching at $targetPos (Try $i)");
        _scrollController.jumpTo(targetPos.clamp(0.0, max));
        tryIdx++;
      }

      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  void setupAudioListeners() {
    player.onDurationChanged.listen((d) {
      if (mounted) setState(() => totalDuration = d);
      if (ayatList.isNotEmpty && d.inSeconds > 0)
        _generateAyatDurasi(d.inSeconds);
    });
    player.onPositionChanged.listen((p) {
      if (mounted) setState(() => currentPosition = p);
      if (isFullSurahPlaying) _updateActiveAyat(p.inSeconds.toDouble());
    });
    player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => isPlaying = s == PlayerState.playing);
    });
    player.onPlayerComplete.listen((_) async {
      if (isFullSurahPlaying) await _updateTilawahStats();
      if (mounted)
        setState(() {
          currentAyatPlaying = null;
          ayatProgress = 0;
        });
    });
  }

  bool _isAyatBookmarked(int nomorAyat) {
    return bookmarks.any((b) {
      try {
        return json.decode(b)['id'] == "${widget.suratId}:$nomorAyat";
      } catch (_) {
        return false;
      }
    });
  }

  Future<void> _toggleBookmark(Ayat a) async {
    final String id = "${widget.suratId}:${a.nomorAyat}";
    final bookmarkItem = json.encode({
      'id': id,
      'suratId': widget.suratId,
      'nomorAyat': a.nomorAyat,
      'suratName': surat?.namaLatin ?? "Surat",
      'teksArab': a.teksArab,
    });
    setState(() {
      if (_isAyatBookmarked(a.nomorAyat)) {
        bookmarks.removeWhere((b) {
          try {
            return json.decode(b)['id'] == id;
          } catch (_) {
            return false;
          }
        });
      } else {
        bookmarks.add(bookmarkItem);
      }
    });
    await prefs?.setStringList(bookmarkKey, bookmarks);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            _isAyatBookmarked(a.nomorAyat)
                ? "Ayat ditambahkan"
                : "Ayat dihapus",
          ),
        ),
      );
  }

  Future<void> _updateTilawahStats() async {
    totalAyatRead += 1;
    totalWaktuTilawah += totalDuration;
    lastRead = DateTime.now();
    prefs?.setString(
      'tilawahStats',
      json.encode({
        'totalAyatRead': totalAyatRead,
        'totalWaktuTilawah': totalWaktuTilawah.inSeconds,
        'lastRead': lastRead!.toIso8601String(),
      }),
    );
  }

  Future<void> _loadTilawahStats() async {
    final data = prefs?.getString('tilawahStats');
    if (data != null) {
      final j = json.decode(data);
      totalAyatRead = j['totalAyatRead'];
      totalWaktuTilawah = Duration(seconds: j['totalWaktuTilawah']);
      lastRead = DateTime.tryParse(j['lastRead']);
    }
  }

  Future<void> _checkAudioCached() async {
    final dir = await getApplicationDocumentsDirectory();
    final surahDir = Directory(
      "${dir.path}/quran/audio/${widget.suratId}/$selectedQari",
    );
    if (await surahDir.exists()) {
      final files = surahDir.listSync();
      if (files.any((f) => f.path.endsWith("full.mp3")))
        if (mounted) setState(() => isAudioCached = true);
    } else if (mounted)
      setState(() => isAudioCached = false);
  }

  Future<void> _cacheAudioFiles() async {
    if (surat == null || isDownloading) return;
    try {
      setState(() {
        isDownloading = true;
        downloadProgress = 0;
      });
      final dir = await getApplicationDocumentsDirectory();
      final surahPath =
          "${dir.path}/quran/audio/${widget.suratId}/$selectedQari";
      final surahDir = Directory(surahPath);
      if (!await surahDir.exists()) await surahDir.create(recursive: true);
      final fullUrl = surat!.audioFull[selectedQari];
      if (fullUrl != null) {
        final fullFile = File("$surahPath/full.mp3");
        if (!await fullFile.exists()) {
          final res = await http.get(Uri.parse(fullUrl));
          await fullFile.writeAsBytes(res.bodyBytes);
        }
      }
      int completed = 0;
      for (var a in ayatList) {
        final url = a.audio[selectedQari];
        if (url == null || url.isEmpty) continue;
        final file = File("$surahPath/${a.nomorAyat}.mp3");
        if (!await file.exists()) {
          final res = await http.get(Uri.parse(url));
          await file.writeAsBytes(res.bodyBytes);
        }
        completed++;
        setState(() => downloadProgress = completed / ayatList.length);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Surat berhasil di-download!")),
        );
        setState(() {
          isAudioCached = true;
          isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal download: $e")));
        setState(() => isDownloading = false);
      }
    }
  }

  Future<void> fetchSuratDetail() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final cached = prefs?.getString('$cacheKey${widget.suratId}');
    if (cached != null) {
      final data = json.decode(cached);
      if (mounted) {
        setState(() {
          surat = Surat.fromJson(data);
          ayatList = (data['ayat'] as List)
              .map((e) => Ayat.fromJson(e))
              .toList();
          if (ayatKeys.length != ayatList.length) {
            ayatKeys = List.generate(ayatList.length, (index) => GlobalKey());
          }
          isLoading = false;
        });
        _jumpToStartAyat();
      }
    }
    try {
      final res = await http.get(
        Uri.parse('https://equran.id/api/v2/surat/${widget.suratId}'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        prefs?.setString('$cacheKey${widget.suratId}', json.encode(data));
        if (mounted) {
          setState(() {
            surat = Surat.fromJson(data);
            ayatList = (data['ayat'] as List)
                .map((e) => Ayat.fromJson(e))
                .toList();
            if (ayatKeys.length != ayatList.length) {
              ayatKeys = List.generate(ayatList.length, (index) => GlobalKey());
            }
            isLoading = false;
          });
          _jumpToStartAyat();
        }
      }
    } catch (_) {
      if (mounted && surat != null) setState(() => isLoading = false);
    }
  }

  void _generateAyatDurasi(int totalSeconds) {
    if (ayatList.isEmpty) return;
    final totalLength = ayatList.fold<int>(
      0,
      (sum, a) => sum + a.teksArab.length,
    );
    double total = 0;
    ayatDurasi.clear();
    ayatMulai.clear();
    for (var a in ayatList) {
      final proporsi = a.teksArab.length / totalLength;
      final durasiAyat = totalSeconds * proporsi;
      ayatDurasi.add(durasiAyat);
      ayatMulai.add(total);
      total += durasiAyat;
    }
  }

  void _updateActiveAyat(double second) {
    if (ayatMulai.isEmpty) return;
    for (int i = 0; i < ayatMulai.length; i++) {
      final start = ayatMulai[i];
      final end = start + ayatDurasi[i];
      if (second >= start && second < end) {
        if (currentAyatPlaying != ayatList[i].nomorAyat) {
          setState(() => currentAyatPlaying = ayatList[i].nomorAyat);
          _scrollToAyat(i);
        }
        if (mounted)
          setState(() => ayatProgress = (second - start) / (end - start));
        break;
      }
    }
  }

  Future<void> stopAudio() async {
    await player.stop();
    setState(() {
      isFullSurahPlaying = false;
      currentAyatPlaying = null;
      currentPosition = Duration.zero;
    });
  }

  Future<void> pauseAudio() async {
    await player.pause();
  }

  Future<void> playAudioFull() async {
    if (surat == null) return;
    final url = surat!.audioFull[selectedQari];
    if (url == null || url.isEmpty) return;

    setState(() {
      isFullSurahPlaying = true;
      isPlaying = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        "${dir.path}/quran/audio/${widget.suratId}/$selectedQari/full.mp3",
      );
      if (await file.exists()) {
        await player.play(DeviceFileSource(file.path));
      } else {
        await player.play(UrlSource(url));
      }
    } catch (e) {
      debugPrint("Error playing full surah: $e");
      if (mounted) {
        setState(() {
          isFullSurahPlaying = false;
          isPlaying = false;
        });
      }
    }
  }

  Future<void> playAyat(Ayat a, int index) async {
    if (currentAyatPlaying == a.nomorAyat && isPlaying) {
      await player.pause();
      return;
    }

    final url = a.audio[selectedQari];
    if (url == null || url.isEmpty) return;

    setState(() {
      isFullSurahPlaying = false;
      currentAyatPlaying = a.nomorAyat;
      ayatProgress = 0;
      isPlaying = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        "${dir.path}/quran/audio/${widget.suratId}/$selectedQari/${a.nomorAyat}.mp3",
      );
      if (await file.exists()) {
        await player.play(DeviceFileSource(file.path));
      } else {
        await player.play(UrlSource(url));
      }
      _scrollToAyat(index);
    } catch (e) {
      debugPrint("Error playing ayat: $e");
      if (mounted) {
        setState(() {
          isPlaying = false;
          currentAyatPlaying = null;
        });
      }
    }
  }

  void _scrollToAyat(int i) {
    _robustScrollToAyat(i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(surat?.namaLatin ?? "Memuat..."),
        backgroundColor: Colors.green[700],
        actions: [
          if (isDownloading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                isAudioCached
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_download_rounded,
                color: isAudioCached ? Colors.lightBlueAccent : Colors.white,
              ),
              onPressed: isAudioCached ? null : _cacheAudioFiles,
            ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () {
              if (surat == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuranTafsirPage(suratId: surat!.nomor),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                QuranTilawahStatsCard(
                  totalAyatRead: totalAyatRead,
                  totalWaktuTilawah: totalWaktuTilawah,
                  lastRead: lastRead,
                ),
                const SizedBox(height: 8),
                QuranAudioPlayerCard(
                  selectedQari: selectedQari,
                  qariList: qariList,
                  currentPosition: currentPosition,
                  totalDuration: totalDuration,
                  isPlaying: isPlaying,
                  isRepeatMode: isRepeatMode,
                  isShuffleMode: isShuffleMode,
                  onQariChanged: (v) async {
                    if (v == null) return;
                    await player.stop();
                    setState(() {
                      selectedQari = v;
                      isAudioCached = false;
                    });
                    prefs?.setString('selectedQari', v);
                    await _checkAudioCached();
                  },
                  onSeek: (v) => player.seek(Duration(seconds: v.toInt())),
                  onStop: stopAudio,
                  onPlayPause: () async =>
                      isPlaying ? pauseAudio() : playAudioFull(),
                  onToggleRepeat: () =>
                      setState(() => isRepeatMode = !isRepeatMode),
                  onToggleShuffle: () =>
                      setState(() => isShuffleMode = !isShuffleMode),
                  formatDuration: (d) {
                    final m = d.inMinutes
                        .remainder(60)
                        .toString()
                        .padLeft(2, '0');
                    final s = d.inSeconds
                        .remainder(60)
                        .toString()
                        .padLeft(2, '0');
                    return "$m:$s";
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    isFullSurahPlaying ? "🟢 Full Mode" : "🔵 Ayat Mode",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                QuranDetailHeader(surat: surat),
                ...List.generate(ayatList.length, (i) {
                  final a = ayatList[i];
                  return AyatCard(
                    key: ayatKeys[i],
                    ayat: a,
                    isActive:
                        a.nomorAyat == currentAyatPlaying ||
                        a.nomorAyat == _highlightedAyatId,
                    isFullSurahPlaying:
                        isFullSurahPlaying || a.nomorAyat == _highlightedAyatId,
                    progress: a.nomorAyat == currentAyatPlaying
                        ? ayatProgress
                        : 0,
                    isBookmarked: _isAyatBookmarked(a.nomorAyat),
                    onPlay: () => playAyat(a, i),
                    onBookmark: () => _toggleBookmark(a),
                  );
                }),
              ],
            ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
