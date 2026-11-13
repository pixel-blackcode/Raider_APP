/// Communauté (Mission 07) : publications, commentaires, réactions,
/// signalements et modération. Toutes les règles d'accès sont appliquées
/// par le serveur (voir la migration `community`).
library;

enum PostAudience {
  public('public'),
  club('club');

  const PostAudience(this.dbValue);
  final String dbValue;

  static PostAudience parse(String? v) =>
      values.firstWhere((a) => a.dbValue == v, orElse: () => public);
}

enum ReactionKind {
  like('like'),
  fire('fire'),
  respect('respect');

  const ReactionKind(this.dbValue);
  final String dbValue;

  static ReactionKind? tryParse(String? v) {
    for (final k in values) {
      if (k.dbValue == v) return k;
    }
    return null;
  }
}

enum ReportTarget { post, comment, message, user }

enum ReportReason { spam, harassment, hate, violence, nudity, scam, other }

enum ModerationAction { hide, restore, dismiss }

DateTime _date(Object? v) => DateTime.parse(v as String).toUtc();

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.audience,
    required this.body,
    required this.createdAt,
    this.authorAvatar,
    this.clubId,
    this.clubName,
    this.hidden = false,
    this.mediaPaths = const [],
    this.commentCount = 0,
    this.reactions = const {},
    this.myReaction,
  });

  factory Post.fromJson(Map<String, dynamic> j) => Post(
    id: j['id'] as String,
    authorId: j['author_id'] as String,
    authorName: (j['author_name'] as String?) ?? '',
    authorAvatar: j['author_avatar'] as String?,
    clubId: j['club_id'] as String?,
    clubName: j['club_name'] as String?,
    audience: PostAudience.parse(j['audience'] as String?),
    body: (j['body'] as String?) ?? '',
    hidden: j['moderation'] == 'hidden',
    createdAt: _date(j['created_at']),
    mediaPaths: [
      for (final p in (j['media_paths'] as List?) ?? const []) p as String,
    ],
    commentCount: (j['comment_count'] as num?)?.toInt() ?? 0,
    reactions: {
      for (final e in ((j['reactions'] as Map?) ?? const {}).entries)
        if (ReactionKind.tryParse(e.key as String) != null)
          ReactionKind.tryParse(e.key as String)!: (e.value as num).toInt(),
    },
    myReaction: ReactionKind.tryParse(j['my_reaction'] as String?),
  );

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? clubId;
  final String? clubName;
  final PostAudience audience;
  final String body;

  /// Masquée par la modération (visible seulement par l'auteur et les
  /// modérateurs, avec une mention).
  final bool hidden;
  final DateTime createdAt;
  final List<String> mediaPaths;
  final int commentCount;
  final Map<ReactionKind, int> reactions;
  final ReactionKind? myReaction;

  int get reactionTotal => reactions.values.fold(0, (a, b) => a + b);

  /// Copie avec MA réaction modifiée (mise à jour optimiste de l'affichage).
  Post withMyReaction(ReactionKind? kind) {
    final counts = {...reactions};
    if (myReaction != null) {
      counts[myReaction!] = (counts[myReaction!] ?? 1) - 1;
      if (counts[myReaction!]! <= 0) counts.remove(myReaction);
    }
    if (kind != null) counts[kind] = (counts[kind] ?? 0) + 1;
    return Post(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      clubId: clubId,
      clubName: clubName,
      audience: audience,
      body: body,
      hidden: hidden,
      createdAt: createdAt,
      mediaPaths: mediaPaths,
      commentCount: commentCount,
      reactions: counts,
      myReaction: kind,
    );
  }
}

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.authorAvatar,
    this.hidden = false,
  });

  factory PostComment.fromJson(Map<String, dynamic> j) => PostComment(
    id: j['id'] as String,
    postId: j['post_id'] as String,
    authorId: j['author_id'] as String,
    authorName: (j['author_name'] as String?) ?? '',
    authorAvatar: j['author_avatar'] as String?,
    body: j['body'] as String,
    hidden: j['moderation'] == 'hidden',
    createdAt: _date(j['created_at']),
  );

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String body;
  final bool hidden;
  final DateTime createdAt;
}

class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.displayName,
    required this.username,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> j) => BlockedUser(
    userId: j['user_id'] as String,
    displayName: j['display_name'] as String,
    username: j['username'] as String,
  );

  final String userId;
  final String displayName;
  final String username;
}

class ModerationItem {
  const ModerationItem({
    required this.target,
    required this.targetId,
    required this.reportCount,
    required this.reasons,
    required this.lastReportedAt,
    this.clubId,
    this.preview,
    this.authorId,
    this.authorName,
    this.hidden = false,
  });

  factory ModerationItem.fromJson(Map<String, dynamic> j) => ModerationItem(
    target: ReportTarget.values.byName(j['target_type'] as String),
    targetId: j['target_id'] as String,
    clubId: j['club_id'] as String?,
    reportCount: (j['report_count'] as num).toInt(),
    reasons: [
      for (final r in (j['reasons'] as List?) ?? const [])
        ReportReason.values.byName(r as String),
    ],
    lastReportedAt: _date(j['last_reported_at']),
    preview: j['preview'] as String?,
    authorId: j['author_id'] as String?,
    authorName: j['author_name'] as String?,
    hidden: j['moderation'] == 'hidden',
  );

  final ReportTarget target;
  final String targetId;
  final String? clubId;
  final int reportCount;
  final List<ReportReason> reasons;
  final DateTime lastReportedAt;
  final String? preview;
  final String? authorId;
  final String? authorName;
  final bool hidden;
}
