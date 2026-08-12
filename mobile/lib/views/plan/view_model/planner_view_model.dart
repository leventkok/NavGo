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
    final userPrompt = event.prompt.trim().isNotEmpty
        ? event.prompt.trim()
        : [
            if (event.title.trim().isNotEmpty) event.title.trim(),
            if (event.area.trim().isNotEmpty) event.area.trim(),
            if (event.query.trim().isNotEmpty) event.query.trim(),
          ].join('. ');

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

      var area = event.area.trim();
      var query = event.query.trim();
      var maxResults = event.maxResults;

      emit(state.copyWith(statusMessage: 'LLM intent çıkarılıyor…'));
      final intent = await _service.parseIntent(
        token: token,
        prompt: userPrompt,
        defaultArea: area,
        tempo: event.tempo,
        interests: event.interests,
        groupType: event.groupType,
        transportMode: event.transportMode,
      );
      if (intent != null) {
        if (area.isEmpty && intent.area.trim().isNotEmpty) {
          area = intent.area.trim();
        }
        if (intent.query.trim().isNotEmpty) {
          query = intent.query.trim();
        }
        maxResults = intent.maxStops.clamp(3, 7);
        emit(
          state.copyWith(
            area: area,
            query: query,
            statusMessage: 'Mekanlar aranıyor…',
          ),
        );
      } else {
        emit(
          state.copyWith(
            statusMessage: 'Şablon ile mekanlar aranıyor…',
          ),
        );
      }

      if (area.isEmpty) {
        throw Exception('Destinasyon gerekli');
      }
      if (query.isEmpty) {
        query = area;
      }

      final places = await _service.searchPlaces(
        token: token,
        area: area,
        query: query,
        maxResults: maxResults,
      );
      if (places.length < 2) {
        throw Exception('Yeterli grounded mekan yok');
      }

      emit(
        state.copyWith(
          stops: places,
          statusMessage: 'LLM durak seçiyor…',
        ),
      );

      var selected = places;
      final indices = await _service.pickStops(
        token: token,
        prompt: userPrompt,
        places: places,
        maxStops: maxResults.clamp(2, places.length),
      );
      if (indices != null && indices.length >= 2) {
        selected = [
          for (final i in indices) places[i],
        ];
      } else {
        selected = places.take(maxResults.clamp(2, places.length)).toList();
        emit(state.copyWith(statusMessage: 'Rota oluşturuluyor…'));
      }

      emit(
        state.copyWith(
          stops: selected,
          statusMessage: 'Rota oluşturuluyor…',
        ),
      );

      final route = await _service.buildRoute(
        token: token,
        placeIds: selected.map((p) => p.placeId).toList(),
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
