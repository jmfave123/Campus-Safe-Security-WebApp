// Models for SMSCHEF API responses
class SmsChefSendData {
  final String phone;
  final String message;
  final int? otp; // present in sample responses; treat as sensitive

  SmsChefSendData({required this.phone, required this.message, this.otp});

  factory SmsChefSendData.fromJson(Map<String, dynamic> json) {
    return SmsChefSendData(
      phone: json['phone']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      otp: json.containsKey('otp')
          ? (json['otp'] is int
              ? json['otp'] as int
              : int.tryParse(json['otp'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson({bool redactSensitive = false}) => {
        'phone': phone,
        'message': redactSensitive ? _redactMessage(message) : message,
        'otp': redactSensitive ? null : otp,
      };

  static String _redactMessage(String msg) {
    // Simple redact: replace digits sequences of length >=4 with '••••'
    return msg.replaceAll(RegExp(r'\d{4,}'), '••••');
  }
}

class SmsChefSendResponse {
  final int status;
  final String message;
  final SmsChefSendData? data;

  SmsChefSendResponse({required this.status, required this.message, this.data});

  factory SmsChefSendResponse.fromJson(Map<String, dynamic> json) {
    return SmsChefSendResponse(
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? SmsChefSendData.fromJson(Map<String, dynamic>.from(json['data']))
          : null,
    );
  }

  Map<String, dynamic> toJson({bool redactSensitive = true}) => {
        'status': status,
        'message': message,
        'data': data?.toJson(redactSensitive: redactSensitive),
      };
}

class SmsChefVerifyResponse {
  final int status;
  final String message;
  final dynamic data; // can be boolean or other payload per API

  SmsChefVerifyResponse(
      {required this.status, required this.message, this.data});

  factory SmsChefVerifyResponse.fromJson(Map<String, dynamic> json) {
    return SmsChefVerifyResponse(
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? '',
      data: json['data'],
    );
  }

  bool get verified => data == true;

  // Some servers may respond with a non-true `data` but include a message
  // such as "already verified". Treat common variants of that message as
  // indicating the OTP is effectively verified so the UI can proceed.
  bool get verifiedLoosely {
    if (verified) return true;
    final msg = message.toLowerCase();
    if (msg.isEmpty) return false;
    // Negative keywords that indicate failure or negation
    final negative = [
      'not',
      "n't",
      'failed',
      'invalid',
      'expired',
      'incorrect',
      'wrong',
      'no',
      'unverified'
    ];
    for (final n in negative) {
      if (msg.contains(n)) return false;
    }

    // If the message contains 'verified' or 'success' or 'already' or 'used',
    // treat it as a successful/accepted verification state.
    final positive = [
      'verified',
      'success',
      'already',
      'used',
      'done',
      'has been verified',
      'has verified'
    ];
    for (final p in positive) {
      if (msg.contains(p)) return true;
    }

    return false;
  }
}
