import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/track.dart';

class TrackZineService {
  Future<List<int>> build(Track track) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(42),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
          ),
          child: pw.Text(
            'ARCHIVO DE LA PECERA // ${DateTime.now().year} // '
            '${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Text(
              'DEATHFISH // LA PECERA RECORDS',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            track.title.toUpperCase(),
            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${track.album} // TRACK ${track.number} // ${track.duration}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'LETRA // ARCHIVO COMPLETO',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            track.lyrics.isEmpty ? 'SIN LETRA ARCHIVADA.' : track.lyrics,
            style: const pw.TextStyle(fontSize: 10, lineSpacing: 4),
          ),
          pw.SizedBox(height: 18),
          pw.Divider(color: PdfColors.black),
          pw.Text(
            'CRÉDITOS / DESCRIPCIÓN\n'
            '${track.credits?.trim().isNotEmpty == true ? track.credits!.trim() : 'DEATHFISH // LA PECERA RECORDS'}\n'
            '${track.album} // ${track.duration}',
            style: const pw.TextStyle(fontSize: 8, lineSpacing: 3),
          ),
        ],
      ),
    );
    return document.save();
  }
}
