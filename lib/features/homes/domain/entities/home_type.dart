enum HomeType {
  family('family', 'عائلة'),
  couple('couple', 'زوجان'),
  sharedHouse('shared_house', 'سكن مشترك'),
  studentHousing('student_housing', 'سكن طلاب'),
  singleUser('single_user', 'مستخدم فردي'),
  office('office', 'مكتب');

  final String value;
  final String arabicName;

  const HomeType(this.value, this.arabicName);

  String get translationKey => 'home_type_$value';

  static HomeType fromValue(String value) {
    return HomeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => HomeType.family,
    );
  }

  static List<HomeType> get allValues => HomeType.values;
}
