// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_chapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoryChapterAdapter extends TypeAdapter<StoryChapter> {
  @override
  final int typeId = 204;

  @override
  StoryChapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoryChapter(
      id: fields[0] as String?,
      bookId: fields[1] as String,
      chapterNumber: fields[2] as int,
      title: fields[3] as String,
      content: fields[4] as String,
      summary: fields[5] as String?,
      readingTime: fields[6] as int?,
      wordCount: fields[7] as int?,
      isCompleted: fields[8] as bool,
      lastReadPosition: fields[9] as int?,
      progressPercent: fields[10] as double?,
      lastReadAt: fields[11] as DateTime?,
      createdAt: fields[12] as DateTime?,
      updatedAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StoryChapter obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bookId)
      ..writeByte(2)
      ..write(obj.chapterNumber)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.summary)
      ..writeByte(6)
      ..write(obj.readingTime)
      ..writeByte(7)
      ..write(obj.wordCount)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.lastReadPosition)
      ..writeByte(10)
      ..write(obj.progressPercent)
      ..writeByte(11)
      ..write(obj.lastReadAt)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryChapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryChapter _$StoryChapterFromJson(Map<String, dynamic> json) => StoryChapter(
      id: json['id'] as String?,
      bookId: json['bookId'] as String,
      chapterNumber: (json['chapterNumber'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      readingTime: (json['readingTime'] as num?)?.toInt(),
      wordCount: (json['wordCount'] as num?)?.toInt(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      lastReadPosition: (json['lastReadPosition'] as num?)?.toInt(),
      progressPercent: (json['progressPercent'] as num?)?.toDouble(),
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$StoryChapterToJson(StoryChapter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookId': instance.bookId,
      'chapterNumber': instance.chapterNumber,
      'title': instance.title,
      'content': instance.content,
      'summary': instance.summary,
      'readingTime': instance.readingTime,
      'wordCount': instance.wordCount,
      'isCompleted': instance.isCompleted,
      'lastReadPosition': instance.lastReadPosition,
      'progressPercent': instance.progressPercent,
      'lastReadAt': instance.lastReadAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
