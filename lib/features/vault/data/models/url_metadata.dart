import 'package:equatable/equatable.dart';

class UrlMetadata extends Equatable {
  final String url;
  final String? title;
  final String? description;
  final String? image;
  final String? siteName;
  final String sourceType;

  const UrlMetadata({
    required this.url,
    this.title,
    this.description,
    this.image,
    this.siteName,
    required this.sourceType,
  });

  factory UrlMetadata.fromJson(Map<String, dynamic> j) => UrlMetadata(
        url: j['url'] as String,
        title: j['title'] as String?,
        description: j['description'] as String?,
        image: j['image'] as String?,
        siteName: j['siteName'] as String?,
        sourceType: j['sourceType'] as String? ?? 'other',
      );

  bool get hasContent => title != null || image != null;

  @override
  List<Object?> get props => [url, title, description, image, siteName, sourceType];
}
