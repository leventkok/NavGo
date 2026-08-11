import 'package:dio/dio.dart';
import 'package:navgo_mobile/core/constants/api_constants.dart';
import 'package:navgo_mobile/core/models/place_model.dart';

class PlannerService {
  PlannerService({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? defaultApiBaseUrl(),
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 45),
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
  }) async {
    final res = await _dio.post(
      '/api/v1/routes/build',
      data: {
        'place_ids': placeIds,
        'travel_mode': 'WALK',
        'optimize_waypoint_order': true,
        'language': 'tr',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return RouteModel.fromJson(res.data as Map<String, dynamic>);
  }
}
