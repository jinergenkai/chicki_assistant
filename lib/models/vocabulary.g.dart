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
    );
  }

  @override
  void write(BinaryWriter writer, Vocabulary obj) {
    writer
      ..writeByte(18)
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
      ..write(obj.isDeleted);
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
