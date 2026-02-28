import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'splash_state.dart';

/// Splash ViewModel
class SplashViewModel extends StateNotifier<SplashState> {
  SplashViewModel() : super(const SplashState());
  
  /// Check app initialization
  Future<void> initialize() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Simulate initialization tasks
      await Future.delayed(const Duration(seconds: 2));
      
      // TODO: Check JWT token validity
      // TODO: Check minimum app version
      // TODO: Pre-warm HTTP client
      
      // For now, navigate to login (will add proper auth check later)
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Splash ViewModel Provider
final splashViewModelProvider =
    StateNotifierProvider<SplashViewModel, SplashState>((ref) {
  return SplashViewModel();
});
