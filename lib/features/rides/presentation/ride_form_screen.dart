import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/geo/point_picker.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../clubs/data/clubs_providers.dart';
import '../../clubs/domain/club.dart';
import '../data/rides_providers.dart';
import '../domain/ride.dart';
import '../domain/ride_draft.dart';
import '../domain/ride_state_machine.dart';
import '../domain/ride_time.dart';
import 'widgets/ride_labels.dart';

/// Création (rideId == null) ou modification d'une balade.
class RideFormScreen extends ConsumerWidget {
  const RideFormScreen({super.key, this.rideId, this.clubId});

  final String? rideId;

  /// Club présélectionné (création depuis la fiche d'un club).
  final String? clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = rideId;
    final clubs = ref.watch(myClubsProvider);

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.rideCreate)),
        body: AsyncValueView(
          value: clubs,
          onRetry: () => ref.invalidate(myClubsProvider),
          data: (memberships) => _RideForm(
            manageableClubs: [
              for (final m in memberships)
                if (m.role.rank >= ClubRole.admin.rank) m.club,
            ],
            initialClubId: clubId,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rideEdit)),
      body: AsyncValueView(
        value: ref.watch(rideDetailProvider(id)),
        onRetry: () => ref.invalidate(rideDetailProvider(id)),
        data: (detail) {
          if (detail == null ||
              !detail.canManage ||
              !RideStateMachine.isEditable(detail.ride.status)) {
            return EmptyState(
              icon: Icons.lock_outline,
              title: l10n.errorNotAllowed,
              message: l10n.rideEditNotAllowed,
            );
          }
          return _RideForm(ride: detail.ride, manageableClubs: const []);
        },
      ),
    );
  }
}

class _RideForm extends ConsumerStatefulWidget {
  const _RideForm({
    required this.manageableClubs,
    this.ride,
    this.initialClubId,
  });

  final Ride? ride;
  final List<Club> manageableClubs;
  final String? initialClubId;

  @override
  ConsumerState<_RideForm> createState() => _RideFormState();
}

class _RideFormState extends ConsumerState<_RideForm> {
  final _formKey = GlobalKey<FormState>();
  late final Ride? _ride = widget.ride;

  late final _title = TextEditingController(text: _ride?.title);
  late final _description = TextEditingController(text: _ride?.description);
  late final _city = TextEditingController(text: _ride?.city);
  late final _start = TextEditingController(text: _ride?.startLabel);
  late final _destination = TextEditingController(
    text: _ride?.destinationLabel,
  );
  late final _itinerary = TextEditingController(text: _ride?.itinerary);
  late final _conditions = TextEditingController(text: _ride?.conditions);
  late final _maxParticipants = TextEditingController(
    text: _ride?.maxParticipants?.toString(),
  );

  late String? _clubId =
      _ride?.clubId ??
      (widget.manageableClubs.any((c) => c.id == widget.initialClubId)
          ? widget.initialClubId
          : null);
  late RideVisibility _visibility =
      _ride?.visibility ??
      (_clubId != null ? RideVisibility.club : RideVisibility.public);
  late bool _openToNonMembers = _ride?.openToNonMembers ?? false;
  late RideJoinPolicy _joinPolicy = _ride?.joinPolicy ?? RideJoinPolicy.open;
  late RideDifficulty _difficulty =
      _ride?.difficulty ?? RideDifficulty.moderate;
  late final Set<BikeType> _bikeTypes = {
    ...?_ride?.bikeTypes,
    if (_ride == null) BikeType.any,
  };
  late String _zone = _ride?.timezone ?? RideTimeZone.kinshasa.id;
  late GeoPoint? _startPoint =
      _ride?.startLat == null || _ride?.startLng == null
      ? null
      : GeoPoint(_ride!.startLat!, _ride.startLng!);
  late GeoPoint? _destinationPoint =
      _ride?.destinationLat == null || _ride?.destinationLng == null
      ? null
      : GeoPoint(_ride!.destinationLat!, _ride.destinationLng!);
  PickedImage? _cover;
  bool _removeCover = false;
  late DateTime _date;
  late TimeOfDay _time;
  bool _busy = false;

  bool get _isEditing => _ride != null;

  @override
  void initState() {
    super.initState();
    if (_ride != null) {
      final local = RideTime.inZone(_ride.startsAt, _ride.timezone);
      _date = DateTime(local.year, local.month, local.day);
      _time = TimeOfDay(hour: local.hour, minute: local.minute);
    } else {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      _time = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _city,
      _start,
      _destination,
      _itinerary,
      _conditions,
      _maxParticipants,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get _startsAtUtc => RideTime.toUtc(
    localDate: _date,
    hour: _time.hour,
    minute: _time.minute,
    zoneId: _zone,
  );

  RideDraft get _draft => RideDraft(
    title: _title.text,
    description: _description.text,
    startsAt: _startsAtUtc,
    timezone: _zone,
    city: _city.text,
    startLabel: _start.text,
    destinationLabel: _destination.text,
    itinerary: _itinerary.text,
    conditions: _conditions.text,
    maxParticipants: int.tryParse(_maxParticipants.text.trim()),
    visibility: _visibility,
    clubId: _visibility == RideVisibility.club ? _clubId : null,
    openToNonMembers: _openToNonMembers,
    joinPolicy: _joinPolicy,
    difficulty: _difficulty,
    bikeTypes: _bikeTypes,
    startLat: _startPoint?.lat,
    startLng: _startPoint?.lng,
    destinationLat: _destinationPoint?.lat,
    destinationLng: _destinationPoint?.lng,
  );

  Future<void> _pickPoint({required bool start}) async {
    final l10n = AppLocalizations.of(context);
    final picked = await ref.read(pointPickerProvider)(
      context,
      initial: start ? _startPoint : (_destinationPoint ?? _startPoint),
      title: start ? l10n.rideMapPickStart : l10n.rideMapPickDestination,
    );
    if (picked == null || !mounted) return;
    setState(() => start ? _startPoint = picked : _destinationPoint = picked);
  }

  Future<void> _pickCover() async {
    try {
      final image = await ref
          .read(photoPickerProvider)
          .pick(maxDimension: 1600);
      if (image == null) return;
      image.validateFor(MediaBucket.rideMedia);
      setState(() {
        _cover = image;
        _removeCover = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(describeError(context, error))),
          );
      }
    }
  }

  /// Photo de couverture, après l'enregistrement de la balade (son dossier
  /// porte l'identifiant de la balade).
  Future<void> _saveCover(String rideId) async {
    final repository = ref.read(ridesRepositoryProvider)!;
    final media = ref.read(mediaRepositoryProvider);
    String? old;
    if (_cover != null && media != null) {
      final path = await media.upload(
        MediaBucket.rideMedia,
        folder: rideId,
        baseName: 'cover',
        image: _cover!,
      );
      old = await repository.setCover(rideId, path);
    } else if (_removeCover) {
      old = await repository.setCover(rideId, null);
    } else {
      return;
    }
    if (old != null) {
      try {
        await media?.remove(MediaBucket.rideMedia, [old]);
      } catch (_) {}
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit({required bool publish}) async {
    final repository = ref.read(ridesRepositoryProvider);
    if (repository == null || !_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final draft = _draft;
    final issues = draft.validate(
      now: DateTime.now(),
      publishing: publish || (_isEditing && _ride!.status != RideStatus.draft),
    );
    if (issues.isNotEmpty) {
      final message = issues.contains(RideDraftIssue.startInPast)
          ? l10n.errorStartInPast
          : issues.contains(RideDraftIssue.bikeTypes)
          ? l10n.validationBikeTypes
          : l10n.errorInvalidInput;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() => _busy = true);
    try {
      if (_isEditing) {
        await repository.updateRide(_ride!.id, draft);
        await _saveCover(_ride.id);
        ref.refreshRides(_ride.id);
        if (mounted) context.pop();
      } else {
        final ride = await repository.createRide(draft, publish: publish);
        try {
          await _saveCover(ride.id);
        } catch (error) {
          // La balade existe : on la montre et on signale la photo manquante.
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.rideCoverNotSaved)));
        }
        ref.refreshRides();
        if (mounted) context.pushReplacement(AppRoutes.ride(ride.id));
      }
    } catch (error) {
      if (mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(describeError(context, error))),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _lengthValidator(String? v, int min, int max, String message) {
    final length = (v ?? '').trim().length;
    return length >= min && length <= max ? null : message;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final materialL10n = MaterialLocalizations.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _CoverPicker(
            picked: _cover,
            remotePath: _removeCover ? null : _ride?.coverPath,
            onPick: _busy ? null : _pickCover,
            onRemove: _busy
                ? null
                : () => setState(() {
                    _cover = null;
                    _removeCover = _ride?.coverPath != null;
                  }),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('ride-field-title'),
            controller: _title,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.rideFieldTitle),
            validator: (v) =>
                _lengthValidator(v, 3, 100, l10n.validationRideTitle),
          ),
          TextFormField(
            controller: _description,
            maxLength: 3000,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.clubFieldDescription),
          ),
          SectionHeader(title: l10n.rideSectionWhen),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('ride-field-date'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(materialL10n.formatMediumDate(_date)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('ride-field-time'),
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    materialL10n.formatTimeOfDay(
                      _time,
                      alwaysUse24HourFormat: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            key: const Key('ride-field-timezone'),
            initialValue: _zone,
            decoration: InputDecoration(labelText: l10n.rideFieldTimezone),
            items: [
              for (final zone in RideTimeZone.values)
                DropdownMenuItem(value: zone.id, child: Text(zone.label(l10n))),
              if (RideTimeZone.tryParse(_zone) == null)
                DropdownMenuItem(value: _zone, child: Text(_zone)),
            ],
            onChanged: (v) => setState(() => _zone = v ?? _zone),
          ),
          SectionHeader(title: l10n.rideSectionWhere),
          TextFormField(
            key: const Key('ride-field-city'),
            controller: _city,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.fieldCity),
            validator: (v) => _lengthValidator(v, 2, 80, l10n.validationCity),
          ),
          TextFormField(
            key: const Key('ride-field-start'),
            controller: _start,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: l10n.rideFieldStart,
              prefixIcon: const Icon(Icons.trip_origin),
            ),
            validator: (v) =>
                _lengthValidator(v, 2, 120, l10n.validationRidePlace),
          ),
          _PointRow(
            keyName: 'ride-pick-start',
            point: _startPoint,
            label: l10n.rideMapPickStart,
            onPick: () => _pickPoint(start: true),
            onClear: () => setState(() => _startPoint = null),
          ),
          TextFormField(
            key: const Key('ride-field-destination'),
            controller: _destination,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: l10n.rideFieldDestination,
              prefixIcon: const Icon(Icons.flag_outlined),
            ),
            validator: (v) =>
                _lengthValidator(v, 2, 120, l10n.validationRidePlace),
          ),
          _PointRow(
            keyName: 'ride-pick-destination',
            point: _destinationPoint,
            label: l10n.rideMapPickDestination,
            onPick: () => _pickPoint(start: false),
            onClear: () => setState(() => _destinationPoint = null),
          ),
          if (_draft.distanceMeters != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                l10n.rideDistance(formatDistance(_draft.distanceMeters!)),
                key: const Key('ride-distance'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          TextFormField(
            controller: _itinerary,
            maxLength: 3000,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.rideFieldItinerary,
              helperText: l10n.rideFieldItineraryHelp,
            ),
          ),
          SectionHeader(title: l10n.rideSectionRiders),
          Text(l10n.rideFieldDifficulty, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final d in RideDifficulty.values)
                ChoiceChip(
                  key: Key('ride-difficulty-${d.dbValue}'),
                  label: Text(d.label(l10n)),
                  selected: _difficulty == d,
                  onSelected: (_) => setState(() => _difficulty = d),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.rideFieldBikeTypes, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final type in BikeType.values)
                FilterChip(
                  key: Key('ride-bike-${type.dbValue}'),
                  label: Text(type.label(l10n)),
                  selected: _bikeTypes.contains(type),
                  onSelected: (selected) => setState(() {
                    if (type == BikeType.any && selected) {
                      _bikeTypes
                        ..clear()
                        ..add(BikeType.any);
                    } else if (selected) {
                      _bikeTypes
                        ..remove(BikeType.any)
                        ..add(type);
                    } else {
                      _bikeTypes.remove(type);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('ride-field-max'),
            controller: _maxParticipants,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.rideFieldMaxParticipants,
              helperText: l10n.rideFieldMaxParticipantsHelp,
            ),
            validator: (v) {
              final text = (v ?? '').trim();
              if (text.isEmpty) return null;
              final n = int.tryParse(text);
              return n != null && n >= 2 && n <= 500
                  ? null
                  : l10n.validationMaxParticipants;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _conditions,
            maxLength: 1000,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.rideFieldConditions,
              helperText: l10n.rideFieldConditionsHelp,
            ),
          ),
          SectionHeader(title: l10n.clubSectionAccess),
          if (!_isEditing && widget.manageableClubs.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              key: const Key('ride-field-club'),
              initialValue: _clubId,
              decoration: InputDecoration(labelText: l10n.rideFieldOrganizedBy),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.rideOrganizedByMe),
                ),
                for (final club in widget.manageableClubs)
                  DropdownMenuItem<String?>(
                    value: club.id,
                    child: Text(club.name),
                  ),
              ],
              onChanged: (value) => setState(() {
                _clubId = value;
                _visibility = value == null
                    ? RideVisibility.public
                    : RideVisibility.club;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_visibility == RideVisibility.club)
            SwitchListTile(
              key: const Key('ride-field-open-to-non-members'),
              contentPadding: EdgeInsets.zero,
              value: _openToNonMembers,
              onChanged: (v) => setState(() => _openToNonMembers = v),
              title: Text(l10n.rideFieldOpenToNonMembers),
              subtitle: Text(l10n.rideFieldOpenToNonMembersHelp),
            )
          else
            SegmentedButton<RideVisibility>(
              key: const Key('ride-field-visibility'),
              segments: [
                for (final v in [RideVisibility.public, RideVisibility.private])
                  ButtonSegment(
                    value: v,
                    label: Text(v.label(l10n)),
                    icon: Icon(v.icon),
                  ),
              ],
              selected: {_visibility},
              onSelectionChanged: (s) => setState(() => _visibility = s.first),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.rideFieldJoinPolicy, style: theme.textTheme.titleSmall),
          RadioGroup<RideJoinPolicy>(
            groupValue: _joinPolicy,
            onChanged: (v) {
              if (v != null) setState(() => _joinPolicy = v);
            },
            child: Column(
              children: [
                for (final policy in RideJoinPolicy.values)
                  RadioListTile<RideJoinPolicy>(
                    key: Key('ride-join-${policy.dbValue}'),
                    contentPadding: EdgeInsets.zero,
                    value: policy,
                    title: Text(policy.label(l10n)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isEditing)
            FilledButton(
              key: const Key('ride-save'),
              onPressed: _busy ? null : () => _submit(publish: false),
              child: Text(l10n.actionSave),
            )
          else ...[
            FilledButton.icon(
              key: const Key('ride-publish'),
              onPressed: _busy ? null : () => _submit(publish: true),
              icon: const Icon(Icons.campaign_outlined),
              label: Text(l10n.rideActionPublish),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              key: const Key('ride-save-draft'),
              onPressed: _busy ? null : () => _submit(publish: false),
              child: Text(l10n.rideSaveDraft),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Point pointé sur la carte (facultatif) : bouton, état, effacement.
class _PointRow extends StatelessWidget {
  const _PointRow({
    required this.keyName,
    required this.point,
    required this.label,
    required this.onPick,
    required this.onClear,
  });

  final String keyName;
  final GeoPoint? point;
  final String label;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: Key(keyName),
              onPressed: onPick,
              icon: Icon(
                point == null
                    ? Icons.add_location_alt_outlined
                    : Icons.edit_location_alt,
              ),
              label: Text(point == null ? label : l10n.rideMapPointSet),
            ),
          ),
          if (point != null)
            IconButton(
              key: Key('$keyName-clear'),
              tooltip: l10n.rideMapClear,
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

/// Photo de couverture facultative de la balade.
class _CoverPicker extends ConsumerWidget {
  const _CoverPicker({
    required this.picked,
    required this.remotePath,
    required this.onPick,
    required this.onRemove,
  });

  final PickedImage? picked;
  final String? remotePath;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final remote = ref
        .watch(mediaRepositoryProvider)
        ?.imageProvider(MediaBucket.rideMedia, remotePath);
    final ImageProvider? image = picked != null
        ? MemoryImage(picked!.bytes)
        : remote;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: scheme.surfaceContainerHighest,
          child: InkWell(
            key: const Key('ride-cover-pick'),
            onTap: onPick,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  Image(
                    image: image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: scheme.onSurfaceVariant,
                      ),
                      Text(l10n.rideCoverAdd),
                    ],
                  ),
                if (image != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filledTonal(
                      key: const Key('ride-cover-remove'),
                      tooltip: l10n.actionDelete,
                      onPressed: onRemove,
                      icon: const Icon(Icons.close),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
