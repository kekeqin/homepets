import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/core/api_client.dart';
import 'package:homepets/core/auth_session_bus.dart';
import 'package:homepets/models/pet.dart';
import 'package:homepets/providers/auth_provider.dart';
import 'package:homepets/screens/pet/widgets/pet_detail_view.dart';

void main() {
  testWidgets('shows pet owner name instead of feed count', (tester) async {
    final pet = Pet(
      id: 10,
      name: '小白兔',
      petType: 'rabbit',
      petForm: 'pet',
      level: 1,
      experience: 0,
      ownerId: 3,
      ownerNickname: '小宝',
      familyId: 99,
      levelThreshold: 100,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_TestApiClient())],
        child: MaterialApp(
          home: Scaffold(body: PetDetailView(pet: pet, embedded: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('所属人员'), findsOneWidget);
    expect(find.text('小宝'), findsOneWidget);
    expect(find.text('喂养次数'), findsNothing);
  });
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
