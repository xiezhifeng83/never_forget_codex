class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.deviceToken,
    required this.createdAt,
    required this.updatedAt,
    required this.lastWriteAt,
    required this.revision,
    this.deleted = false,
  });

  final String id;
  final String title;
  final int orderIndex;
  final String deviceToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastWriteAt;
  final int revision;
  final bool deleted;

  bool get isActive => !deleted;

  Todo copyWith({
    String? title,
    int? orderIndex,
    String? deviceToken,
    DateTime? updatedAt,
    DateTime? lastWriteAt,
    int? revision,
    bool? deleted,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      deviceToken: deviceToken ?? this.deviceToken,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastWriteAt: lastWriteAt ?? this.lastWriteAt,
      revision: revision ?? this.revision,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'orderIndex': orderIndex,
      'deviceToken': deviceToken,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastWriteAt': lastWriteAt.toIso8601String(),
      'revision': revision,
      'deleted': deleted,
    };
  }

  static Todo fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      orderIndex: json['orderIndex'] as int? ?? 0,
      deviceToken: json['deviceToken'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastWriteAt: DateTime.parse(json['lastWriteAt'] as String? ?? json['updatedAt'] as String),
      revision: json['revision'] as int? ?? 0,
      deleted: json['deleted'] as bool? ?? false,
    );
  }
}
