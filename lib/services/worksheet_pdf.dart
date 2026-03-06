import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class WorksheetPdf {
  /// Generates a simple printable PDF offline.
  /// Returns the saved file path.
  static Future<String> buildAndSave({
    required String title,
    required String instructions,
    required List<String> items,
    required String footer,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(instructions, style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 12),
                ...items.map((e) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Row(
                        children: [
                          pw.Container(width: 16, height: 16, decoration: pw.BoxDecoration(border: pw.Border.all())),
                          pw.SizedBox(width: 10),
                          pw.Expanded(child: pw.Text(e, style: const pw.TextStyle(fontSize: 14))),
                          pw.SizedBox(width: 12),
                          pw.Container(width: 140, height: 18, decoration: pw.BoxDecoration(border: pw.Border.all())),
                        ],
                      ),
                    )),
                pw.Spacer(),
                pw.Text(
                  footer,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final safe = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp('_+'), '_');
    final file = File('${dir.path}/$safe.pdf');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }
}
