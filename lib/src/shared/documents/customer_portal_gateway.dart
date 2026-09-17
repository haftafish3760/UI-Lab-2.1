import 'dart:convert';
import 'package:http/http.dart' as http;
import 'customer_document.dart';

/// Account integration supplies a fresh Firebase ID token, never a service key.
/// No default host or demonstration URL can create an apparently live link.
class CustomerPortalGateway {
  CustomerPortalGateway({
    required this.origin,
    required this.idToken,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    if (origin.scheme != 'https' ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw ArgumentError('A secure customer portal origin is required.');
    }
  }
  final Uri origin;
  final Future<String> Function() idToken;
  final http.Client _client;

  Future<Map<String, dynamic>> _request(
    String action,
    Map<String, Object?> body, {
    String? reviewToken,
  }) async {
    final token = reviewToken ?? await idToken();
    if (token.isEmpty) {
      throw StateError('Sign in before creating customer links.');
    }
    final response = await _client
        .post(
          origin.resolve('/api/$action'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 25));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw StateError(
        data['error'] as String? ?? 'The customer portal is unavailable.',
      );
    }
    return data;
  }

  Future<CustomerReviewLink> create(
    String recordId,
    CustomerDocument document,
  ) async {
    if (document.draft) {
      throw StateError('Finish the draft before creating a review link.');
    }
    final data = await _request('issue', {
      'recordId': recordId,
      'snapshot': document.toPortalJson(),
    });
    final token = data['token'] as String;
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) {
      throw const FormatException('The portal returned an invalid link.');
    }
    return CustomerReviewLink(
      url: origin.replace(path: '/', fragment: token),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(data['expiresAt'] as int),
      digest: data['digest'] as String,
    );
  }

  Future<void> revoke(CustomerReviewLink link) async {
    await _request('revoke', {'token': link.url.fragment});
  }

  Future<Map<String, dynamic>> refresh(CustomerReviewLink link) =>
      _request('status', {'token': link.url.fragment});
  void close() => _client.close();
}

class CustomerReviewLink {
  const CustomerReviewLink({
    required this.url,
    required this.expiresAt,
    required this.digest,
  });
  final Uri url;
  final DateTime expiresAt;
  final String digest;
}
