class ReportModel {
  final int reportId;
  final String uid;
  final String username;
  final String email;
  final String reportDetail;
  final String createdAt;

  ReportModel({
    required this.reportId,
    required this.uid,
    required this.username,
    required this.email,
    required this.reportDetail,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['report_id'] ?? 0,
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      reportDetail: json['report_detail'] ?? '',
      createdAt: json['create_at'] ?? '',
    );
  }
}
