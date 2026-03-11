import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bitaqwa/model/quran_models.dart';
import 'package:bitaqwa/pages/quran_detail_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuratCard extends StatefulWidget {
  final Surat surat;

  const SuratCard({super.key, required this.surat});

  @override
  State<SuratCard> createState() => _SuratCardState();
}

class _SuratCardState extends State<SuratCard> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkOffline();
  }

  Future<void> _checkOffline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final qari = prefs.getString('selectedQari') ?? "05";
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        "${dir.path}/quran/audio/${widget.surat.nomor}/$qari/full.mp3",
      );
      if (await file.exists()) {
        if (mounted) setState(() => _isOffline = true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuranDetailPage(suratId: widget.surat.nomor),
          ),
        );
        _checkOffline(); // Refresh status balik dari detail
      },
      borderRadius: BorderRadius.circular(14),
      child: Hero(
        tag: 'surat_${widget.surat.nomor}',
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.green.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withAlpha(38),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade100,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.surat.nomor.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.surat.namaLatin,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isOffline) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.cloud_done_rounded,
                              size: 16,
                              color: Colors.blueAccent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "${widget.surat.arti} • ${widget.surat.jumlahAyat} ayat",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget.surat.tempatTurun.toLowerCase() ==
                                      "mekah"
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.surat.tempatTurun,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    widget.surat.tempatTurun.toLowerCase() ==
                                        "mekah"
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      widget.surat.nama,
                      style: const TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 22,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
