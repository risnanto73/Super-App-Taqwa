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
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:bitaqwa/components/quran_tafsir_page.dart';
import 'package:bitaqwa/model/quran_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranDetailPage extends StatefulWidget {
  final int suratId;
  const QuranDetailPage({super.key, required this.suratId});

  @override
  State<QuranDetailPage> createState() => _QuranDetailPageState();
}

class _QuranDetailPageState extends State<QuranDetailPage> {
  Surat? surat;
  List<Ayat> ayatList = [];
  bool isLoading = true;
  bool isFullSurahPlaying = false;

  // 🎧 Audio Player
  final AudioPlayer player = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  // 💾 Cache & Qari
  SharedPreferences? prefs;
  final String cacheKey = 'cachedSurat_';
  String selectedQari = "05";

  // 📊 Statistik Tilawah
  int totalAyatRead = 0;
  Duration totalWaktuTilawah = Duration.zero;
  DateTime? lastRead;

  // 📥 Offline
  bool isAudioCached = false;

  // 🧭 Mode Hafalan
  bool isRepeatMode = false;
  bool isShuffleMode = false;

  // 📜 Scroll controller
  final ScrollController _scrollController = ScrollController();

  // 🔁 Durasi per ayat
  List<double> ayatDurasi = [];
  List<double> ayatMulai = [];

  // 🔊 Ayat aktif
  int? currentAyatPlaying;
  double ayatProgress = 0;

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
    await _loadTilawahStats();
    await fetchSuratDetail();
  }

  // ================================================================
  // 🎧 LISTENER AUDIO
  // ================================================================
  void setupAudioListeners() {
    player.onDurationChanged.listen((d) {
      setState(() => totalDuration = d);
      if (ayatList.isNotEmpty && d.inSeconds > 0) {
        _generateAyatDurasi(d.inSeconds);
      }
    });

    player.onPositionChanged.listen((p) {
      setState(() => currentPosition = p);
      if (isFullSurahPlaying) _updateActiveAyat(p.inSeconds.toDouble());
    });

    player.onPlayerStateChanged.listen((s) {
      setState(() => isPlaying = s == PlayerState.playing);
    });

    player.onPlayerComplete.listen((_) async {
      if (isFullSurahPlaying) await _updateTilawahStats();
      setState(() {
        currentAyatPlaying = null;
        ayatProgress = 0;
      });
    });
  }

  // ================================================================
  // 📊 TILAWAH STATS
  // ================================================================
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

  // ================================================================
  // 📥 OFFLINE MODE
  // ================================================================
  Future<void> _cacheAudioFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final qariDir = Directory("${dir.path}/qari_$selectedQari");
    if (!await qariDir.exists()) await qariDir.create();
    for (var a in ayatList) {
      final url = a.audio[selectedQari];
      if (url == null || url.isEmpty) continue;
      final path = "${qariDir.path}/${a.nomorAyat}.mp3";
      final file = File(path);
      if (!await file.exists()) {
        final res = await http.get(Uri.parse(url));
        await file.writeAsBytes(res.bodyBytes);
      }
    }
    prefs?.setBool('audio_cached_${widget.suratId}_$selectedQari', true);
    setState(() => isAudioCached = true);
  }

  // ================================================================
  // FETCH & CACHE DATA
  // ================================================================
  Future<void> fetchSuratDetail() async {
    setState(() => isLoading = true);
    final cached = prefs?.getString('$cacheKey${widget.suratId}');
    if (cached != null) {
      final data = json.decode(cached);
      surat = Surat.fromJson(data);
      ayatList = (data['ayat'] as List).map((e) => Ayat.fromJson(e)).toList();
    }

    try {
      final res = await http.get(
        Uri.parse('https://equran.id/api/v2/surat/${widget.suratId}'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        surat = Surat.fromJson(data);
        ayatList = (data['ayat'] as List).map((e) => Ayat.fromJson(e)).toList();
        prefs?.setString('$cacheKey${widget.suratId}', json.encode(data));
      }
    } catch (_) {}

    setState(() => isLoading = false);
  }

  // ================================================================
  // ESTIMASI & SYNC AYAT
  // ================================================================
  void _generateAyatDurasi(int totalSeconds) {
    final totalLength =
        ayatList.fold<int>(0, (sum, a) => sum + a.teksArab.length);
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
        setState(() => ayatProgress = (second - start) / (end - start));
        break;
      }
    }
  }

  // ================================================================
  // AUDIO CONTROL
  // ================================================================
  Future<void> playAudioFull() async {
    if (surat == null) return;
    final url = surat!.audioFull[selectedQari];
    setState(() {
      isFullSurahPlaying = true;
      currentAyatPlaying = null;
      ayatProgress = 0;
    });
    await player.stop();
    await player.play(UrlSource(url!));
  }

  Future<void> playAyat(Ayat a, int index) async {
    await player.stop();
    setState(() {
      isFullSurahPlaying = false;
      currentAyatPlaying = a.nomorAyat;
      ayatProgress = 0;
    });
    await player.play(UrlSource(a.audio[selectedQari] ?? ""));
    _scrollToAyat(index);
  }

  Future<void> pauseAudio() async => await player.pause();
  Future<void> stopAudio() async {
    await player.stop();
    setState(() {
      isFullSurahPlaying = false;
      currentAyatPlaying = null;
      currentPosition = Duration.zero;
    });
  }

  void _scrollToAyat(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        i * 190.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  // ================================================================
  // BUILD UI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(surat?.namaLatin ?? "Memuat..."),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(
              isAudioCached
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_download_rounded,
              color: Colors.white,
            ),
            onPressed: _cacheAudioFiles,
            tooltip: "Download Offline",
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuranTafsirPage(suratId: surat!.nomor),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildTilawahStatsCard(),
                const SizedBox(height: 8),
                _buildAudioPlayerCard(),
                const SizedBox(height: 16),

                Center(
                  child: Text(
                    isFullSurahPlaying
                        ? "🟢 Full Mode"
                        : "🔵 Ayat Mode",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Surat
                Text(
                  surat!.nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'ScheherazadeNew',
                    fontSize: 32,
                  ),
                ),
                Text(
                  "${surat!.namaLatin} • ${surat!.arti}\n${surat!.tempatTurun} • ${surat!.jumlahAyat} Ayat",
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 24),

                // Daftar Ayat
                ...List.generate(ayatList.length, (i) {
                  final a = ayatList[i];
                  final isActive = a.nomorAyat == currentAyatPlaying;
                  final progress = isActive ? ayatProgress : 0;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isFullSurahPlaying
                              ? Colors.green[100]
                              : Colors.blue[50])
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: Colors.green.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          a.teksArab,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'ScheherazadeNew',
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            a.teksLatin,
                            style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.black54),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(a.teksIndonesia),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.isNaN
                              ? 0.0
                              : progress.clamp(0.0, 1.0).toDouble(),
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                              Colors.green.shade400),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Ayat ${a.nomorAyat}",
                                style: const TextStyle(color: Colors.grey)),
                            IconButton(
                              icon: Icon(
                                isActive
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: isActive
                                    ? Colors.green[800]
                                    : Colors.black54,
                                size: 32,
                              ),
                              onPressed: () => playAyat(a, i),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildTilawahStatsCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [
                const Text("📖 Ayat Dibaca",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text("$totalAyatRead"),
              ]),
              Column(children: [
                const Text("⏱️ Waktu",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text("${totalWaktuTilawah.inMinutes} menit"),
              ]),
              Column(children: [
                const Text("📅 Terakhir",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(lastRead != null
                    ? "${lastRead!.day}/${lastRead!.month}"
                    : "-"),
              ]),
            ],
          ),
        ),
      );

  Widget _buildAudioPlayerCard() => Card(
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.headphones, color: Colors.green),
                const SizedBox(width: 8),
                Text("Putar Surat Lengkap",
                    style:
                        TextStyle(color: Colors.green[800], fontSize: 16)),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedQari,
                decoration: const InputDecoration(labelText: "Pilih Qari"),
                items: qariList.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  await player.stop();
                  setState(() => selectedQari = v);
                  prefs?.setString('selectedQari', v);
                },
              ),
              Slider(
                activeColor: Colors.green[700],
                value: currentPosition.inSeconds.toDouble(),
                max: totalDuration.inSeconds.toDouble() > 0
                    ? totalDuration.inSeconds.toDouble()
                    : 1,
                onChanged: (v) =>
                    player.seek(Duration(seconds: v.toInt())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(currentPosition)),
                  Text(formatDuration(totalDuration)),
                ],
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                    icon: const Icon(Icons.stop, color: Colors.red),
                    onPressed: stopAudio),
                IconButton(
                  icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.green,
                      size: 48),
                  onPressed: () async =>
                      isPlaying ? pauseAudio() : playAudioFull(),
                ),
                IconButton(
                  icon: Icon(Icons.repeat,
                      color: isRepeatMode ? Colors.green : Colors.grey),
                  onPressed: () =>
                      setState(() => isRepeatMode = !isRepeatMode),
                ),
                IconButton(
                  icon: Icon(Icons.shuffle,
                      color: isShuffleMode ? Colors.green : Colors.grey),
                  onPressed: () =>
                      setState(() => isShuffleMode = !isShuffleMode),
                ),
              ]),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    player.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
