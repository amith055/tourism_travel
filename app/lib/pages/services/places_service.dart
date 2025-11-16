import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place.dart';

class PlacesService {
  // ⚠️ API keys (replace with your restricted keys)
  final String mapsApiKey = 'AIzaSyB4etaq4Xmric5Og4mINDcCgl3C_yqHL5Q';
  final String geminiApiKey = 'AIzaSyAtrQCcHNQ1cDdkDna14Qpzoeaf4POvw0g';

  /// Directions API -> returns distanceKm and decoded polyline (List<LatLng>)
  Future<Map<String, dynamic>> getDirections(
      double startLat, double startLng, double endLat, double endLng) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng'
        '&destination=$endLat,$endLng&mode=driving&key=$mapsApiKey');

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Directions request failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    if (data['routes'] == null || (data['routes'] as List).isEmpty) {
      throw Exception('No routes found');
    }

    final route = data['routes'][0];
    final leg = route['legs'][0];
    final distanceMeters = (leg['distance']['value'] as num).toDouble();

    final encodedPolyline = route['overview_polyline']?['points'] ?? '';
    final polylinePoints = encodedPolyline.isEmpty
        ? <LatLng>[]
        : _decodePolyline(encodedPolyline);

    return {
      'distanceKm': distanceMeters / 1000.0,
      'polyline': polylinePoints,
      'startAddress': leg['start_address'],
      'endAddress': leg['end_address'],
      'durationText': leg['duration']?['text'],
      'durationValue': leg['duration']?['value'],
    };
  }

  /// Geocode address -> LatLng
  Future<LatLng?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;
    final encoded = Uri.encodeComponent(address);
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&key=$mapsApiKey');

    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception('Geocoding failed');
    final data = jsonDecode(res.body);
    if (data['results'] == null || (data['results'] as List).isEmpty) return null;

    final loc = data['results'][0]['geometry']['location'];
    return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
  }

  /// Public: fetch all nearby places and the Gemini top-10 shortlist
  Future<Map<String, List<PlaceModel>>> nearbyWithAI(
      double startLat, double startLng, double endLat, double endLng,
      {String category = 'tourism'}) async {
    final allNearby =
        await _fetchNearbyPlaces(startLat, startLng, endLat, endLng, category);
    final geminiTop10 = await _getGeminiTop10(allNearby);
    return {'allNearby': allNearby, 'geminiTop10': geminiTop10};
  }

  /// Fetch nearby places along route (waypoints sampling + multi-category support)
  Future<List<PlaceModel>> _fetchNearbyPlaces(
      double startLat, double startLng, double endLat, double endLng,
      String category) async {
    final points =
        _intermediatePoints(LatLng(startLat, startLng), LatLng(endLat, endLng), 6);

    // 🔹 Support multi-category input (comma-separated from UI)
    final categoryList =
        category.split(',').map((c) => c.trim().toLowerCase()).toList();

    final types = <String>[];

    if (categoryList.contains('temples')) {
      types.addAll(['hindu_temple', 'church', 'mosque', 'place_of_worship']);
    }
    if (categoryList.contains('historical')) {
      types.addAll(['museum', 'art_gallery', 'historical_landmark']);
    }
    if (categoryList.contains('tourism')) {
      types.addAll(['tourist_attraction', 'amusement_park', 'park', 'zoo']);
    }

    // Default fallback
    if (types.isEmpty) {
      types.addAll(['tourist_attraction', 'park']);
    }

    final all = <PlaceModel>[];

    for (final p in points) {
      for (final t in types) {
        final url =
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${p.latitude},${p.longitude}&radius=2500&type=$t&key=$mapsApiKey';
        final res = await http.get(Uri.parse(url));
        if (res.statusCode != 200) continue;

        final data = jsonDecode(res.body);
        final results = (data['results'] ?? []) as List;
        for (final r in results) {
          try {
            final place = PlaceModel.fromJson(r);
            if (place.rating >= 4.0 &&
                !all.any((existing) => existing.placeId == place.placeId)) {
              all.add(place);
            }
          } catch (_) {
            // ignore malformed entries
          }
        }
      }
    }

    all.sort((a, b) => b.rating.compareTo(a.rating));
    return all;
  }

  /// Ask Gemini to pick top 10 — returns matched PlaceModel objects
 Future<List<PlaceModel>> _getGeminiTop10(List<PlaceModel> places) async {
  if (places.isEmpty) return [];

  // Prepare concise list for Gemini input
  final inputList = places
      .map((p) => {'name': p.name, 'rating': p.rating, 'address': p.address})
      .toList();

  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiApiKey');

  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {
            "text":
                "You are a travel recommendation engine. Given this list of places (with name, rating, and address): $inputList\n"
                "Select the **top 20 most interesting, popular, and highly rated** places ensuring a mix of historical, cultural, and natural attractions.\n"
                "Return only a JSON array of the chosen place names. Example:\n"
                "[\"Name1\", \"Name2\", \"Name3\", ...]"
          }
        ]
      }
    ]
  });

  final res = await http.post(url,
      headers: {'Content-Type': 'application/json'}, body: body);

  print(res.body);
  if (res.statusCode != 200) {
    return [];
  }

  final data = jsonDecode(res.body);
  final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
  if (text == null) return [];

  List<dynamic> topNames;
  try {
    topNames = jsonDecode(text);
  } catch (e) {
    // Clean non-JSON characters if Gemini responds with mixed text
    final cleaned = text
        .replaceAll(RegExp(r'[^0-9A-Za-z\s\[\]\",.-]'), '')
        .replaceAll(RegExp(r'json', caseSensitive: false), '')
        .trim();
    try {
      topNames = jsonDecode(cleaned);
    } catch (_) {
      return [];
    }
  }

  // Convert to lowercase for case-insensitive match
  final lowerNames = topNames.map((n) => n.toString().toLowerCase()).toList();

  // Match Gemini output with local PlaceModel list
  final matched = places
      .where((p) =>
          lowerNames.any((name) => p.name.toLowerCase().contains(name)))
      .take(20)
      .toList();

  // If fewer than 20, fill with remaining high-rated ones
  if (matched.length < 20 && places.isNotEmpty) {
    for (final p in places) {
      if (matched.length >= 20) break;
      if (!matched.contains(p)) matched.add(p);
    }
  }

  return matched;
}

  /// Helpers
  List<LatLng> _intermediatePoints(LatLng start, LatLng end, int count) {
    final points = <LatLng>[];
    for (int i = 0; i <= count; i++) {
      final lat = start.latitude + (end.latitude - start.latitude) * (i / count);
      final lng = start.longitude + (end.longitude - start.longitude) * (i / count);
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
