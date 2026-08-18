class PlaceModel {
  const PlaceModel({
    required this.placeId,
    required this.displayName,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.googleMapsUri,
  });

  final String placeId;
  final String displayName;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? googleMapsUri;

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    return PlaceModel(
      placeId: (json['place_id'] ?? '') as String,
      displayName: (json['displayName'] ?? '') as String,
      formattedAddress: (json['formattedAddress'] ?? '') as String,
      latitude: (loc['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (loc['longitude'] as num?)?.toDouble() ?? 0,
      googleMapsUri: json['googleMapsUri'] as String?,
    );
  }
}
