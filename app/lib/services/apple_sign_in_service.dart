import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInCredential {
  const AppleSignInCredential({
    required this.identityToken,
    required this.authorizationCode,
    required this.nonce,
    this.fullName,
  });

  final String identityToken;
  final String authorizationCode;
  final String nonce;
  final String? fullName;
}

class AppleSignInCanceledException implements Exception {}

class AppleSignInFailure implements Exception {
  const AppleSignInFailure(this.message);

  final String message;
}

class AppleSignInService {
  Future<bool> isAvailable() async {
    if (!_supportsNativeAppleSignIn) {
      return false;
    }
    return SignInWithApple.isAvailable();
  }

  Future<AppleSignInCredential> signIn() async {
    final nonce = generateNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const AppleSignInFailure('Missing Apple identity token');
      }

      return AppleSignInCredential(
        identityToken: identityToken,
        authorizationCode: credential.authorizationCode,
        nonce: nonce,
        fullName: _fullName(credential),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw AppleSignInCanceledException();
      }
      throw AppleSignInFailure(error.message);
    } on SignInWithAppleException catch (error) {
      throw AppleSignInFailure(error.toString());
    }
  }

  bool get _supportsNativeAppleSignIn {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  String? _fullName(AuthorizationCredentialAppleID credential) {
    final givenName = credential.givenName?.trim();
    final familyName = credential.familyName?.trim();
    final hasGiven = givenName != null && givenName.isNotEmpty;
    final hasFamily = familyName != null && familyName.isNotEmpty;

    if (!hasGiven && !hasFamily) {
      return null;
    }
    if (hasGiven && hasFamily) {
      // Prefer Chinese-style 姓名 when either part contains CJK characters.
      final looksChinese =
          _containsCjk(givenName) || _containsCjk(familyName);
      return looksChinese ? '$familyName$givenName' : '$givenName $familyName';
    }
    return hasGiven ? givenName : familyName;
  }

  bool _containsCjk(String value) {
    return RegExp(r'[\u3400-\u9FFF]').hasMatch(value);
  }
}
