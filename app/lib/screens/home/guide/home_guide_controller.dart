import 'package:shared_preferences/shared_preferences.dart';

enum HomeGuideStep {
  taskSticker,
  familyFrame,
  petArea,
  done;

  String get storageValue => switch (this) {
    HomeGuideStep.taskSticker => 'task_sticker',
    HomeGuideStep.familyFrame => 'family_frame',
    HomeGuideStep.petArea => 'pet_area',
    HomeGuideStep.done => 'done',
  };

  static HomeGuideStep fromStorageValue(String? value) {
    return switch (value) {
      'task_sticker' => HomeGuideStep.taskSticker,
      'family_frame' => HomeGuideStep.familyFrame,
      'pet_area' => HomeGuideStep.petArea,
      'done' => HomeGuideStep.done,
      _ => HomeGuideStep.taskSticker,
    };
  }
}

class HomeGuideProgress {
  const HomeGuideProgress({
    required this.currentStep,
    this.completed = false,
    this.skipped = false,
  });

  final HomeGuideStep currentStep;
  final bool completed;
  final bool skipped;

  bool get shouldShow =>
      !completed && !skipped && currentStep != HomeGuideStep.done;
}

class HomeGuideSnapshot {
  const HomeGuideSnapshot({
    required this.hasFamilyMembers,
    required this.hasActiveTasks,
    required this.hasCurrentUserPet,
    required this.hasMembersMissingPets,
  });

  final bool hasFamilyMembers;
  final bool hasActiveTasks;
  final bool hasCurrentUserPet;
  final bool hasMembersMissingPets;

  bool get hasFamilySetupGap =>
      !hasFamilyMembers || !hasCurrentUserPet || hasMembersMissingPets;

  bool get hasFinishedFirstDaySetup =>
      hasFamilyMembers &&
      hasActiveTasks &&
      hasCurrentUserPet &&
      !hasMembersMissingPets;
}

class HomeGuideController {
  HomeGuideController({
    required SharedPreferences preferences,
    required String scopeId,
    this.guideVersion = 1,
  }) : _preferences = preferences,
       _scopeId = scopeId;

  final SharedPreferences _preferences;
  final String _scopeId;
  final int guideVersion;

  String get _safeScopeId {
    final safe = _scopeId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safe.isEmpty ? 'anonymous' : safe;
  }

  String get _prefix => 'home_guide_v${guideVersion}_$_safeScopeId';
  String get _completedKey => '${_prefix}_completed';
  String get _skippedKey => '${_prefix}_skipped';
  String get _currentStepKey => '${_prefix}_current_step';

  HomeGuideProgress readProgress(HomeGuideSnapshot snapshot) {
    final completed = _preferences.getBool(_completedKey) ?? false;
    final skipped = _preferences.getBool(_skippedKey) ?? false;
    if (completed || skipped) {
      return HomeGuideProgress(
        currentStep: HomeGuideStep.done,
        completed: completed,
        skipped: skipped,
      );
    }

    final storedStepValue = _preferences.getString(_currentStepKey);
    if (storedStepValue == null && snapshot.hasFinishedFirstDaySetup) {
      return const HomeGuideProgress(
        currentStep: HomeGuideStep.done,
        completed: true,
      );
    }

    final storedStep = HomeGuideStep.fromStorageValue(storedStepValue);
    final currentStep = _firstAvailableStep(storedStep, snapshot);
    return HomeGuideProgress(currentStep: currentStep);
  }

  Future<HomeGuideProgress> advance(
    HomeGuideStep completedStep,
    HomeGuideSnapshot snapshot,
  ) async {
    final nextStep = _firstAvailableStepAfterCompletion(
      completedStep,
      _nextStepAfter(completedStep),
      snapshot,
    );
    if (nextStep == HomeGuideStep.done) {
      await markCompleted();
      return const HomeGuideProgress(
        currentStep: HomeGuideStep.done,
        completed: true,
      );
    }

    await _preferences.setString(_currentStepKey, nextStep.storageValue);
    return HomeGuideProgress(currentStep: nextStep);
  }

  HomeGuideStep _firstAvailableStepAfterCompletion(
    HomeGuideStep completedStep,
    HomeGuideStep preferred,
    HomeGuideSnapshot snapshot,
  ) {
    if (completedStep == HomeGuideStep.familyFrame) {
      if (snapshot.hasFamilySetupGap) {
        return HomeGuideStep.familyFrame;
      }
      if (!snapshot.hasActiveTasks) {
        return HomeGuideStep.taskSticker;
      }
      return _firstAvailableStep(preferred, snapshot);
    }

    if (snapshot.hasFamilySetupGap) {
      return HomeGuideStep.familyFrame;
    }

    var step = preferred;
    while (step != HomeGuideStep.done && _shouldSkipStep(step, snapshot)) {
      step = _nextStepAfter(step);
    }
    return step;
  }

  Future<HomeGuideProgress> skip() async {
    await _preferences.setBool(_skippedKey, true);
    await _preferences.setString(
      _currentStepKey,
      HomeGuideStep.done.storageValue,
    );
    return const HomeGuideProgress(
      currentStep: HomeGuideStep.done,
      skipped: true,
    );
  }

  Future<void> markCompleted() async {
    await _preferences.setBool(_completedKey, true);
    await _preferences.setString(
      _currentStepKey,
      HomeGuideStep.done.storageValue,
    );
  }

  Future<void> reset() async {
    await _preferences.remove(_completedKey);
    await _preferences.remove(_skippedKey);
    await _preferences.remove(_currentStepKey);
  }

  HomeGuideStep _firstAvailableStep(
    HomeGuideStep preferred,
    HomeGuideSnapshot snapshot,
  ) {
    if (snapshot.hasFamilySetupGap) {
      return HomeGuideStep.familyFrame;
    }

    if (!snapshot.hasActiveTasks &&
        (preferred == HomeGuideStep.taskSticker ||
            preferred == HomeGuideStep.familyFrame)) {
      return HomeGuideStep.taskSticker;
    }

    var step = preferred;
    while (step != HomeGuideStep.done && _shouldSkipStep(step, snapshot)) {
      step = _nextStepAfter(step);
    }
    return step;
  }

  bool _shouldSkipStep(HomeGuideStep step, HomeGuideSnapshot snapshot) {
    return switch (step) {
      HomeGuideStep.taskSticker => snapshot.hasActiveTasks,
      HomeGuideStep.familyFrame => !snapshot.hasFamilySetupGap,
      HomeGuideStep.petArea => false,
      HomeGuideStep.done => true,
    };
  }

  HomeGuideStep _nextStepAfter(HomeGuideStep step) {
    return switch (step) {
      HomeGuideStep.taskSticker => HomeGuideStep.familyFrame,
      HomeGuideStep.familyFrame => HomeGuideStep.petArea,
      HomeGuideStep.petArea => HomeGuideStep.done,
      HomeGuideStep.done => HomeGuideStep.done,
    };
  }
}
