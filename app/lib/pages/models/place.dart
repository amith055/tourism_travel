class PlaceModel {
  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final double rating;
  final String address;
  final bool? openNow;
  final String icon;

  PlaceModel({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.address,
    this.openNow,
    required this.icon,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']?['location'];
    return PlaceModel(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      lat: (geometry?['lat'] ?? 0).toDouble(),
      lng: (geometry?['lng'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      address: json['vicinity'] ?? '',
      openNow: json['opening_hours']?['open_now'],
      icon: json['icon'] ?? '',
    );
  }
}
