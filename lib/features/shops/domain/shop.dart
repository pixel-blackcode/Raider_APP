/// Boutique d'un motard vérifié (D-58). Aucune transaction dans
/// l'application : la boutique regroupe ses annonces et un contact direct.
class Shop {
  const Shop({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.city,
    this.ownerName = '',
    this.description = '',
    this.area,
    this.phone,
    this.logoPath,
    this.active = true,
    this.listingCount = 0,
    this.suspended = false,
  });

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
    id: j['id'] as String,
    ownerId: j['owner_id'] as String,
    ownerName: (j['owner_name'] as String?) ?? '',
    name: j['name'] as String,
    description: (j['description'] as String?) ?? '',
    city: (j['city'] as String?) ?? '',
    area: j['area'] as String?,
    phone: j['phone'] as String?,
    logoPath: j['logo_path'] as String?,
    active: (j['active'] as bool?) ?? true,
    listingCount: (j['listing_count'] as num?)?.toInt() ?? 0,
    suspended: (j['suspended'] as bool?) ?? false,
  );

  final String id;
  final String ownerId;
  final String ownerName;
  final String name;
  final String description;
  final String city;
  final String? area;

  /// Numéro WhatsApp de la boutique (facultatif).
  final String? phone;
  final String? logoPath;

  /// Visible des autres : propriétaire vérifié et boutique non suspendue.
  final bool active;
  final int listingCount;

  /// Suspendue par l'équipe (D-64).
  final bool suspended;
}

class ShopDraft {
  const ShopDraft({
    required this.name,
    required this.city,
    this.description = '',
    this.area,
    this.phone,
  });

  final String name;
  final String city;
  final String description;
  final String? area;
  final String? phone;
}
