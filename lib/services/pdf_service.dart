import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/client.dart';
import '../models/invoice.dart';
import '../models/task.dart';

class PdfService {
  static Uint8List? _logoBytes;
  static pw.Font? _arabicFont;

  static Future<void> _ensureInitialized() async {
    _arabicFont ??= await PdfGoogleFonts.cairoRegular();
    try {
      _logoBytes ??=
          (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
    } catch (_) {
      _logoBytes = null;
    }
  }

  // ─── Invoice PDF ────────────────────────────────────────────
  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required Client client,
    required List<Task> tasks,
    required String currency,
  }) async {
    await _ensureInitialized();
    final fmt = NumberFormat('#,##0', 'en');
    final dateFmt = DateFormat('yyyy/MM/dd');
    final boldFont = await PdfGoogleFonts.cairoBold();

    final pdf = pw.Document();

    final brandColor = PdfColor.fromHex('#6C63FF');
    final darkBg = PdfColor.fromHex('#0F0F1A');
    final cardBg = PdfColor.fromHex('#1E1E36');
    const textWhite = PdfColors.white;
    final textGrey = PdfColor.fromHex('#9CA3AF');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: _arabicFont,
          bold: boldFont,
        ),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(color: darkBg),
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (_logoBytes != null)
                          pw.Image(pw.MemoryImage(_logoBytes!),
                              width: 80, height: 80),
                        pw.SizedBox(height: 8),
                        pw.Text('كود بالعقل',
                            style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 18,
                                color: brandColor)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('فاتورة',
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 28,
                                color: textWhite)),
                        pw.SizedBox(height: 4),
                        pw.Text('#${invoice.invoiceNumber}',
                            style: pw.TextStyle(
                                fontSize: 20, color: brandColor)),
                        pw.SizedBox(height: 4),
                        pw.Text(dateFmt.format(invoice.issuedAt),
                            style:
                                pw.TextStyle(fontSize: 12, color: textGrey)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Divider(color: brandColor, thickness: 2),
                pw.SizedBox(height: 16),

                // Client info
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: cardBg,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('العميل',
                              textDirection: pw.TextDirection.rtl,
                              style: pw.TextStyle(
                                  fontSize: 10, color: textGrey)),
                          pw.Text(client.name,
                              textDirection: pw.TextDirection.rtl,
                              style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 16,
                                  color: textWhite)),
                          if (client.contact.isNotEmpty)
                            pw.Text(client.contact,
                                style: pw.TextStyle(
                                    fontSize: 11, color: textGrey)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('الحالة',
                              textDirection: pw.TextDirection.rtl,
                              style: pw.TextStyle(
                                  fontSize: 10, color: textGrey)),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: _statusColor(invoice.status),
                              borderRadius: pw.BorderRadius.circular(12),
                            ),
                            child: pw.Text(
                              _statusLabel(invoice.status),
                              textDirection: pw.TextDirection.rtl,
                              style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 11,
                                  color: PdfColors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Tasks table
                pw.Table(
                  border: pw.TableBorder.all(color: cardBg, width: 1),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: brandColor),
                      children: [
                        _tableCell('#', boldFont, PdfColors.white,
                            isHeader: true),
                        _tableCell('الوصف', boldFont, PdfColors.white,
                            isHeader: true),
                        _tableCell('المبلغ', boldFont, PdfColors.white,
                            isHeader: true),
                      ],
                    ),
                    // Rows
                    ...tasks.asMap().entries.map((entry) {
                      final i = entry.key;
                      final task = entry.value;
                      final rowBg =
                          i.isEven ? darkBg : cardBg;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: rowBg),
                        children: [
                          _tableCell('${i + 1}', _arabicFont!, textGrey),
                          _tableCellRtl(
                              task.title, _arabicFont!, textWhite),
                          _tableCell('${fmt.format(task.cost)} $currency',
                              _arabicFont!, textWhite),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Totals
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: cardBg,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        _totalRow('المجموع', fmt.format(invoice.subtotal),
                            currency, _arabicFont!, boldFont, textGrey),
                        if (invoice.discount > 0) ...[
                          pw.Divider(color: textGrey),
                          _totalRow(
                              'الخصم',
                              '- ${fmt.format(invoice.discount)}',
                              currency,
                              _arabicFont!,
                              boldFont,
                              PdfColors.red300),
                        ],
                        pw.Divider(color: brandColor, thickness: 2),
                        _totalRow('الإجمالي', fmt.format(invoice.total),
                            currency, _arabicFont!, boldFont, brandColor,
                            isBold: true),
                      ],
                    ),
                  ),
                ),

                if (invoice.notes.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: cardBg,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ملاحظات:',
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 11,
                                color: textGrey)),
                        pw.SizedBox(height: 4),
                        pw.Text(invoice.notes,
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(
                                fontSize: 11, color: textWhite)),
                      ],
                    ),
                  ),
                ],

                pw.Spacer(),

                // Footer
                pw.Divider(color: cardBg),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'كود بالعقل — Freelance Assistant',
                    style: pw.TextStyle(fontSize: 10, color: textGrey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ─── Account Statement PDF ──────────────────────────────────
  static Future<Uint8List> generateStatementPdf({
    required Client client,
    required List<StatementEntry> entries,
    required double totalDebit,
    required double totalCredit,
    required double balance,
    required String currency,
  }) async {
    await _ensureInitialized();
    final fmt = NumberFormat('#,##0', 'en');
    final dateFmt = DateFormat('yyyy/MM/dd');
    final boldFont = await PdfGoogleFonts.cairoBold();

    final pdf = pw.Document();

    final brandColor = PdfColor.fromHex('#6C63FF');
    final darkBg = PdfColor.fromHex('#0F0F1A');
    final cardBg = PdfColor.fromHex('#1E1E36');
    const textWhite = PdfColors.white;
    final textGrey = PdfColor.fromHex('#9CA3AF');
    final greenColor = PdfColor.fromHex('#10B981');
    final amberColor = PdfColor.fromHex('#FBBF24');
    final redColor = PdfColor.fromHex('#EF4444');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: _arabicFont,
          bold: boldFont,
        ),
        build: (context) => [
          // Header
          pw.Container(
            decoration: pw.BoxDecoration(color: darkBg),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (_logoBytes != null)
                          pw.Image(pw.MemoryImage(_logoBytes!),
                              width: 60, height: 60),
                        pw.SizedBox(height: 4),
                        pw.Text('كود بالعقل',
                            style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 14,
                                color: brandColor)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('كشف حساب',
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 24,
                                color: textWhite)),
                        pw.SizedBox(height: 4),
                        pw.Text(client.name,
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 16,
                                color: brandColor)),
                        pw.SizedBox(height: 4),
                        pw.Text(dateFmt.format(DateTime.now()),
                            style:
                                pw.TextStyle(fontSize: 11, color: textGrey)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Summary boxes
                pw.Row(
                  children: [
                    _summaryBox('إجمالي الفواتير', fmt.format(totalDebit),
                        currency, amberColor, boldFont, _arabicFont!),
                    pw.SizedBox(width: 10),
                    _summaryBox('إجمالي المدفوعات', fmt.format(totalCredit),
                        currency, greenColor, boldFont, _arabicFont!),
                    pw.SizedBox(width: 10),
                    _summaryBox(
                        'الرصيد',
                        fmt.format(balance),
                        currency,
                        balance > 0 ? redColor : greenColor,
                        boldFont,
                        _arabicFont!),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Statement table
          pw.Table(
            border: pw.TableBorder.all(color: cardBg, width: 1),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: brandColor),
                children: [
                  _tableCell('التاريخ', boldFont, PdfColors.white,
                      isHeader: true),
                  _tableCell('البيان', boldFont, PdfColors.white,
                      isHeader: true),
                  _tableCell('مدين', boldFont, PdfColors.white,
                      isHeader: true),
                  _tableCell('دائن', boldFont, PdfColors.white,
                      isHeader: true),
                  _tableCell('الرصيد', boldFont, PdfColors.white,
                      isHeader: true),
                ],
              ),
              // Rows
              ...entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final rowBg = i.isEven ? darkBg : cardBg;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowBg),
                  children: [
                    _tableCell(dateFmt.format(e.date), _arabicFont!, textGrey),
                    _tableCellRtl(e.description, _arabicFont!, textWhite),
                    _tableCell(
                        e.debit > 0 ? fmt.format(e.debit) : '',
                        _arabicFont!,
                        amberColor),
                    _tableCell(
                        e.credit > 0 ? fmt.format(e.credit) : '',
                        _arabicFont!,
                        greenColor),
                    _tableCell(
                        fmt.format(e.balance),
                        _arabicFont!,
                        e.balance > 0 ? redColor : greenColor),
                  ],
                );
              }),
              // Totals row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: brandColor),
                children: [
                  _tableCell('', boldFont, PdfColors.white),
                  _tableCell('الإجمالي', boldFont, PdfColors.white,
                      isHeader: true),
                  _tableCell('${fmt.format(totalDebit)} $currency', boldFont,
                      PdfColors.white,
                      isHeader: true),
                  _tableCell('${fmt.format(totalCredit)} $currency', boldFont,
                      PdfColors.white,
                      isHeader: true),
                  _tableCell('${fmt.format(balance)} $currency', boldFont,
                      PdfColors.white,
                      isHeader: true),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Footer
          pw.Center(
            child: pw.Text(
              'كود بالعقل — Freelance Assistant',
              style: pw.TextStyle(fontSize: 10, color: textGrey),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Helpers ────────────────────────────────────────────────
  static pw.Widget _tableCell(String text, pw.Font font, PdfColor color,
      {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 11 : 10,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _tableCellRtl(String text, pw.Font font, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        maxLines: 2,
        style: pw.TextStyle(font: font, fontSize: 10, color: color),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, String currency,
      pw.Font baseFont, pw.Font boldFont, PdfColor color,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                  font: isBold ? boldFont : baseFont,
                  fontSize: isBold ? 14 : 11,
                  color: color)),
          pw.Text('$value $currency',
              style: pw.TextStyle(
                  font: isBold ? boldFont : baseFont,
                  fontSize: isBold ? 14 : 11,
                  color: color)),
        ],
      ),
    );
  }

  static pw.Widget _summaryBox(String label, String value, String currency,
      PdfColor color, pw.Font boldFont, pw.Font baseFont) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            pw.Text(label,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                    font: baseFont, fontSize: 9, color: color)),
            pw.SizedBox(height: 4),
            pw.FittedBox(
              child: pw.Text('$value $currency',
                  style: pw.TextStyle(
                      font: boldFont, fontSize: 13, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  static PdfColor _statusColor(String status) {
    switch (status) {
      case 'draft':
        return PdfColors.grey;
      case 'sent':
        return PdfColors.blue;
      case 'paid':
        return PdfColor.fromHex('#10B981');
      case 'cancelled':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'مسودة';
      case 'sent':
        return 'مُرسلة';
      case 'paid':
        return 'مدفوعة';
      case 'cancelled':
        return 'ملغاة';
      default:
        return status;
    }
  }
}

/// Reusable entry model for statement PDF
class StatementEntry {
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  double balance;

  StatementEntry({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    this.balance = 0,
  });
}
