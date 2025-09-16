class ActivityMaster {
  final String actId;
  final String actName;
  final String iconPath;

  ActivityMaster({
    required this.actId,
    required this.actName,
    required this.iconPath,
  });

  factory ActivityMaster.fromJson(Map<String, dynamic> json) {
    return ActivityMaster(
      actId: json['act_id']?.toString() ?? '',
      actName: json['act_name'] ?? '',
      iconPath: json['act_pic'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'act_id': actId,
      'act_name': actName,
      'act_pic': iconPath,
    };
  }
}