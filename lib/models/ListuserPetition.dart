class PetitionItem {
  final String target;
  final String reason;
  final DateTime createAt;
  final String actionBy;
  final int actionId;

  PetitionItem({
    required this.target,
    required this.reason,
    required this.createAt,
    required this.actionBy,
    required this.actionId,
  });

  factory PetitionItem.fromJson(Map<String, dynamic> j) => PetitionItem(
        target: j['target'] as String,
        reason: j['reason'] as String,
        createAt: DateTime.parse(j['create_at'] as String),
        actionBy: (j['action_by'] ?? '') as String,
        actionId: (j['action_id'] ?? 0) as int,
      );
}
