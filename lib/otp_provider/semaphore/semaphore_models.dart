/// Data models for Semaphore SMS API responses and requests.
///
/// Semaphore returns message data in a specific format. These models
/// handle parsing the JSON responses and provide safe serialization
/// that excludes sensitive data like OTP codes from logs.
///
/// API Documentation: https://semaphore.co/docs
library;

/// Represents a single SMS message in Semaphore's response.
///
/// When you send an OTP via Semaphore, you get back an array of these
/// message objects. Each contains details about the sent message including
/// the generated OTP code.
class SemaphoreMessage {
  /// Unique identifier for this message from Semaphore
  final int messageId;

  /// User ID associated with the Semaphore account
  final int userId;

  /// Email/username of the Semaphore account
  final String user;

  /// Account ID from Semaphore
  final int accountId;

  /// Account name/label from Semaphore
  final String account;

  /// Phone number that received the message (e.g., "639171234567")
  final String recipient;

  /// The actual SMS message that was sent to the user
  final String message;

  /// The OTP code that was generated/sent (SENSITIVE - never log this)
  final dynamic code; // Can be int or string depending on provider response

  /// Sender name displayed to recipient
  final String senderName;

  /// Mobile network (e.g., "Globe", "Smart", "Sun")
  final String network;

  /// Message status (e.g., "Pending", "Sent", "Delivered", "Failed")
  final String status;

  /// Message type (e.g., "Single", "Bulk")
  final String type;

  /// Source of the message (e.g., "Api", "Dashboard")
  final String source;

  /// When the message was created (ISO format)
  final String createdAt;

  /// When the message was last updated
  final String updatedAt;

  SemaphoreMessage({
    required this.messageId,
    required this.userId,
    required this.user,
    required this.accountId,
    required this.account,
    required this.recipient,
    required this.message,
    required this.code,
    required this.senderName,
    required this.network,
    required this.status,
    required this.type,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse a Semaphore message from JSON response
  factory SemaphoreMessage.fromJson(Map<String, dynamic> json) {
    return SemaphoreMessage(
      messageId: _parseInt(json['message_id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      user: json['user']?.toString() ?? '',
      accountId: _parseInt(json['account_id']) ?? 0,
      account: json['account']?.toString() ?? '',
      recipient: json['recipient']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      code: json['code'], // Keep original type (int or string)
      senderName: json['sender_name']?.toString() ?? '',
      network: json['network']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  /// Convert to JSON for safe logging (excludes sensitive data)
  Map<String, dynamic> toJson({bool redactSensitive = true}) => {
        'message_id': messageId,
        'user_id': userId,
        'user': user,
        'account_id': accountId,
        'account': account,
        'recipient': recipient,
        'message': redactSensitive ? _redactMessage(message) : message,
        'code': redactSensitive ? '••••' : code, // Always redact OTP in logs
        'sender_name': senderName,
        'network': network,
        'status': status,
        'type': type,
        'source': source,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// Get the OTP code as a string (for verification)
  String get codeAsString => code?.toString() ?? '';

  /// Redact sensitive information from message content
  static String _redactMessage(String msg) {
    // Replace sequences of 4+ digits with bullets
    return msg.replaceAll(RegExp(r'\d{4,}'), '••••');
  }

  /// Helper to safely parse integers from JSON
  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Response wrapper for Semaphore OTP send requests.
///
/// Semaphore returns an array of message objects. This class wraps
/// that array and provides convenient access to the first message
/// and its OTP code.
class SemaphoreSendResponse {
  /// List of messages returned by Semaphore (usually just one for OTP)
  final List<SemaphoreMessage> messages;

  /// Raw response from Semaphore API (for debugging)
  final dynamic rawResponse;

  SemaphoreSendResponse({
    required this.messages,
    this.rawResponse,
  });

  /// Parse response from Semaphore API
  factory SemaphoreSendResponse.fromJson(dynamic json) {
    List<SemaphoreMessage> messages = [];

    if (json is List) {
      // Standard Semaphore response is an array of messages
      messages = json
          .where((item) => item is Map<String, dynamic>)
          .map((item) =>
              SemaphoreMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } else if (json is Map<String, dynamic>) {
      // Handle single message wrapped in object
      if (json.containsKey('messages') && json['messages'] is List) {
        messages = (json['messages'] as List)
            .where((item) => item is Map<String, dynamic>)
            .map((item) =>
                SemaphoreMessage.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        // Single message object
        messages = [SemaphoreMessage.fromJson(json)];
      }
    }

    return SemaphoreSendResponse(
      messages: messages,
      rawResponse: json,
    );
  }

  /// Get the first message (most common case for OTP)
  SemaphoreMessage? get firstMessage =>
      messages.isNotEmpty ? messages.first : null;

  /// Get the OTP code from the first message
  String? get otpCode => firstMessage?.codeAsString;

  /// Check if the send was successful
  bool get isSuccess =>
      messages.isNotEmpty &&
      messages.any((msg) => msg.status.toLowerCase() != 'failed');

  /// Get success/error message for display
  String get statusMessage {
    if (messages.isEmpty) return 'No messages in response';
    final first = messages.first;
    return 'Message ${first.status.toLowerCase()} to ${first.recipient}';
  }

  /// Convert to JSON for safe logging
  Map<String, dynamic> toJson({bool redactSensitive = true}) => {
        'messages': messages
            .map((msg) => msg.toJson(redactSensitive: redactSensitive))
            .toList(),
        'message_count': messages.length,
        'is_success': isSuccess,
        'status_message': statusMessage,
        // rawResponse excluded to prevent accidental logging
      };
}
