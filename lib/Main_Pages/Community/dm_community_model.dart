// lib/models/community_models.dart

class Category {
  final int id;
  final String name;
  final String slug;
  final String color;
  final String description;
  final int topicCount;
  final int postCount;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.color,
    required this.description,
    required this.topicCount,
    required this.postCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        color: json['color'] as String? ?? '0088CC',
        description: json['description'] as String? ?? '',
        topicCount: json['topic_count'] as int? ?? 0,
        postCount: json['post_count'] as int? ?? 0,
      );
}

class Topic {
  final int id;
  final String title;
  final String slug;
  final int postsCount;
  final int replyCount;
  final int views;
  final int likeCount;
  final String? createdAt;
  final String? lastPostedAt;
  final int? categoryId;
  final bool pinned;
  final bool closed;
  final String excerpt;
  final String opUsername;
  final String opAvatarTemplate;

  const Topic({
    required this.id,
    required this.title,
    required this.slug,
    required this.postsCount,
    required this.replyCount,
    required this.views,
    required this.likeCount,
    this.createdAt,
    this.lastPostedAt,
    this.categoryId,
    required this.pinned,
    required this.closed,
    required this.excerpt,
    required this.opUsername,
    required this.opAvatarTemplate,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as int,
        title: json['title'] as String,
        slug: json['slug'] as String? ?? '',
        postsCount: json['posts_count'] as int? ?? 0,
        replyCount: json['reply_count'] as int? ?? 0,
        views: json['views'] as int? ?? 0,
        likeCount: json['like_count'] as int? ?? 0,
        createdAt: json['created_at'] as String?,
        lastPostedAt: json['last_posted_at'] as String?,
        categoryId: json['category_id'] as int?,
        pinned: json['pinned'] as bool? ?? false,
        closed: json['closed'] as bool? ?? false,
        excerpt: json['excerpt'] as String? ?? '',
        opUsername: json['op_username'] as String? ?? '',
        opAvatarTemplate: json['op_avatar'] as String? ?? '',
      );
}

class Post {
  final int id;
  final int postNumber;
  final String username;
  final String displayName;
  final String avatarTemplate;
  final String cooked;
  final String raw;
  final String? createdAt;
  int likeCount;
  final int? replyToPostNumber;
  final bool yours;
  final bool canEdit;
  final bool canDelete;
  bool isLiked;

  Post({
    required this.id,
    required this.postNumber,
    required this.username,
    required this.displayName,
    required this.avatarTemplate,
    required this.cooked,
    required this.raw,
    this.createdAt,
    required this.likeCount,
    this.replyToPostNumber,
    required this.yours,
    required this.canEdit,
    required this.canDelete,
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int,
        postNumber: json['post_number'] as int? ?? 1,
        username: json['username'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        avatarTemplate: json['avatar_template'] as String? ?? '',
        cooked: json['cooked'] as String? ?? '',
        raw: json['raw'] as String? ?? '',
        createdAt: json['created_at'] as String?,
        likeCount: json['like_count'] as int? ?? 0,
        replyToPostNumber: json['reply_to_post_number'] as int?,
        yours: json['yours'] as bool? ?? false,
        canEdit: json['can_edit'] as bool? ?? false,
        canDelete: json['can_delete'] as bool? ?? false,
      );
}

class TopicDetail {
  final int id;
  final String title;
  final int postsCount;
  final int replyCount;
  final int views;
  final int likeCount;
  final String? createdAt;
  final bool closed;
  final int? categoryId;
  final List<Post> posts;

  const TopicDetail({
    required this.id,
    required this.title,
    required this.postsCount,
    required this.replyCount,
    required this.views,
    required this.likeCount,
    this.createdAt,
    required this.closed,
    this.categoryId,
    required this.posts,
  });

  factory TopicDetail.fromJson(Map<String, dynamic> json) => TopicDetail(
        id: json['id'] as int,
        title: json['title'] as String,
        postsCount: json['posts_count'] as int? ?? 0,
        replyCount: json['reply_count'] as int? ?? 0,
        views: json['views'] as int? ?? 0,
        likeCount: json['like_count'] as int? ?? 0,
        createdAt: json['created_at'] as String?,
        closed: json['closed'] as bool? ?? false,
        categoryId: json['category_id'] as int?,
        posts: (json['posts'] as List<dynamic>? ?? [])
            .map((p) => Post.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
