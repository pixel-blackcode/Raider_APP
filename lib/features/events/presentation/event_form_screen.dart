import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/geo/point_picker.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/client_ref.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_ui.dart';
import '../data/events_repository.dart';
import '../domain/moto_event.dart';

/// Création (avec [clubId]) ou modification (avec [eventId]) d'un événement.
class EventFormScreen extends ConsumerWidget {
  const EventFormScreen({super.key, this.clubId, this.eventId});

  final String? clubId;
  final String? eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (eventId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.eventNewTitle)),
        body: _EventForm(clubId: clubId),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.eventEditTitle)),
      body: AsyncValueView(
        value: ref.watch(eventDetailProvider(eventId!)),
        data: (e) => e == null ? const SizedBox.shrink() : _EventForm(event: e),
      ),
    );
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({this.clubId, this.event});

  final String? clubId;
  final MotoEvent? event;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.event?.title);
  late final _place = TextEditingController(text: widget.event?.placeName);
  late final _city = TextEditingController(
    text: widget.event?.city ?? 'Kinshasa',
  );
  late final _description = TextEditingController(
    text: widget.event?.description,
  );
  late DateTime _start =
      widget.event?.startsAt.toLocal() ??
      DateTime.now()
          .add(const Duration(days: 7))
          .copyWith(
            hour: 9,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0,
          );
  late DateTime? _end = widget.event?.endsAt?.toLocal();
  late GeoPoint? _point = widget.event?.lat == null
      ? null
      : GeoPoint(widget.event!.lat!, widget.event!.lng!);
  final _clientRef = newClientRef();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_title, _place, _city, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    if (_end != null && !_end!.isAfter(_start)) {
      showSnack(context, l10n.eventEndBeforeStart);
      return;
    }
    final draft = EventDraft(
      title: _title.text,
      startsAt: _start,
      endsAt: _end,
      placeName: _place.text,
      city: _city.text,
      description: _description.text,
      lat: _point?.lat,
      lng: _point?.lng,
    );
    final repo = ref.read(eventsRepositoryProvider)!;
    setState(() => _busy = true);
    try {
      if (widget.event == null) {
        final id = await repo.create(widget.clubId!, _clientRef, draft);
        ref.refreshEvents();
        if (!mounted) return;
        context.pushReplacement(AppRoutes.event(id));
      } else {
        await repo.update(widget.event!.id, draft);
        ref.refreshEvents(widget.event!.id);
        if (!mounted) return;
        context.pop();
      }
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = MaterialLocalizations.of(context);
    String fmt(DateTime d) =>
        '${m.formatMediumDate(d)} · ${m.formatTimeOfDay(TimeOfDay.fromDateTime(d), alwaysUse24HourFormat: true)}';
    String? len(String? v, int min, int max) {
      final n = (v ?? '').trim().length;
      return n < min || n > max ? l10n.validationTooShort(min) : null;
    }

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextFormField(
            key: const Key('event-title'),
            controller: _title,
            maxLength: 120,
            decoration: InputDecoration(labelText: l10n.eventFieldTitle),
            validator: (v) => len(v, 3, 120),
          ),
          TextFormField(
            key: const Key('event-place'),
            controller: _place,
            maxLength: 160,
            decoration: InputDecoration(labelText: l10n.eventFieldPlace),
            validator: (v) => len(v, 2, 160),
          ),
          TextFormField(
            key: const Key('event-city'),
            controller: _city,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.eventFieldCity),
            validator: (v) => len(v, 2, 80),
          ),
          ListTile(
            key: const Key('event-map-point'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _point == null ? Icons.add_location_alt_outlined : Icons.place,
              color: _point == null
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              _point == null ? l10n.eventPointOnMap : l10n.eventPointPicked,
            ),
            subtitle: Text(l10n.eventPointHelp),
            trailing: _point == null
                ? const Icon(Icons.chevron_right)
                : IconButton(
                    key: const Key('event-map-clear'),
                    tooltip: l10n.actionDelete,
                    onPressed: () => setState(() => _point = null),
                    icon: const Icon(Icons.clear),
                  ),
            onTap: () async {
              final p = await ref.read(placePickerProvider)(
                context,
                initial: _point,
              );
              if (p != null && mounted) setState(() => _point = p);
            },
          ),
          ListTile(
            key: const Key('event-start'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(l10n.eventFieldStart),
            subtitle: Text(fmt(_start)),
            onTap: () async {
              final d = await _pick(_start);
              if (d != null) setState(() => _start = d);
            },
          ),
          ListTile(
            key: const Key('event-end'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available),
            title: Text(l10n.eventFieldEnd),
            subtitle: Text(_end == null ? l10n.eventNoEnd : fmt(_end!)),
            trailing: _end == null
                ? null
                : IconButton(
                    onPressed: () => setState(() => _end = null),
                    icon: const Icon(Icons.clear),
                  ),
            onTap: () async {
              final d = await _pick(
                _end ?? _start.add(const Duration(hours: 4)),
              );
              if (d != null) setState(() => _end = d);
            },
          ),
          TextFormField(
            key: const Key('event-description'),
            controller: _description,
            maxLength: 3000,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(labelText: l10n.eventFieldDescription),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const Key('event-submit'),
            onPressed: _busy ? null : _submit,
            child: Text(
              widget.event == null ? l10n.eventCreate : l10n.actionSave,
            ),
          ),
        ],
      ),
    );
  }
}
