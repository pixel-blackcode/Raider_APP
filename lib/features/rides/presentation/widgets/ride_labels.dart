import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/ride.dart';
import '../../domain/ride_time.dart';

extension RideStatusLabel on Ride {
  /// Libellé combinant statut et verrouillage (« En cours · fermée »).
  String statusLabel(AppLocalizations l10n) {
    final base = switch (status) {
      RideStatus.draft => l10n.rideStatusDraft,
      RideStatus.published => l10n.rideStatusPublished,
      RideStatus.locked => l10n.rideStatusLocked,
      RideStatus.inProgress => l10n.rideStatusInProgress,
      RideStatus.finished => l10n.rideStatusFinished,
      RideStatus.cancelled => l10n.rideStatusCancelled,
    };
    return status == RideStatus.inProgress && joinsLocked
        ? '$base · ${l10n.rideJoinsClosed}'
        : base;
  }

  Color statusColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<RiderColors>()!;
    return switch (status) {
      RideStatus.draft => colors.stale,
      RideStatus.published => colors.success,
      RideStatus.locked => colors.warning,
      RideStatus.inProgress => scheme.primary,
      RideStatus.finished => colors.stale,
      RideStatus.cancelled => colors.sos,
    };
  }

  /// « sam. 14 nov. · 08:30 ».
  String shortSchedule() =>
      '${RideTime.formatShortDate(startsAt, timezone)} · '
      '${RideTime.formatTime(startsAt, timezone)}';
}

extension RideVisibilityLabel on RideVisibility {
  String label(AppLocalizations l10n) => switch (this) {
    RideVisibility.public => l10n.rideVisibilityPublic,
    RideVisibility.private => l10n.rideVisibilityPrivate,
    RideVisibility.club => l10n.rideVisibilityClub,
  };

  IconData get icon => switch (this) {
    RideVisibility.public => Icons.public,
    RideVisibility.private => Icons.lock_outline,
    RideVisibility.club => Icons.groups_outlined,
  };
}

extension RideJoinPolicyLabel on RideJoinPolicy {
  String label(AppLocalizations l10n) => switch (this) {
    RideJoinPolicy.open => l10n.rideJoinOpen,
    RideJoinPolicy.approval => l10n.rideJoinApproval,
    RideJoinPolicy.inviteOnly => l10n.rideJoinInviteOnly,
  };
}

extension RideDifficultyLabel on RideDifficulty {
  String label(AppLocalizations l10n) => switch (this) {
    RideDifficulty.easy => l10n.rideDifficultyEasy,
    RideDifficulty.moderate => l10n.rideDifficultyModerate,
    RideDifficulty.hard => l10n.rideDifficultyHard,
    RideDifficulty.expert => l10n.rideDifficultyExpert,
  };
}

extension BikeTypeLabel on BikeType {
  String label(AppLocalizations l10n) => switch (this) {
    BikeType.any => l10n.bikeAny,
    BikeType.scooter => l10n.bikeScooter,
    BikeType.roadster => l10n.bikeRoadster,
    BikeType.sport => l10n.bikeSport,
    BikeType.trail => l10n.bikeTrail,
    BikeType.enduro => l10n.bikeEnduro,
    BikeType.custom => l10n.bikeCustom,
    BikeType.touring => l10n.bikeTouring,
    BikeType.quad => l10n.bikeQuad,
  };
}

extension RideActionLabel on RideAction {
  String label(AppLocalizations l10n) => switch (this) {
    RideAction.publish => l10n.rideActionPublish,
    RideAction.lock => l10n.rideActionLock,
    RideAction.unlock => l10n.rideActionUnlock,
    RideAction.start => l10n.rideActionStart,
    RideAction.finish => l10n.rideActionFinish,
    RideAction.cancel => l10n.rideActionCancel,
  };

  IconData get icon => switch (this) {
    RideAction.publish => Icons.campaign_outlined,
    RideAction.lock => Icons.lock_outline,
    RideAction.unlock => Icons.lock_open,
    RideAction.start => Icons.play_arrow,
    RideAction.finish => Icons.flag_outlined,
    RideAction.cancel => Icons.cancel_outlined,
  };
}

extension RideTimeZoneLabel on RideTimeZone {
  String label(AppLocalizations l10n) => switch (this) {
    RideTimeZone.kinshasa => l10n.timezoneKinshasa,
    RideTimeZone.lubumbashi => l10n.timezoneLubumbashi,
  };
}

/// Nom lisible d'un fuseau (repli sur l'identifiant IANA).
String timezoneLabel(AppLocalizations l10n, String zoneId) =>
    RideTimeZone.tryParse(zoneId)?.label(l10n) ?? zoneId;
