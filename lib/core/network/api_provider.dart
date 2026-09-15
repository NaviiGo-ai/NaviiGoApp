import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// Global ApiClient Riverpod provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
