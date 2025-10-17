import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // Overpass API query for golf courses in Sweden (using bounding box for Sweden)
  final query = '''
  [out:json][timeout:60];
  (
    node["leisure"="golf_course"](55.0,10.5,69.0,24.0);
    way["leisure"="golf_course"](55.0,10.5,69.0,24.0);
    relation["leisure"="golf_course"](55.0,10.5,69.0,24.0);
  );
  out body;
  >;
  out skel qt;
  ''';

  final url = 'https://overpass-api.de/api/interpreter';
  final response = await http.post(Uri.parse(url), body: {'data': query});

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final List courses = [];
    for (var element in data['elements']) {
      final tags = element['tags'] ?? {};
      courses.add({
        'name': tags['name'] ?? 'Unknown',
        'holes': tags['holes'],
        'website': tags['website'],
        'wikidata': tags['wikidata'],
        'osm_id': element['id'],
        'type': element['type'],
        'lat': element['lat'],
        'lon': element['lon'],
        'distance': null, // Can be calculated later if needed
      });
    }
    final file = File('lib/golf_courses_sweden.json');
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(courses));
    print('Saved ${courses.length} golf courses to lib/golf_courses_sweden.json');
  } else {
    print('Failed to fetch data: ${response.statusCode}');
  }
}
