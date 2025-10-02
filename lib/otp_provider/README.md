# OTP Provider System

This module provides a unified interface for sending and verifying One-Time Passwords (OTPs) through different SMS providers. Currently supports Semaphore SMS Philippines, with easy extensibility for other providers.

## Features

- **Unified Interface**: Switch between SMS providers without changing your app code
- **Secure**: Automatic redaction of sensitive data in logs, secure OTP storage and verification  
- **Flexible**: Support for custom OTP codes or auto-generated ones
- **Resilient**: Proper error handling, timeouts, and retry logic
- **Testable**: Easy mocking for unit tests

## Quick Start

1. **Set up environment variables** in your `gemini.env` or `.env` file:
```env
SEMAPHORE_API=your_semaphore_api_key_here
OTP_PROVIDER=semaphore
```

2. **Load environment in your app** (usually in `main.dart`):
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: "gemini.env");
  runApp(MyApp());
}
```

3. **Send an OTP**:
```dart
import 'otp_provider/otp_provider_factory.dart';

// Create provider from environment config
final otpProvider = OtpProviderFactory.createFromEnvironment();

// Send OTP (user enters phone number in your UI)
final result = await otpProvider.sendOtp(
  phone: userEnteredPhoneNumber, // e.g., '+639171234567'
  message: 'Your Campus Safe login code is {otp}. Valid for 5 minutes.',
);

if (result.success) {
  print('OTP sent successfully!');
  // Store the OTP code for verification (result.code)
} else {
  print('Failed to send OTP: ${result.message}');
}
```

4. **Verify OTP** (using local verification since Semaphore doesn't provide verify endpoint):
```dart
import 'otp_provider/local_verifier.dart';

final verifier = LocalOtpVerifier();

// Store OTP when sending (in your send OTP function)
await verifier.storeOtp(
  phone: userPhone,
  code: result.code!, // OTP from send result
  ttlSeconds: 300, // 5 minutes
);

// Later, verify when user submits OTP
final verifyResult = await verifier.verifyOtp(
  phone: userPhone,
  code: userEnteredOtp,
);

if (verifyResult.verified) {
  print('OTP verified! User can proceed.');
} else {
  print('Invalid OTP: ${verifyResult.message}');
}
```

## File Structure

```
lib/otp_provider/
├── README.md                           # This file
├── otp_provider.dart                   # Abstract interface
├── otp_provider_factory.dart           # Provider factory
├── local_verifier.dart                 # Local OTP verification
└── semaphore/
    ├── semaphore_client.dart           # Semaphore SMS implementation
    └── semaphore_models.dart           # Request/response models
```

## Available Providers

### Semaphore SMS Philippines

**Setup:**
- Get API key from [semaphore.co](https://semaphore.co)
- Add to `gemini.env`: `SEMAPHORE_API=your_api_key`

**Features:**
- Dedicated OTP endpoint (better delivery rates)
- Auto-generated or custom OTP codes
- Philippine number format handling
- 2 credits per 160-character SMS

**Limitations:**
- No server-side verification endpoint
- Must use `LocalVerifier` for OTP verification

## Phone Number Format

The system automatically handles Philippine phone number formats:

```dart
// These all get normalized to +639171234567
'+639171234567'  // International format (preferred)  
'639171234567'   // Without + prefix
'09171234567'    // Local format (converted to +63)
'0917 123 4567'  // With spaces (cleaned)
```

## Security Considerations

### Safe Logging
- OTP codes are automatically redacted from logs
- Only safe metadata is logged (success/failure, message IDs)
- Debug logging only active in debug mode

### OTP Storage
- OTPs are hashed before storage (never stored in plaintext)
- Automatic expiry and cleanup
- Protection against brute force attacks (max 5 attempts)
- Constant-time comparison prevents timing attacks

### Best Practices
- **Never hardcode API keys** - always use environment variables
- **Validate phone numbers** - use international format
- **Set reasonable TTL** - 5 minutes is recommended for OTPs
- **Rate limit sends** - prevent SMS spam to users
- **Use HTTPS** - for all API communications

## Error Handling

```dart
try {
  final result = await provider.sendOtp(
    phone: phone,
    message: message,
  );
  
  if (!result.success) {
    // Handle provider-level errors (API issues, invalid phone, etc.)
    showError('Failed to send OTP: ${result.message}');
  }
} catch (e) {
  if (e is ProviderException) {
    // Network errors, API failures
    showError('SMS service error: ${e.message}');
  } else {
    // Other errors (validation, etc.)
    showError('Unexpected error: $e');
  }
}
```

## Testing

### Unit Tests
```dart
// Mock the provider for testing
final mockProvider = MockOtpProvider();
when(mockProvider.sendOtp(any)).thenAnswer((_) async => SendResult(
  success: true,
  message: 'Mock OTP sent',
  code: '123456',
));

final provider = OtpProviderFactory.createMockProvider(mockProvider);
```

### Integration Tests
```dart
// Test with real provider in test environment
final provider = OtpProviderFactory.createSemaphoreProvider(
  apiKey: 'test_api_key'
);
```

## Configuration Validation

Check your setup before using:

```dart
final validation = OtpProviderFactory.validateConfiguration('semaphore');
if (!validation.isValid) {
  print('Configuration error: ${validation.message}');
  // Handle missing API keys, invalid config, etc.
}
```

## Extending to Other Providers

To add a new SMS provider:

1. **Create client class** implementing `OtpProvider`:
```dart
class MyProviderClient implements OtpProvider {
  @override
  Future<SendResult> sendOtp({...}) async {
    // Implementation
  }
  
  @override  
  Future<VerifyResult> verifyOtp({...}) async {
    // Implementation
  }
}
```

2. **Add to factory**:
```dart
// In otp_provider_factory.dart
case 'myprovider':
  return MyProviderClient(apiKey: _getApiKeyFromEnv('MYPROVIDER_API'));
```

3. **Update supported providers list**:
```dart
static List<String> get supportedProviders => ['semaphore', 'myprovider'];
```

## Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|  
| `SEMAPHORE_API` | Yes | Semaphore API key | `f9bf9f2b232c9b8aa1c16f305066642d` |
| `OTP_PROVIDER` | No | Provider to use | `semaphore` (default) |

## Troubleshooting

### "API key is required" error
- Check `SEMAPHORE_API` is set in your `.env` file
- Ensure `dotenv.load()` is called before using the provider
- Verify the API key is correct (should be 32+ characters)

### "Failed to send OTP" errors  
- Check your Semaphore account balance
- Verify phone number format (should include country code)
- Check network connectivity
- Review error details in `result.message`

### OTP verification always fails
- Ensure you're using `LocalVerifier` for Semaphore
- Check that OTP was stored after successful send
- Verify phone numbers match exactly (formatting)
- Check if OTP has expired (default: 5 minutes)

### Phone number format issues
- Use international format: `+639171234567`  
- Avoid special characters except `+`
- The system auto-converts Philippine local format (`09xx`) to international

---

## Support

For issues related to:
- **Semaphore API**: Contact [Semaphore support](https://semaphore.co/contact)
- **This module**: Check error messages and logs, ensure proper configuration