import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/client_ref.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../data/community_providers.dart';
import '../data/community_repository.dart';
import '../domain/community.dart';
import 'community_ui.dart';

/// Nouvelle publication : texte et jusqu'à 4 photos, dans le fil général ou
/// dans l'espace d'un club. Un renvoi après échec ne crée pas de doublon.
class PostComposerScreen extends ConsumerStatefulWidget {
  const PostComposerScreen({super.key, this.clubId});

  final String? clubId;

  static const maxPhotos = 10;

  @override
  ConsumerState<PostComposerScreen> createState() => _PostComposerScreenState();
}

class _PostComposerScreenState extends ConsumerState<PostComposerScreen> {
  final _body = TextEditingController();
  final _photos = <PickedImage>[];

  /// Photos déjà envoyées (photo → chemin) : pas de double envoi au renvoi.
  final _uploaded = <PickedImage, String>{};
  final _clientRef = newClientRef();
  PostAudience _audience = PostAudience.public;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.clubId != null) _audience = PostAudience.club;
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    try {
      final image = await ref
          .read(photoPickerProvider)
          .pick(maxDimension: 1600);
      if (image == null) return;
      image.validateFor(MediaBucket.postMedia);
      setState(() => _photos.add(image));
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    }
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    final text = _body.text.trim();
    if (text.isEmpty && _photos.isEmpty) {
      setState(() => _error = l10n.postEmpty);
      return;
    }
    final repo = ref.read(communityRepositoryProvider);
    final media = ref.read(mediaRepositoryProvider);
    final uid = ref.read(currentUserIdProvider);
    if (repo == null || uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final paths = <String>[];
      for (final photo in _photos) {
        paths.add(
          _uploaded[photo] ??= await media!.upload(
            MediaBucket.postMedia,
            folder: uid,
            baseName: 'post',
            image: photo,
          ),
        );
      }
      await repo.createPost(
        clientRef: _clientRef,
        body: text,
        audience: _audience,
        clubId: widget.clubId,
        mediaPaths: paths,
      );
      if (!mounted) return;
      refreshCommunity(ref);
      showSnack(context, l10n.postPublished);
      context.pop();
    } catch (error) {
      // Jamais présentée comme publiée sans réponse du serveur.
      if (mounted) {
        setState(
          () => _error = '${l10n.postNotSent} ${describeError(context, error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.clubId == null ? l10n.postNewTitle : l10n.postNewClubTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton(
              key: const Key('post-publish'),
              onPressed: _busy ? null : _publish,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.postPublish),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (widget.clubId != null) ...[
            SegmentedButton<PostAudience>(
              key: const Key('post-audience'),
              segments: [
                ButtonSegment(
                  value: PostAudience.club,
                  icon: const Icon(Icons.lock_outline),
                  label: Text(l10n.postAudienceClub),
                ),
                ButtonSegment(
                  value: PostAudience.public,
                  icon: const Icon(Icons.public),
                  label: Text(l10n.postAudiencePublic),
                ),
              ],
              selected: {_audience},
              onSelectionChanged: (s) => setState(() => _audience = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            key: const Key('post-body'),
            controller: _body,
            minLines: 4,
            maxLines: 12,
            maxLength: 2000,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: l10n.postBodyHint,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _error!,
                key: const Key('post-error'),
                style: TextStyle(
                  color: colors.sos,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (i, photo) in _photos.indexed)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        photo.bytes,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 96,
                          height: 96,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton.filledTonal(
                        key: Key('post-photo-remove-$i'),
                        tooltip: l10n.actionDelete,
                        onPressed: _busy
                            ? null
                            : () => setState(() => _photos.removeAt(i)),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
              if (_photos.length < PostComposerScreen.maxPhotos)
                SizedBox(
                  width: 96,
                  height: 96,
                  child: OutlinedButton(
                    key: const Key('post-add-photo'),
                    onPressed: _busy ? null : _addPhoto,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined),
                        Text(
                          '${_photos.length}/${PostComposerScreen.maxPhotos}',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.postGuidelines, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
