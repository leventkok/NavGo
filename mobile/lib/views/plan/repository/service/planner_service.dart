import 'package:dio/dio.dart';
import 'package:navgo_mobile/core/constants/api_constants.dart';
import 'package:navgo_mobile/core/models/place_model.dart';

class PlanIntent {
  const PlanIntent({
    required this.area,
    required this.query,
    required this.durationLabel,
    required this.maxStops,
  });

  final String area;
  final String query;
  final String durationLabel;
  final int maxStops;

  factory PlanIntent.fromJson(Map<String, dynamic> json) {
    return PlanIntent(
      area: (json['area'] ?? '') as String,
      query: (json['query'] ?? '') as String,
      durationLabel: (json['duration_label'] ?? '') as String,
      maxStops: (json['max_stops'] as num?)?.toInt() ?? 5,
    );
  }
}

class PlannerService {
  PlannerService({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? defaultApiBaseUrl(),
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 120),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<String> ensureDemoAuth() async {
    const email = 'demo@navgo.local';
    const password = 'NavGoDemo1!';
    try {
      final res = await _dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      return res.data['token'] as String;
    } catch (_) {
      await _dio.post(
        '/api/v1/auth/register',
        data: {
          'email': email,
          'password': password,
          'first_name': 'NavGo',
          'last_name': 'Demo',
        },
      );
      final res = await _dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      return res.data['token'] as String;
    }
  }

  /// Returns null when LLM is unavailable (503) or request fails.
  Future<PlanIntent?> parseIntent({
    required String token,
    required String prompt,
    String defaultArea = '',
    String tempo = '',
    List<String> interests = const [],
    String groupType = '',
    String transportMode = '',
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/llm/parse-intent',
        data: {
          'prompt': prompt,
          'default_area': defaultArea,
          'tempo': tempo,
          'interests': interests,
          'group_type': groupType,
          'transport_mode': transportMode,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return PlanIntent.fromJson(res.data as Map<String, dynamic>);
    } on DioException {
      // LLM optional — template / PreferenceQueryBuilder path continues.
      return null;
    }
  }

  /// Returns null when LLM is unavailable; otherwise zero-based indices.
  Future<List<int>?> pickStops({
    required String token,
    required String prompt,
    required List<PlaceModel> places,
    int maxStops = 5,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/llm/pick-stops',
        data: {
          'prompt': prompt,
          'max_stops': maxStops,
          'places': [
            for (final p in places)
              {
                'display_name': p.displayName,
                'formatted_address': p.formattedAddress,
              },
          ],
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final raw = (res.data['indices'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .where((i) => i >= 0 && i < places.length)
          .toList();
      return raw;
    } on DioException {
      return null;
    }
  }

  Future<List<PlaceModel>> searchPlaces({
    required String token,
    required String area,
    required String query,
    int maxResults = 5,
  }) async {
    final res = await _dio.post(
      '/api/v1/places/search',
      data: {
        'query': query.isEmpty ? area : query,
        'area': area,
        'language': 'tr',
        'max_results': maxResults,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final list = (res.data['places'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PlaceModel.fromJson)
        .toList();
    return list;
  }

  Future<RouteModel> buildRoute({
    required String token,
    required List<String> placeIds,
    String travelMode = 'WALK',
  }) async {
    final res = await _dio.post(
      '/api/v1/routes/build',
      data: {
        'place_ids': placeIds,
        'travel_mode': travelMode,
        'optimize_waypoint_order': true,
        'language': 'tr',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return RouteModel.fromJson(res.data as Map<String, dynamic>);
  }
}
