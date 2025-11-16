import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectionsService {
  final String apiKey = "AIzaSyB4etaq4Xmric5Og4mINDcCgl3C_yqHL5Q";

  Future<Map<String, dynamic>> getDirections(
    String origin,
    String destination,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey',
    );
    final res = await http.get(url);
    return json.decode(res.body);
  }

  Future<double> distanceBetween(String origin, String destination) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$origin&destinations=$destination&key=$apiKey',
    );
    final res = await http.get(url);
    final data = json.decode(res.body);
    try {
      final element = data['rows'][0]['elements'][0];
      return (element['distance']['value'] as num).toDouble();
    } catch (e) {
      return double.infinity;
    }
  }
}
