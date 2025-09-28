import 'package:hive/hive.dart';

part 'voice_note.g.dart';

@HiveType(typeId: 101)
class VoiceNote extends HiveObject {
  @HiveField(0)
  int? id; // Primary key local

  @HiveField(1)
  String filePath; // Đường dẫn file ghi âm

  @HiveField(2)
  String? title; // optional, tên note

  @HiveField(3)
  String? description; // optional, mô tả thêm

  @HiveField(4)
  DateTime createdAt; // thời gian tạo

  @HiveField(5)
  DateTime updatedAt; // thời gian cập nhật

  @HiveField(6)
  bool isSync; // đã sync server chưa

  @HiveField(7)
  bool isDeleted; // track xóa offline

  VoiceNote({
    this.id,
    required this.filePath,
    this.title,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isSync = false,
    this.isDeleted = false,
  });
}
