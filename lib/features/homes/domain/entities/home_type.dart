enum HomeType {
  family('family'),
  couple('couple'),
  sharedHouse('shared_house'),
  studentHousing('student_housing'),
  singleUser('single_user'),
  office('office');

  final String value;

  const HomeType(this.value);

  String get translationKey => 'home_type_$value';

  @Deprecated('Use translationKey with context.translate() instead')
  String get arabicName => translationKey;

  static HomeType fromValue(String value) {
    return HomeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => HomeType.family,
    );
  }

  static List<HomeType> get allValues => HomeType.values;
}
