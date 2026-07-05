// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppModeNotifier)
final appModeProvider = AppModeNotifierProvider._();

final class AppModeNotifierProvider
    extends $NotifierProvider<AppModeNotifier, ThemeMode> {
  AppModeNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appModeProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appModeNotifierHash();

  @$internal
  @override
  AppModeNotifier create() => AppModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$appModeNotifierHash() => r'89d341eb01c304137b96a60f3dd6f5636bb63d95';

abstract class _$AppModeNotifier extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ThemeMode, ThemeMode>, ThemeMode, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
