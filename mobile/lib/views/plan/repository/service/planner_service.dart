import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:navgo_mobile/core/constants/api_constants.dart';
import 'package:navgo_mobile/core/models/place_model.dart';
import 'package:navgo_mobile/data/auth_token_store.dart';
import 'package:navgo_mobile/flavors/app_flavor.dart';
import 'package:navgo_mobile/views/plan/models/plan_suggestion.dart';

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
                connectTimeout: const Duration(seconds: 60),
                receiveTimeout: const Duration(seconds: 180),
                sendTimeout: const Duration(seconds: 60),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  /// Handshake → login/register → bind. Prod forbids hardcoded demo unless
  /// `--dart-define=NAVGO_ALLOW_DEMO=true` (dev flavor default allows demo).
  Future<String> ensureSession() async {
    final cached = await AuthTokenStore.readToken();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    const defineEmail = String.fromEnvironment('NAVGO_USER_EMAIL');
    const definePassword = String.fromEnvironment('NAVGO_USER_PASSWORD');
    const allowDemoDefine = bool.fromEnvironment('NAVGO_ALLOW_DEMO', defaultValue: false);

    final allowDemo = allowDemoDefine || currentAppFlavor == AppFlavor.dev || kDebugMode;
    var email = defineEmail;
    var password = definePassword;
    if (email.isEmpty || password.isEmpty) {
      if (!allowDemo) {
        throw StateError(
          'Production auth required: pass --dart-define=NAVGO_USER_EMAIL=... '
          'and NAVGO_USER_PASSWORD=..., or complete a prior bind session.',
        );
      }
      email = 'demo@navgo.local';
      password = 'NavGoDemo1!';
    }

    final hs = await _dio.post('/api/v1/auth/handshake', data: {});
    final handshakeId = hs.data['handshake_id'] as String;
    final barrier = hs.data['barrier'] as String;
    final channelPath = hs.data['channel_path'] as String?;

    Future<Response<dynamic>> login() {
      return _dio.post(
        '/api/v1/auth/login',
        data: {
          'email': email,
          'password': password,
          'handshake_id': handshakeId,
        },
      );
    }

    Response<dynamic> loginRes;
    try {
      loginRes = await login();
    } catch (_) {
      await _dio.post(
        '/api/v1/auth/register',
        data: {
          'email': email,
          'password': password,
          'first_name': 'NavGo',
          'last_name': allowDemo ? 'Demo' : 'User',
          'handshake_id': handshakeId,
        },
      );
      loginRes = await login();
    }

    final userToken = loginRes.data['token'] as String;
    final bind = await _dio.post(
      '/api/v1/auth/bind',
      data: {
        'handshake_id': handshakeId,
        'barrier': barrier,
      },
      options: Options(headers: {'Authorization': 'Bearer $userToken'}),
    );
    final blended = bind.data['token'] as String;
    await AuthTokenStore.save(
      blendedToken: blended,
      channelPath: channelPath ?? (bind.data['channel_path'] as String? ?? ''),
      barrier: barrier,
      handshakeId: handshakeId,
    );
    return blended;
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
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 180),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      return PlanIntent.fromJson(res.data as Map<String, dynamic>);
    } on DioException {
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
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 180),
          sendTimeout: const Duration(seconds: 60),
        ),
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

  /// Location-aware quick-start cards. Null when LLM is unavailable.
  Future<List<PlanSuggestion>?> suggestDayCards({
    required String token,
    required String area,
    String locale = 'tr',
    String tempo = '',
    List<String> interests = const [],
    String groupType = '',
    String transportMode = '',
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/llm/suggest-day-cards',
        data: {
          'area': area,
          'locale': locale,
          'tempo': tempo,
          'interests': interests,
          'group_type': groupType,
          'transport_mode': transportMode,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      final raw = (res.data['cards'] as List<dynamic>? ?? []);
      final cards = <PlanSuggestion>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final card = PlanSuggestion.fromApi(Map<String, dynamic>.from(item));
        if (card.title.isEmpty || card.query.isEmpty) continue;
        cards.add(card);
      }
      if (cards.length < 2) return null;
      return cards.take(4).toList();
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
