import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/marketplace.dart';

extension ListingCategoryUi on ListingCategory {
  String label(AppLocalizations l10n) => switch (this) {
    ListingCategory.motorcycle => l10n.listingCatMotorcycle,
    ListingCategory.parts => l10n.listingCatParts,
    ListingCategory.helmet => l10n.listingCatHelmet,
    ListingCategory.protection => l10n.listingCatProtection,
    ListingCategory.accessories => l10n.listingCatAccessories,
    ListingCategory.other => l10n.listingCatOther,
  };

  IconData get icon => switch (this) {
    ListingCategory.motorcycle => Icons.two_wheeler,
    ListingCategory.parts => Icons.settings_outlined,
    ListingCategory.helmet => Icons.sports_motorsports_outlined,
    ListingCategory.protection => Icons.shield_outlined,
    ListingCategory.accessories => Icons.backpack_outlined,
    ListingCategory.other => Icons.category_outlined,
  };
}

extension ListingConditionUi on ListingCondition {
  String label(AppLocalizations l10n) => switch (this) {
    ListingCondition.isNew => l10n.listingCondNew,
    ListingCondition.likeNew => l10n.listingCondLikeNew,
    ListingCondition.good => l10n.listingCondGood,
    ListingCondition.fair => l10n.listingCondFair,
    ListingCondition.forParts => l10n.listingCondForParts,
  };
}

extension ListingStatusUi on ListingStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ListingStatus.available => l10n.listingStatusAvailable,
    ListingStatus.reserved => l10n.listingStatusReserved,
    ListingStatus.sold => l10n.listingStatusSold,
  };
}

String listingPrice(AppLocalizations l10n, Listing l) => l.price == null
    ? l10n.listingPriceOnRequest
    : formatPrice(l.price!, l.currency);
