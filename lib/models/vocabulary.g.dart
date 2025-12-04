// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VocabularyAdapter extends TypeAdapter<Vocabulary> {
  @override
  final int typeId = 100;

  @override
  Vocabulary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vocabulary(
      id: fields[0] as int?,
      word: fields[1] as String,
      pronunciation: fields[2] as String?,
      originLanguage: fields[3] as String,
      targetLanguage: fields[4] as String,
      meaning: fields[5] as String?,
      exampleSentence: fields[6] as String?,
      exampleTranslation: fields[7] as String?,
      ttsAudioPath: fields[8] as String?,
      synonyms: (fields[9] as List?)?.cast<String>(),
      antonyms: (fields[10] as List?)?.cast<String>(),
      tags: (fields[11] as List?)?.cast<String>(),
      difficulty: fields[12] as int?,
      familiarity: fields[13] as double?,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
      isSync: fields[16] as bool,
      isDeleted: fields[17] as bool,
      pos: fields[18] as String?,
      frequencyRank: fields[19] as int?,
      sourceList: fields[20] as String?,
      relatedWords: (fields[21] as List?)?.cast<String>(),
      userNotes: fields[22] as String?,
      imagePath: fields[23] as String?,
      reviewStatus: fields[24] as String?,
      bookId: fields[25] as String?,
      topic: fields[26] as String?,
      nextReviewDate: fields[27] as DateTime?,
      reviewCount: fields[28] as int?,
      lastReviewedAt: fields[29] as DateTime?,
      easeFactor: fields[30] as double?,
      interval: fields[31] as int?,
      orderIndex: fields[32] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Vocabulary obj) {
    writer
      ..writeByte(33)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.word)
      ..writeByte(2)
      ..write(obj.pronunciation)
      ..writeByte(3)
      ..write(obj.originLanguage)
      ..writeByte(4)
      ..write(obj.targetLanguage)
      ..writeByte(5)
      ..write(obj.meaning)
      ..writeByte(6)
      ..write(obj.exampleSentence)
      ..writeByte(7)
      ..write(obj.exampleTranslation)
      ..writeByte(8)
      ..write(obj.ttsAudioPath)
      ..writeByte(9)
      ..write(obj.synonyms)
      ..writeByte(10)
      ..write(obj.antonyms)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.difficulty)
      ..writeByte(13)
      ..write(obj.familiarity)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.isSync)
      ..writeByte(17)
      ..write(obj.isDeleted)
      ..writeByte(18)
      ..write(obj.pos)
      ..writeByte(19)
      ..write(obj.frequencyRank)
      ..writeByte(20)
      ..write(obj.sourceList)
      ..writeByte(21)
      ..write(obj.relatedWords)
      ..writeByte(22)
      ..write(obj.userNotes)
      ..writeByte(23)
      ..write(obj.imagePath)
      ..writeByte(24)
      ..write(obj.reviewStatus)
      ..writeByte(25)
      ..write(obj.bookId)
      ..writeByte(26)
      ..write(obj.topic)
      ..writeByte(27)
      ..write(obj.nextReviewDate)
      ..writeByte(28)
      ..write(obj.reviewCount)
      ..writeByte(29)
      ..write(obj.lastReviewedAt)
      ..writeByte(30)
      ..write(obj.easeFactor)
      ..writeByte(31)
      ..write(obj.interval)
      ..writeByte(32)
      ..write(obj.orderIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vocabulary _$VocabularyFromJson(Map<String, dynamic> json) => Vocabulary(
      id: (json['id'] as num?)?.toInt(),
      word: json['word'] as String,
      pronunciation: json['pronunciation'] as String?,
      originLanguage: json['originLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      meaning: json['meaning'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
      exampleTranslation: json['exampleTranslation'] as String?,
      ttsAudioPath: json['ttsAudioPath'] as String?,
      synonyms: (json['synonyms'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      antonyms: (json['antonyms'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      difficulty: (json['difficulty'] as num?)?.toInt(),
      familiarity: (json['familiarity'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSync: json['isSync'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      pos: json['pos'] as String?,
      frequencyRank: (json['frequencyRank'] as num?)?.toInt(),
      sourceList: json['sourceList'] as String?,
      relatedWords: (json['relatedWords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      userNotes: json['userNotes'] as String?,
      imagePath: json['imagePath'] as String?,
      reviewStatus: json['reviewStatus'] as String?,
      bookId: json['bookId'] as String?,
      topic: json['topic'] as String?,
      nextReviewDate: json['nextReviewDate'] == null
          ? null
          : DateTime.parse(json['nextReviewDate'] as String),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      lastReviewedAt: json['lastReviewedAt'] == null
          ? null
          : DateTime.parse(json['lastReviewedAt'] as String),
      easeFactor: (json['easeFactor'] as num?)?.toDouble(),
      interval: (json['interval'] as num?)?.toInt(),
      orderIndex: (json['orderIndex'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VocabularyToJson(Vocabulary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'word': instance.word,
      'pronunciation': instance.pronunciation,
      'originLanguage': instance.originLanguage,
      'targetLanguage': instance.targetLanguage,
      'meaning': instance.meaning,
      'exampleSentence': instance.exampleSentence,
      'exampleTranslation': instance.exampleTranslation,
      'ttsAudioPath': instance.ttsAudioPath,
      'synonyms': instance.synonyms,
      'antonyms': instance.antonyms,
      'tags': instance.tags,
      'difficulty': instance.difficulty,
      'familiarity': instance.familiarity,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isSync': instance.isSync,
      'isDeleted': instance.isDeleted,
      'pos': instance.pos,
      'frequencyRank': instance.frequencyRank,
      'sourceList': instance.sourceList,
      'relatedWords': instance.relatedWords,
      'userNotes': instance.userNotes,
      'imagePath': instance.imagePath,
      'reviewStatus': instance.reviewStatus,
      'bookId': instance.bookId,
      'topic': instance.topic,
      'nextReviewDate': instance.nextReviewDate?.toIso8601String(),
      'reviewCount': instance.reviewCount,
      'lastReviewedAt': instance.lastReviewedAt?.toIso8601String(),
      'easeFactor': instance.easeFactor,
      'interval': instance.interval,
      'orderIndex': instance.orderIndex,
    };
