import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/core/constants.dart';

void main() {
  group('ApiConstants', () {
    test('uses configured API_BASE_URL when provided', () {
      expect(
        ApiConstants.resolveBaseUrl(
          isProductionBuild: false,
          configuredBaseUrl: ' https://api.example.com ',
        ),
        'https://api.example.com',
      );
    });

    test('uses production backend for production builds without override', () {
      expect(
        ApiConstants.resolveBaseUrl(
          isProductionBuild: true,
          configuredBaseUrl: '',
        ),
        'https://pickstarpet.kkqin.com',
      );
    });

    test('uses local backend for development builds without override', () {
      expect(
        ApiConstants.resolveBaseUrl(
          isProductionBuild: false,
          configuredBaseUrl: '',
        ),
        'http://10.0.2.2:8000',
      );
    });
  });
}
