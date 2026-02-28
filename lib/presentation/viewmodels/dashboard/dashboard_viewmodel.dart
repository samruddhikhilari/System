import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/repositories/dashboard_repository.dart';

class DashboardState {
  const DashboardState({
    this.isLoading = false,
    this.error,
    this.summary,
  });

  final bool isLoading;
  final String? error;
  final DashboardSummary? summary;

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    DashboardSummary? summary,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      summary: summary ?? this.summary,
    );
  }
}

class DashboardViewModel extends StateNotifier<DashboardState> {
  DashboardViewModel(this._repository) : super(const DashboardState());

  final DashboardRepository _repository;
  StreamSubscription<DashboardSummary>? _refreshSubscription;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final summary = await _repository.getDashboardSummary();
      state = state.copyWith(isLoading: false, summary: summary);
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    }
  }

  void startAutoRefresh() {
    _refreshSubscription?.cancel();
    _refreshSubscription = _repository.autoRefreshSummary().listen((summary) {
      state = state.copyWith(summary: summary, clearError: true);
    });
  }

  void stopAutoRefresh() {
    _refreshSubscription?.cancel();
    _refreshSubscription = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
      final repository = ref.watch(dashboardRepositoryProvider);
      final viewModel = DashboardViewModel(repository);
      ref.onDispose(viewModel.stopAutoRefresh);
      return viewModel;
    });
