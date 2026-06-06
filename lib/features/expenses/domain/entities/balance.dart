class Balance {
  final String memberA;
  final String memberB;
  final int netAmount; // cents, positive means memberA owes memberB

  const Balance({
    required this.memberA,
    required this.memberB,
    required this.netAmount,
  });

  bool get isSettled => netAmount == 0;
  bool get memberAOwes => netAmount > 0;
  bool get memberBOwes => netAmount < 0;

  int get absoluteAmount => netAmount.abs();

  String getDebtor() => netAmount > 0 ? memberA : memberB;
  String getCreditor() => netAmount > 0 ? memberB : memberA;

  Balance copyWith({String? memberA, String? memberB, int? netAmount}) {
    return Balance(
      memberA: memberA ?? this.memberA,
      memberB: memberB ?? this.memberB,
      netAmount: netAmount ?? this.netAmount,
    );
  }
}
