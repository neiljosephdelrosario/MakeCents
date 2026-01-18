// GENERATED CODE - MANUALLY WRITTEN FOR YOU

part of 'monthly_summary_model.dart';

class MonthlySummaryModelAdapter extends TypeAdapter<MonthlySummaryModel> {
  @override
  final int typeId = 20;

  @override
  MonthlySummaryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };

    return MonthlySummaryModel(
      monthKey: fields[0] as String,
      income: fields[1] as double,
      expenses: fields[2] as double,
      goalSavings: fields[3] as double,
      net: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlySummaryModel obj) {
    writer
      ..writeByte(5) // number of fields
      ..writeByte(0)
      ..write(obj.monthKey)
      ..writeByte(1)
      ..write(obj.income)
      ..writeByte(2)
      ..write(obj.expenses)
      ..writeByte(3)
      ..write(obj.goalSavings)
      ..writeByte(4)
      ..write(obj.net);
  }
}
