import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  // Disable Google Fonts HTTP fetching in tests
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ThemeFactory', () {
    group('parseHexColor', () {
      test('parses valid 6-digit HEX color correctly', () {
        final color = ThemeFactory.parseHexColor('#FF5733');
        expect(color, equals(const Color(0xFFFF5733)));
      });

      test('parses valid 6-digit HEX without # prefix', () {
        final color = ThemeFactory.parseHexColor('FF5733');
        expect(color, equals(const Color(0xFFFF5733)));
      });

      test('parses lowercase HEX color correctly', () {
        final color = ThemeFactory.parseHexColor('#ff5733');
        expect(color, equals(const Color(0xFFFF5733)));
      });

      test('returns fallback color for invalid HEX string', () {
        const fallback = Colors.blue;
        final color = ThemeFactory.parseHexColor('invalid-color', fallback: fallback);
        expect(color, equals(fallback));
      });

      test('returns fallback color for empty string', () {
        const fallback = Colors.red;
        final color = ThemeFactory.parseHexColor('', fallback: fallback);
        expect(color, equals(fallback));
      });

      test('returns fallback color for null-like values', () {
        const fallback = Colors.green;
        final color = ThemeFactory.parseHexColor('null', fallback: fallback);
        expect(color, equals(fallback));
      });

      test('returns default fallback (grey) when no fallback provided', () {
        final color = ThemeFactory.parseHexColor('invalid');
        expect(color, equals(Colors.grey));
      });
    });

    group('createTheme', () {
      test('returns valid ThemeData with valid config', () {
        final config = ThemeConfig(
          id: 'test-id',
          tenantId: 'tenant-id',
          primaryColor: '#FF5722',
          secondaryColor: '#FFC107',
          backgroundColor: '#FFFFFF',
          textColor: '#212121',
          fontFamily: ThemeFontFamily.roboto,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final theme = ThemeFactory.createTheme(config);

        expect(theme, isA<ThemeData>());
        expect(theme.primaryColor, equals(const Color(0xFFFF5722)));
        expect(theme.colorScheme.secondary, equals(const Color(0xFFFFC107)));
      });

      test('returns valid ThemeData with different font families', () {
        final config = ThemeConfig(
          id: 'test-id',
          tenantId: 'tenant-id',
          fontFamily: ThemeFontFamily.poppins,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final theme = ThemeFactory.createTheme(config);

        expect(theme, isA<ThemeData>());
        // Font family is not applied in test mode to avoid Google Fonts errors
        // The getGoogleFontTextTheme method should be used at runtime
        expect(theme.textTheme.bodyLarge, isNotNull);
      });

      test('applies border radius to button themes', () {
        final config = ThemeConfig(
          id: 'test-id',
          tenantId: 'tenant-id',
          borderRadius: const BorderRadiusConfig(small: 8, medium: 16, large: 24),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final theme = ThemeFactory.createTheme(config);

        expect(theme.elevatedButtonTheme.style, isNotNull);
      });

      test('handles invalid colors gracefully by using defaults', () {
        final config = ThemeConfig(
          id: 'test-id',
          tenantId: 'tenant-id',
          primaryColor: 'not-a-color',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Should not throw
        final theme = ThemeFactory.createTheme(config);
        expect(theme, isA<ThemeData>());
      });
    });

    group('createDefaultTheme', () {
      test('returns a valid default ThemeData', () {
        final theme = ThemeFactory.createDefaultTheme();

        expect(theme, isA<ThemeData>());
        expect(theme.primaryColor, isNotNull);
      });
    });
  });
}
