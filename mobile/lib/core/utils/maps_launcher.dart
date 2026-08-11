import 'package:url_launcher/url_launcher.dart';

Future<bool> openMapsUrl(String url) async {
  if (url.isEmpty) return false;
  final uri = Uri.parse(url);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
