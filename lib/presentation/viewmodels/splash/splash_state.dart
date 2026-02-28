import 'package:freezed_annotation/freezed_annotation.dart';

part 'splash_state.freezed.dart';

@freezed
class SplashState with _$SplashState {
  const factory SplashState({
    @Default(true) bool isLoading,
    @Default(false) bool isAuthenticated,
    @Default(false) bool requiresUpdate,
    String? error,
  }) = _SplashState;
}
