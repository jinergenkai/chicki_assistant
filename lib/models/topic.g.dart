// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TopicAdapter extends TypeAdapter<Topic> {
  @override
  final int typeId = 201;

  @override
  Topic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Topic(
      id: fields[0] as String,
      title: fields[1] as String,
      vocabIds: (fields[2] as List).cast<String>(),
      bookId: fields[3] as String,
      createdAt: fields[4] as DateTime?,
      orderIndex: fields[5] as int?,
      description: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Topic obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.vocabIds)
      ..writeByte(3)
      ..write(obj.bookId)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.orderIndex)
      ..writeByte(6)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Topic _$TopicFromJson(Map<String, dynamic> json) => Topic(
      id: json['id'] as String,
      title: json['title'] as String,
      vocabIds:
          (json['vocabIds'] as List<dynamic>).map((e) => e as String).toList(),
      bookId: json['bookId'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      orderIndex: (json['orderIndex'] as num?)?.toInt(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$TopicToJson(Topic instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'vocabIds': instance.vocabIds,
      'bookId': instance.bookId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'orderIndex': instance.orderIndex,
      'description': instance.description,
    };
