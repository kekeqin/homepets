import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Central legal / support contact endpoints for App Store compliance.
class SupportLinks {
  SupportLinks._();

  static const String siteOrigin = 'https://pickstarpet.kkqin.com';
  static const String privacyUrl = '$siteOrigin/privacy.html';
  static const String termsUrl = '$siteOrigin/terms.html';
  static const String supportUrl = '$siteOrigin/support.html';
  static const String supportEmail = 'support@kkqin.com';

  /// Keep in sync with the About dialog until package_info is wired in.
  static const String appVersionLabel = '1.0.0';

  static Uri get privacyPageUri => Uri.parse(privacyUrl);
  static Uri get termsPageUri => Uri.parse(termsUrl);
  static Uri get supportPageUri => Uri.parse(supportUrl);

  static Uri supportMailtoUri({String appVersion = appVersionLabel}) {
    return mailtoUri(
      subject: '【拾星小宠】订阅/账号问题',
      body: [
        '问题描述：',
        '',
        '注册方式（手机号 / Apple）：',
        '设备：iOS',
        'App 版本：$appVersion',
      ].join('\n'),
    );
  }

  static Uri deleteAccountMailtoUri({String appVersion = appVersionLabel}) {
    return mailtoUri(
      subject: '申请删除账号与数据',
      body: [
        '请协助删除我的拾星小宠账号及相关家庭数据。',
        '',
        '注册方式（手机号 / Apple）：',
        '账号信息：',
        '设备：iOS',
        'App 版本：$appVersion',
        '',
        '我已知悉删除后数据通常无法恢复。',
      ].join('\n'),
    );
  }

  static Uri mailtoUri({required String subject, required String body}) {
    final query = [
      'subject=${Uri.encodeComponent(subject)}',
      'body=${Uri.encodeComponent(body)}',
    ].join('&');
    return Uri.parse('mailto:$supportEmail?$query');
  }

  static Future<void> openPrivacy(BuildContext context) {
    return openWebPage(context, privacyPageUri);
  }

  static Future<void> openTerms(BuildContext context) {
    return openWebPage(context, termsPageUri);
  }

  static Future<void> openSupportPage(BuildContext context) {
    return openWebPage(context, supportPageUri);
  }

  static Future<void> openSupportEmail(BuildContext context) {
    return openMailto(context, supportMailtoUri());
  }

  static Future<void> openDeleteAccountEmail(BuildContext context) {
    return openMailto(context, deleteAccountMailtoUri());
  }

  static Future<void> openWebPage(BuildContext context, Uri uri) {
    return open(
      context,
      uri,
      mode: LaunchMode.inAppBrowserView,
      failureMessage: '暂时无法打开页面，请稍后重试',
    );
  }

  static Future<void> openMailto(BuildContext context, Uri uri) {
    return open(
      context,
      uri,
      mode: LaunchMode.externalApplication,
      failureMessage: '暂时无法打开邮件应用，请手动发送至 $supportEmail',
    );
  }

  static Future<void> open(
    BuildContext context,
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
    String failureMessage = '暂时无法打开，请稍后重试',
  }) async {
    final opened = await launchUrl(uri, mode: mode);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}
