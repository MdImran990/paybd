import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/transaction.dart';
import '../utils/format.dart';
import '../utils/tx_ui.dart';

// The built-in PDF font has no taka sign, so the PDF writes "Tk" instead.
String _tk(int minor) => formatTaka(minor).replaceFirst('৳', 'Tk');

pw.Widget _cell(String text, {bool bold = false, PdfColor? color}) => pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );

pw.Widget _box(String label, String value) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            pw.Text(value,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

/// Builds the statement PDF (English only).
Future<Uint8List> buildStatementPdf({
  required String name,
  required String phone,
  required String periodLabel,
  required List<Transaction> txs,
  required int moneyIn,
  required int moneyOut,
}) async {
  final doc = pw.Document();
  final pink = PdfColor.fromHex('#E2136E');

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: pw.BoxDecoration(color: pink),
      children: [
        for (final h in const [
          'Date',
          'Details',
          'Type',
          'Amount',
          'Fee',
          'Transaction ID',
        ])
          _cell(h, bold: true, color: PdfColors.white),
      ],
    ),
    for (final t in txs)
      pw.TableRow(
        children: [
          _cell(formatDateTime(t.createdAt)),
          _cell(txTitle(t)),
          _cell(t.type.label),
          _cell('${t.isCredit ? '+' : '-'}${_tk(t.amountMinor)}'),
          _cell(_tk(t.feeMinor)),
          _cell(t.id),
        ],
      ),
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
      build: (ctx) => [
        pw.Text('PayBD Statement',
            style: pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold, color: pink)),
        pw.Text('DEMO statement. Not real money.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 12),
        pw.Text('Account: $name', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Mobile: $phone', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Period: $periodLabel', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Generated: ${formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            _box('Money in', _tk(moneyIn)),
            pw.SizedBox(width: 10),
            _box('Money out', _tk(moneyOut)),
            pw.SizedBox(width: 10),
            _box('Transactions', '${txs.length}'),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.4),
            1: pw.FlexColumnWidth(3.4),
            2: pw.FlexColumnWidth(2.0),
            3: pw.FlexColumnWidth(2.0),
            4: pw.FlexColumnWidth(1.2),
            5: pw.FlexColumnWidth(2.6),
          },
          children: rows,
        ),
      ],
    ),
  );
  return doc.save();
}
