// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 202;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      email: fields[1] as String,
      ownedBooks: (fields[2] as List).cast<String>(),
      progress: (fields[3] as Map).cast<String, double>(),
      customBookIds: (fields[4] as List).cast<String>(),
      recentBookIds: (fields[5] as List).cast<String>(),
      favoriteBookIds: (fields[6] as List).cast<String>(),
      streak: fields[7] as int,
      lastActiveDate: fields[8] as DateTime?,
      totalXP: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.ownedBooks)
      ..writeByte(3)
      ..write(obj.progress)
      ..writeByte(4)
      ..write(obj.customBookIds)
      ..writeByte(5)
      ..write(obj.recentBookIds)
      ..writeByte(6)
      ..write(obj.favoriteBookIds)
      ..writeByte(7)
      ..write(obj.streak)
      ..writeByte(8)
      ..write(obj.lastActiveDate)
      ..writeByte(9)
      ..write(obj.totalXP);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
