import 'package:flutter/material.dart';

class SudutInfoPost {
  const SudutInfoPost({
    required this.id,
    this.authorId,
    this.authorName,
    required this.category,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.managedBy,
    required this.isPublished,
    required this.validFrom,
    this.validUntil,
    required this.createdAt,
  });

  final String id;
  final String? authorId;
  final String? authorName;
  final String category; // 'disiplin', 'kaunseling', 'sahsiah', 'sekolah', 'umum'
  final String title;
  final String content;
  final String? imageUrl;
  final String managedBy;
  final bool isPublished;
  final DateTime validFrom;
  final DateTime? validUntil;
  final DateTime createdAt;

  bool get isCurrentlyActive {
    final now = DateTime.now();
    if (!isPublished) return false;
    if (validFrom.isAfter(now)) return false;
    if (validUntil != null && validUntil!.isBefore(now)) return false;
    return true;
  }

  bool get isScheduled {
    final now = DateTime.now();
    return isPublished && validFrom.isAfter(now);
  }

  bool get isExpired {
    final now = DateTime.now();
    return isPublished && validUntil != null && validUntil!.isBefore(now);
  }

  String get statusLabel {
    if (!isPublished) return 'NYAHTERBIT / DRAF';
    final now = DateTime.now();
    if (validFrom.isAfter(now)) return 'DIJADUALKAN';
    if (validUntil != null && validUntil!.isBefore(now)) return 'TAMAT TEMPOH';
    return 'AKTIF (LIVE)';
  }

  Color get statusColor {
    if (!isPublished) return Colors.grey.shade700;
    final now = DateTime.now();
    if (validFrom.isAfter(now)) return Colors.amber.shade900;
    if (validUntil != null && validUntil!.isBefore(now)) return Colors.red.shade800;
    return Colors.green.shade800;
  }

  factory SudutInfoPost.fromMap(Map<String, dynamic> map) {
    String? author;
    final prof = map['profiles'];
    if (prof is Map<String, dynamic>) {
      author = prof['full_name'] as String?;
    } else if (map['author_name'] != null) {
      author = map['author_name'] as String?;
    }

    return SudutInfoPost(
      id: map['id'] as String,
      authorId: map['author_id'] as String?,
      authorName: author,
      category: map['category'] as String? ?? 'umum',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      managedBy: map['managed_by'] as String? ?? 'Unit Disiplin & Kaunseling',
      isPublished: map['is_published'] as bool? ?? true,
      validFrom: map['valid_from'] != null
          ? DateTime.parse(map['valid_from'] as String).toLocal()
          : DateTime.now(),
      validUntil: map['valid_until'] != null
          ? DateTime.parse(map['valid_until'] as String).toLocal()
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }
}
