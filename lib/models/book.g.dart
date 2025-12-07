// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 200;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      price: fields[3] as double,
      isCustom: fields[4] as bool,
      ownerId: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      lastOpenedAt: fields[8] as DateTime?,
      version: fields[9] as String?,
      isPublic: fields[10] as bool,
      coverImagePath: fields[11] as String?,
      author: fields[12] as String?,
      category: fields[13] as String?,
      jsonHash: fields[14] as String?,
      source: fields[15] == null
          ? BookSource.userCreated
          : fields[15] as BookSource?,
      originalOwnerId: fields[16] as String?,
      type: fields[17] == null ? BookType.flashBook : fields[17] as BookType,
      typeConfig: (fields[18] as Map?)?.cast<String, dynamic>(),
      coverId: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.isCustom)
      ..writeByte(5)
      ..write(obj.ownerId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.lastOpenedAt)
      ..writeByte(9)
      ..write(obj.version)
      ..writeByte(10)
      ..write(obj.isPublic)
      ..writeByte(11)
      ..write(obj.coverImagePath)
      ..writeByte(12)
      ..write(obj.author)
      ..writeByte(13)
      ..write(obj.category)
      ..writeByte(14)
      ..write(obj.jsonHash)
      ..writeByte(15)
      ..write(obj.source)
      ..writeByte(16)
      ..write(obj.originalOwnerId)
      ..writeByte(17)
      ..write(obj.type)
      ..writeByte(18)
      ..write(obj.typeConfig)
      ..writeByte(19)
      ..write(obj.coverId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookSourceAdapter extends TypeAdapter<BookSource> {
  @override
  final int typeId = 201;

  @override
  BookSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BookSource.statics;
      case 1:
        return BookSource.userCreated;
      case 2:
        return BookSource.imported;
      default:
        return BookSource.statics;
    }
  }

  @override
  void write(BinaryWriter writer, BookSource obj) {
    switch (obj) {
      case BookSource.statics:
        writer.writeByte(0);
        break;
      case BookSource.userCreated:
        writer.writeByte(1);
        break;
      case BookSource.imported:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookTypeAdapter extends TypeAdapter<BookType> {
  @override
  final int typeId = 202;

  @override
  BookType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BookType.flashBook;
      case 1:
        return BookType.journal;
      case 2:
        return BookType.story;
      default:
        return BookType.flashBook;
    }
  }

  @override
  void write(BinaryWriter writer, BookType obj) {
    switch (obj) {
      case BookType.flashBook:
        writer.writeByte(0);
        break;
      case BookType.journal:
        writer.writeByte(1);
        break;
      case BookType.story:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      isCustom: json['isCustom'] as bool,
      ownerId: json['ownerId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      lastOpenedAt: json['lastOpenedAt'] == null
          ? null
          : DateTime.parse(json['lastOpenedAt'] as String),
      version: json['version'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      coverImagePath: json['coverImagePath'] as String?,
      author: json['author'] as String?,
      category: json['category'] as String?,
      jsonHash: json['jsonHash'] as String?,
      source: $enumDecodeNullable(_$BookSourceEnumMap, json['source']) ??
          BookSource.userCreated,
      originalOwnerId: json['originalOwnerId'] as String?,
      type: $enumDecodeNullable(_$BookTypeEnumMap, json['type']) ??
          BookType.flashBook,
      typeConfig: json['typeConfig'] as Map<String, dynamic>?,
      coverId: json['coverId'] as String?,
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'isCustom': instance.isCustom,
      'ownerId': instance.ownerId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'lastOpenedAt': instance.lastOpenedAt?.toIso8601String(),
      'version': instance.version,
      'isPublic': instance.isPublic,
      'coverImagePath': instance.coverImagePath,
      'author': instance.author,
      'category': instance.category,
      'jsonHash': instance.jsonHash,
      'source': _$BookSourceEnumMap[instance.source]!,
      'originalOwnerId': instance.originalOwnerId,
      'type': _$BookTypeEnumMap[instance.type]!,
      'typeConfig': instance.typeConfig,
      'coverId': instance.coverId,
    };

const _$BookSourceEnumMap = {
  BookSource.statics: 'statics',
  BookSource.userCreated: 'userCreated',
  BookSource.imported: 'imported',
};

const _$BookTypeEnumMap = {
  BookType.flashBook: 'flashBook',
  BookType.journal: 'journal',
  BookType.story: 'story',
};
