import 'json.dart';

/// Página de resultados (espeja `PageResponse` del backend).
class PageOf<T> {
  const PageOf({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  factory PageOf.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) item,
  ) =>
      PageOf(
        content: ((j['content'] as List?) ?? const [])
            .map((e) => item(e as Map<String, dynamic>))
            .toList(),
        page: jsonInt(j['page']),
        size: jsonInt(j['size']),
        totalElements: jsonInt(j['totalElements']),
        totalPages: jsonInt(j['totalPages']),
        last: j['last'] != false,
      );
}
