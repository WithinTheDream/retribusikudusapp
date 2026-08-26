import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retribusikudusapp/main.dart';
import 'package:retribusikudusapp/utils/formatters.dart';

void main() {
  testWidgets('App smoke test loads SplashScreen and navigates', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the splash screen title is rendered initially.
    expect(find.text('Retribusi Sampah Kudus'), findsOneWidget);

    // Fast-forward the splash timer
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  group('AppFormatters Tests', () {
    test('formatRupiah formats numeric and string values correctly', () {
      expect(AppFormatters.formatRupiah(25000), 'Rp 25.000');
      expect(AppFormatters.formatRupiah('50000'), 'Rp 50.000');
      expect(AppFormatters.formatRupiah(0), 'Rp 0');
      expect(AppFormatters.formatRupiah(null), 'Rp 0');
    });

    test('formatTanggal formats date strings correctly', () {
      final date = DateTime(2026, 8, 26);
      expect(AppFormatters.formatTanggal(date), contains('2026'));
      expect(AppFormatters.formatTanggal('2026-08-26'), contains('2026'));
      expect(AppFormatters.formatTanggal(null), '-');
    });
  });
}
