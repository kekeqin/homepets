import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/core/support_links.dart';

void main() {
  group('SupportLinks', () {
    test('exposes stable site endpoints', () {
      expect(SupportLinks.siteOrigin, 'https://pickstarpet.kkqin.com');
      expect(SupportLinks.privacyUrl, endsWith('/privacy.html'));
      expect(SupportLinks.termsUrl, endsWith('/terms.html'));
      expect(SupportLinks.supportUrl, endsWith('/support.html'));
      expect(SupportLinks.supportEmail, 'support@kkqin.com');
    });

    test('builds support mailto with encoded subject and body', () {
      final uri = SupportLinks.supportMailtoUri(appVersion: '1.0.0');

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'support@kkqin.com');
      expect(uri.query, contains(Uri.encodeComponent('【拾星小宠】订阅/账号问题')));
      expect(uri.query, contains(Uri.encodeComponent('App 版本：1.0.0')));
      expect(uri.query, contains(Uri.encodeComponent('设备：iOS')));
    });

    test('builds delete-account mailto with encoded subject and body', () {
      final uri = SupportLinks.deleteAccountMailtoUri(
        appVersion: '1.2.3',
        publicId: 'abc234',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'support@kkqin.com');
      expect(uri.query, contains(Uri.encodeComponent('申请删除账号与数据')));
      expect(uri.query, contains(Uri.encodeComponent('App 版本：1.2.3')));
      expect(uri.query, contains(Uri.encodeComponent('专属 ID：ABC234')));
      expect(
        uri.query,
        contains(Uri.encodeComponent('我已知悉删除后数据通常无法恢复。')),
      );
    });

    test('page URIs point at pickstarpet legal pages', () {
      expect(SupportLinks.privacyPageUri.toString(), SupportLinks.privacyUrl);
      expect(SupportLinks.termsPageUri.toString(), SupportLinks.termsUrl);
      expect(SupportLinks.supportPageUri.toString(), SupportLinks.supportUrl);
    });
  });
}
