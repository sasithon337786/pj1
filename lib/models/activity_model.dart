class Activity {
  final String actDetailId;
  final String actName;
  final String iconPath;
  final double goal;
  final String unit;
  final double currentValue;
  final String displayText;
  final bool isCompleted;

  Activity({
    required this.actDetailId,
    required this.actName,
    required this.iconPath,
    required this.goal,
    required this.unit,
    required this.currentValue,
    required this.displayText,
    required this.isCompleted,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    String _fmt(num n) => (n % 1 == 0) ? n.toInt().toString() : n.toString();
    
    final unit = (json['unit'] ?? json['goal_unit'] ?? json['act_unit'] ?? '').toString();
    
    double goalNum = 0;
    final rawGoal = json['goal'];
    if (rawGoal is num) goalNum = rawGoal.toDouble();
    if (rawGoal is String) goalNum = double.tryParse(rawGoal) ?? 0;

    double currentNum = 0;
    final rawCurrent = json['current_value'];
    if (rawCurrent is num) currentNum = rawCurrent.toDouble();
    if (rawCurrent is String) currentNum = double.tryParse(rawCurrent) ?? 0;

    final bool isCompleted = goalNum > 0 && currentNum >= goalNum;
    final String displayText = isCompleted
        ? 'ทำเสร็จแล้ว'
        : '${_fmt(currentNum)}/${_fmt(goalNum)}${unit.isNotEmpty ? ' $unit' : ''}';

    return Activity(
      actDetailId: json['act_detail_id']?.toString() ?? '',
      actName: json['act_name'] ?? 'Unknown Activity',
      iconPath: json['icon_path'] ?? '',
      goal: goalNum,
      unit: unit,
      currentValue: currentNum,
      displayText: displayText,
      isCompleted: isCompleted,
    );
  }
}