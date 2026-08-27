import 'package:intl/intl.dart';

class AppFormatters {
  /// Format angka ke format mata uang Rupiah Indonesia (contoh: Rp 25.000)
  static String formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';

    num parsedAmount = 0;
    if (amount is num) {
      parsedAmount = amount;
    } else if (amount is String) {
      parsedAmount =
          num.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return formatter.format(parsedAmount);
  }

  static const List<String> _bulanPendek = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _bulanPanjang = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Format string/DateTime ke format tanggal Indonesia (contoh: 26 Agu 2026 atau 26 Agustus 2026, 14:30)
  static String formatTanggal(
    dynamic date, {
    bool includeTime = false,
    bool shortMonth = true,
  }) {
    if (date == null) return '-';

    DateTime? dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      dateTime = DateTime.tryParse(date);
    }

    if (dateTime == null) return date.toString();

    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final monthList = shortMonth ? _bulanPendek : _bulanPanjang;
    final month = (local.month >= 1 && local.month <= 12)
        ? monthList[local.month - 1]
        : local.month.toString();
    final year = local.year.toString();

    if (includeTime) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    }

    return '$day $month $year';
  }
}
