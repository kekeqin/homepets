import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'providers/revenue_cat_provider.dart';
import 'providers/subscription_provider.dart';

void main() {
  runApp(const ProviderScope(child: PickStarPetApp()));
}

class PickStarPetApp extends ConsumerWidget {
  const PickStarPetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(revenueCatProvider.select((state) => state.isInitialized));
    ref.watch(subscriptionProvider.select((state) => state.isInitialized));

    return MaterialApp.router(
      title: '家庭宠物',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        fontFamily: 'PickStarPetFont',
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
