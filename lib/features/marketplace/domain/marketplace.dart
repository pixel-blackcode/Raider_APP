/// Marketplace (Mission 08) : petites annonces entre motards.
///
/// AUCUN paiement ni transaction dans l'application (critère 14) : le prix
/// est indicatif et la vente se conclut directement entre les personnes.
library;

enum ListingCategory {
  motorcycle,
  parts,
  helmet,
  protection,
  accessories,
  other;

  static ListingCategory parse(String? v) =>
      values.firstWhere((c) => c.name == v, orElse: () => other);
}

enum ListingCondition {
  isNew('new'),
  likeNew('like_new'),
  good('good'),
  fair('fair'),
  forParts('for_parts');

  const ListingCondition(this.dbValue);
  final String dbValue;

  static ListingCondition parse(String? v) =>
      values.firstWhere((c) => c.dbValue == v, orElse: () => good);
}

enum ListingStatus {
  available,
  reserved,
  sold;

  static ListingStatus parse(String? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => available);
}

enum Currency {
  usd('USD'),
  cdf('CDF');

  const Currency(this.code);
  final String code;

  static Currency parse(String? v) =>
      values.firstWhere((c) => c.code == v, orElse: () => usd);
}

class Listing {
  const Listing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.category,
    required this.title,
    required this.condition,
    required this.city,
    required this.createdAt,
    this.sellerAvatar,
    this.description = '',
    this.price,
    this.currency = Currency.usd,
    this.area,
    this.status = ListingStatus.available,
    this.hidden = false,
    this.mediaPaths = const [],
    this.isFavorite = false,
    this.favoriteCount = 0,
  });

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
    id: j['id'] as String,
    sellerId: j['seller_id'] as String,
    sellerName: (j['seller_name'] as String?) ?? '',
    sellerAvatar: j['seller_avatar'] as String?,
    category: ListingCategory.parse(j['category'] as String?),
    title: j['title'] as String,
    description: (j['description'] as String?) ?? '',
    price: (j['price'] as num?)?.toDouble(),
    currency: Currency.parse(j['currency'] as String?),
    condition: ListingCondition.parse(j['condition'] as String?),
    city: j['city'] as String,
    area: j['area'] as String?,
    status: ListingStatus.parse(j['status'] as String?),
    hidden: j['moderation'] == 'hidden',
    createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
    mediaPaths: [
      for (final p in (j['media_paths'] as List?) ?? const []) p as String,
    ],
    isFavorite: (j['is_favorite'] as bool?) ?? false,
    favoriteCount: (j['favorite_count'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final ListingCategory category;
  final String title;
  final String description;

  /// Prix indicatif (null : « prix à discuter »).
  final double? price;
  final Currency currency;
  final ListingCondition condition;
  final String city;

  /// Zone approximative (quartier) : jamais d'adresse exacte.
  final String? area;
  final ListingStatus status;
  final bool hidden;
  final DateTime createdAt;
  final List<String> mediaPaths;
  final bool isFavorite;
  final int favoriteCount;
}

/// Saisie d'une annonce (création ou modification).
class ListingDraft {
  const ListingDraft({
    required this.category,
    required this.title,
    required this.condition,
    required this.city,
    this.description = '',
    this.price,
    this.currency = Currency.usd,
    this.area,
  });

  final ListingCategory category;
  final String title;
  final String description;
  final double? price;
  final Currency currency;
  final ListingCondition condition;
  final String city;
  final String? area;
}

enum ListingScope { all, mine, favorites }

class ListingFilter {
  const ListingFilter({
    this.query = '',
    this.category,
    this.city = '',
    this.maxPrice,
    this.currency,
    this.scope = ListingScope.all,
  });

  final String query;
  final ListingCategory? category;
  final String city;
  final double? maxPrice;
  final Currency? currency;
  final ListingScope scope;

  ListingFilter copyWith({
    String? query,
    ListingCategory? Function()? category,
    String? city,
    double? Function()? maxPrice,
    Currency? Function()? currency,
    ListingScope? scope,
  }) => ListingFilter(
    query: query ?? this.query,
    category: category != null ? category() : this.category,
    city: city ?? this.city,
    maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    currency: currency != null ? currency() : this.currency,
    scope: scope ?? this.scope,
  );

  @override
  bool operator ==(Object other) =>
      other is ListingFilter &&
      other.query == query &&
      other.category == category &&
      other.city == city &&
      other.maxPrice == maxPrice &&
      other.currency == currency &&
      other.scope == scope;

  @override
  int get hashCode =>
      Object.hash(query, category, city, maxPrice, currency, scope);
}

/// « 80 $ », « 120 000 FC », « Prix à discuter » (texte fourni par l'appelant).
String formatPrice(double price, Currency currency) {
  final whole = price.truncateToDouble() == price;
  final raw = whole ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
  final parts = raw.split('.');
  final grouped = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  final number = parts.length > 1 ? '$grouped,${parts[1]}' : grouped;
  return currency == Currency.usd ? '$number \$' : '$number FC';
}
