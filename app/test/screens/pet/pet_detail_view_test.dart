import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/core/api_client.dart';
import 'package:homepets/core/auth_session_bus.dart';
import 'package:homepets/core/ui/adaptive_design_layout.dart';
import 'package:homepets/models/pet.dart';
import 'package:homepets/providers/auth_provider.dart';
import 'package:homepets/screens/pet/widgets/pet_detail_view.dart';

void main() {
  testWidgets('shows pet owner name instead of feed count', (tester) async {
    final pet = _testPet(ownerNickname: 'OwnerNameUnique');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_TestApiClient())],
        child: MaterialApp(
          home: Scaffold(body: PetDetailView(pet: pet, embedded: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OwnerNameUnique'), findsOneWidget);
  });

  testWidgets('fits full profile card inside bounded modal height', (
    tester,
  ) async {
    final pet = _testPet(level: 4, experience: 510, levelThreshold: 1000);
    const hostKey = Key('pet_detail_bounded_host');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_TestApiClient())],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                key: hostKey,
                width: 430,
                height: 700,
                child: PetDetailView(pet: pet, embedded: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hostRect = tester.getRect(find.byKey(hostKey));
    final cardRect = tester.getRect(find.byKey(PetDetailView.profileCardKey));

    expect(cardRect.left, greaterThanOrEqualTo(hostRect.left - 0.01));
    expect(cardRect.top, greaterThanOrEqualTo(hostRect.top - 0.01));
    expect(cardRect.right, lessThanOrEqualTo(hostRect.right + 0.01));
    expect(cardRect.bottom, lessThanOrEqualTo(hostRect.bottom + 0.01));
  });

  testWidgets('uses shared adaptive design coordinates across viewports', (
    tester,
  ) async {
    final pet = _testPet(level: 4, experience: 510, levelThreshold: 1000);

    Future<void> expectLayoutAt(Size viewportSize) async {
      tester.view.physicalSize = viewportSize;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(_TestApiClient())],
          child: MaterialApp(
            home: Scaffold(body: PetDetailView(pet: pet, embedded: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final geometry = AdaptiveDesignLayoutGeometry.resolve(
        viewportSize: viewportSize,
        designSize: PetDetailDesignLayout.designSize,
        minimumInsets: PetDetailDesignLayout.embeddedMinimumInsets,
      );

      expect(
        tester.getRect(find.byKey(PetDetailView.profileCardKey)),
        _closeToRect(geometry.designRect),
      );
      expect(
        tester.getRect(find.byKey(PetDetailView.nameBannerKey)),
        _closeToRect(
          geometry.toScreenRect(PetDetailDesignLayout.nameBannerRect),
        ),
      );
      expect(
        tester.getRect(find.byKey(PetDetailView.portraitFrameKey)),
        _closeToRect(
          geometry.toScreenRect(PetDetailDesignLayout.portraitFrameRect),
        ),
      );
      expect(
        tester.getRect(find.byKey(PetDetailView.recentTasksPanelKey)),
        _closeToRect(
          geometry.toScreenRect(PetDetailDesignLayout.recentTasksPanelRect),
        ),
      );
    }

    await expectLayoutAt(const Size(390, 844));
    await tester.pumpWidget(const SizedBox.shrink());
    await expectLayoutAt(const Size(430, 932));

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

Matcher _closeToRect(Rect expected) {
  return isA<Rect>()
      .having((rect) => rect.left, 'left', closeTo(expected.left, 0.01))
      .having((rect) => rect.top, 'top', closeTo(expected.top, 0.01))
      .having((rect) => rect.width, 'width', closeTo(expected.width, 0.01))
      .having((rect) => rect.height, 'height', closeTo(expected.height, 0.01));
}

Pet _testPet({
  int level = 1,
  int experience = 0,
  int? levelThreshold = 100,
  String ownerNickname = 'Child',
}) {
  return Pet(
    id: 10,
    name: 'Rabbit',
    petType: 'rabbit',
    petForm: 'pet',
    level: level,
    experience: experience,
    ownerId: 3,
    ownerNickname: ownerNickname,
    familyId: 99,
    levelThreshold: levelThreshold,
  );
}

class _TestApiClient extends ApiClient {
  _TestApiClient() : super(AuthSessionBus());

  final Dio _dio = Dio()..httpClientAdapter = _EmptyHistoryAdapter();

  @override
  Dio get dio => _dio;
}

class _EmptyHistoryAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '[]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
