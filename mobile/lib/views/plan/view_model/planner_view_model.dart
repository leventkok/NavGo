import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navgo_mobile/core/enums/view_status.dart';
import 'package:navgo_mobile/core/models/place_model.dart';
import 'package:navgo_mobile/views/plan/repository/service/planner_service.dart';

part 'planner_event.dart';
part 'planner_state.dart';

class PlannerViewModel extends Bloc<PlannerEvent, PlannerState> {
  PlannerViewModel({PlannerService? service})
      : _service = service ?? PlannerService(),
        super(const PlannerState()) {
    on<PlannerPlanDayEvent>(_onPlanDay);
    on<PlannerResetEvent>(_onReset);
  }

  final PlannerService _service;

  FutureOr<void> _onReset(
    PlannerResetEvent event,
    Emitter<PlannerState> emit,
  ) {
    emit(
      state.copyWith(
        status: ViewStatus.initial,
        phase: PlannerPhase.home,
        planTitle: '',
        area: '',
        query: '',
        stops: const [],
        clearRoute: true,
        clearError: true,
        statusMessage: '',
      ),
    );
  }

  FutureOr<void> _onPlanDay(
    PlannerPlanDayEvent event,
    Emitter<PlannerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ViewStatus.loading,
        phase: PlannerPhase.working,
        planTitle: event.title,
        area: event.area,
        query: event.query,
        clearError: true,
        statusMessage: 'Oturum açılıyor…',
      ),
    );

    try {
      final token = await _service.ensureDemoAuth();
      emit(state.copyWith(statusMessage: 'Mekanlar aranıyor…'));

      final places = await _service.searchPlaces(
        token: token,
        area: event.area,
        query: event.query,
        maxResults: event.maxResults,
      );
      if (places.length < 2) {
        throw Exception('Yeterli grounded mekan yok');
      }

      emit(
        state.copyWith(
          stops: places,
          statusMessage: 'Rota oluşturuluyor…',
        ),
      );

      final route = await _service.buildRoute(
        token: token,
        placeIds: places.map((p) => p.placeId).toList(),
        travelMode: event.travelMode,
      );

      emit(
        state.copyWith(
          status: ViewStatus.success,
          phase: PlannerPhase.done,
          route: route,
          statusMessage: 'Plan hazır',
        ),
      );
    } catch (e) {
      var message = e.toString().replaceFirst('Exception: ', '');
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          message = e.message!;
        }
      }
      emit(
        state.copyWith(
          status: ViewStatus.failure,
          phase: PlannerPhase.home,
          errorMessage: message,
          statusMessage: '',
        ),
      );
    }
  }
}
