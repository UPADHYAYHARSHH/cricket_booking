enum SplitStatus { pending, settled }

class SplitRequestModel {
  final String? id;
  final String bookingId;
  final String userId;
  final double totalAmount;
  final String? upiId;
  final String? qrCodeUrl;
  final SplitStatus status;
  final DateTime? createdAt;
  final List<SplitMemberModel> members;

  SplitRequestModel({
    this.id,
    required this.bookingId,
    required this.userId,
    required this.totalAmount,
    this.upiId,
    this.qrCodeUrl,
    this.status = SplitStatus.pending,
    this.createdAt,
    this.members = const [],
  });

  factory SplitRequestModel.fromJson(Map<String, dynamic> json) {
    return SplitRequestModel(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user_id'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      upiId: json['upi_id'],
      qrCodeUrl: json['qr_code_url'],
      status: json['status'] == 'settled'
          ? SplitStatus.settled
          : SplitStatus.pending,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      members: (json['split_members'] as List?)
              ?.map((m) => SplitMemberModel.fromJson(m))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'total_amount': totalAmount,
      'upi_id': upiId,
      'qr_code_url': qrCodeUrl,
      'status': status.name,
    };
  }
}

class SplitMemberModel {
  final String? id;
  final String? splitRequestId;
  final String name;
  final double amount;
  final bool isReceived;
  final String? memberUserId;

  SplitMemberModel({
    this.id,
    this.splitRequestId,
    required this.name,
    required this.amount,
    this.isReceived = false,
    this.memberUserId,
  });

  factory SplitMemberModel.fromJson(Map<String, dynamic> json) {
    return SplitMemberModel(
      id: json['id'],
      splitRequestId: json['split_request_id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      isReceived: json['is_received'] ?? false,
      memberUserId: json['member_user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (splitRequestId != null) 'split_request_id': splitRequestId,
      'name': name,
      'amount': amount,
      'is_received': isReceived,
      if (memberUserId != null) 'member_user_id': memberUserId,
    };
  }
}
