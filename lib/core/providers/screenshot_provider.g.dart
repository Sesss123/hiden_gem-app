// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScreenshotNotifier)
final screenshotProvider = ScreenshotNotifierProvider._();

final class ScreenshotNotifierProvider
    extends $NotifierProvider<ScreenshotNotifier, bool> {
  ScreenshotNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'screenshotProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$screenshotNotifierHash();

  @$internal
  @override
  ScreenshotNotifier create() => ScreenshotNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$screenshotNotifierHash() =>
    r'463a89d5dd763c6a26c0cb6c788c8bd7d319be4d';

abstract class _$ScreenshotNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
