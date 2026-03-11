import 'dart:ffi';

abstract class RatingValue {
  const RatingValue();
  String get typeKey; // 'b'- bool 'n' - number 'e' - enum
  Map<String, dynamic> toJson();

  static RatingValue fromJson(Map<String, dynamic> json){

    switch (json['t']) {
      case 'b': return BoolValue(json['v'] as bool? ?? false);
      case 'n':
        final v = json['v'];
        if (v is int) return NumberValue(v);
        if (v is double) return NumberValue(v);
        if (v is num) return NumberValue(v);
        return const NumberValue(0);
      case 'e': return EnumValue(json['v'] as String? ?? '');
      default: throw ArgumentError('Unknown RatingValue type: ${json['t']}');
    }

  }
}

class BoolValue extends RatingValue {
  final bool value;
  const BoolValue(this.value);
  @override String get  typeKey => 'b';
  @override Map<String, dynamic> toJson() => {'t': typeKey, 'v': value};
}


class NumberValue extends RatingValue {
  final num value;
  const NumberValue(this.value);
  @override String get typeKey => 'n';
  @override Map<String, dynamic> toJson() => {'t': typeKey, 'v': value};
}

class EnumValue extends RatingValue {
  final String option;
  const EnumValue(this.option);
  @override String get typeKey => 'e';
  @override Map<String, dynamic> toJson() => {'t': typeKey, 'v': option};
}
