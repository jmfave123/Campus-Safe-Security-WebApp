/// Factory for creating different OTP providers.
///
/// This factory centralizes the creation of OTP providers, making it easy
/// to switch between different SMS services (Semaphore, SmsChef, etc.)
/// based on configuration or environment settings.
///
/// Features:
/// - Environment-based provider selection
/// - Secure API key injection from environment variables
/// - Easy testing with mock providers
/// - Consistent configuration across the app
///
/// Usage:
/// ```dart
/// // Create Semaphore provider using environment variables
/// final provider = OtpProviderFactory.createSemaphoreProvider();
///
/// // Or create with explicit configuration
/// final provider = OtpProviderFactory.createSemaphoreProvider(
///   apiKey: 'your_api_key_here'
/// );
///
/// // Use the provider
/// final result = await provider.sendOtp(
///   phone: '+639171234567',
///   message: 'Your OTP is {otp}'
/// );
/// ```
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'otp_provider.dart';
import 'semaphore/semaphore_client.dart';

/// Factory class for creating OTP providers
class OtpProviderFactory {
  /// Create a Semaphore SMS provider instance.
  ///
  /// [apiKey] - Optional API key. If not provided, will try to load from
  ///           environment variable 'SEMAPHORE_API'
  ///
  /// Returns configured SemaphoreClient instance
  /// Throws ArgumentError if API key is not provided and not found in environment
  static OtpProvider createSemaphoreProvider({String? apiKey}) {
    final key = apiKey ?? _getApiKeyFromEnv('SEMAPHORE_API');

    if (key.isEmpty) {
      throw ArgumentError(
          'Semaphore API key is required. Either pass it as parameter '
          'or set SEMAPHORE_API environment variable.');
    }

    return SemaphoreClient(apiKey: key);
  }

  /// Create provider based on environment configuration.
  ///
  /// Looks for 'OTP_PROVIDER' environment variable to determine which
  /// provider to create. Defaults to 'semaphore' if not specified.
  ///
  /// Supported providers:
  /// - 'semaphore' - Creates SemaphoreClient
  ///
  /// Returns the configured OTP provider
  static OtpProvider createFromEnvironment() {
    final providerType = dotenv.env['OTP_PROVIDER'] ?? 'semaphore';

    switch (providerType.toLowerCase()) {
      case 'semaphore':
        return createSemaphoreProvider();

      default:
        throw ArgumentError('Unsupported OTP provider: $providerType. '
            'Supported providers: semaphore');
    }
  }

  /// Create a provider for testing purposes.
  ///
  /// [mockProvider] - Custom mock provider for testing
  ///
  /// Returns the mock provider (useful for unit tests)
  static OtpProvider createMockProvider(OtpProvider mockProvider) {
    return mockProvider;
  }

  /// Get available provider types
  static List<String> get supportedProviders => ['semaphore'];

  /// Check if a provider type is supported
  static bool isProviderSupported(String providerType) {
    return supportedProviders.contains(providerType.toLowerCase());
  }

  /// Validate provider configuration without creating instance.
  ///
  /// [providerType] - Type of provider to validate ('semaphore', etc.)
  ///
  /// Returns validation result with details
  static ProviderValidationResult validateConfiguration(String providerType) {
    switch (providerType.toLowerCase()) {
      case 'semaphore':
        return _validateSemaphoreConfig();

      default:
        return ProviderValidationResult(
          isValid: false,
          provider: providerType,
          message: 'Unsupported provider type: $providerType',
        );
    }
  }

  /// Get API key from environment variables with validation
  static String _getApiKeyFromEnv(String envVar) {
    final key = dotenv.env[envVar];

    if (key == null || key.trim().isEmpty) {
      return '';
    }

    // Basic validation - API keys should be reasonable length
    if (key.length < 10) {
      throw ArgumentError(
          'API key from $envVar appears to be invalid (too short). '
          'Please check your environment configuration.');
    }

    return key.trim();
  }

  /// Validate Semaphore configuration
  static ProviderValidationResult _validateSemaphoreConfig() {
    try {
      final apiKey = _getApiKeyFromEnv('SEMAPHORE_API');

      if (apiKey.isEmpty) {
        return ProviderValidationResult(
          isValid: false,
          provider: 'semaphore',
          message: 'SEMAPHORE_API environment variable is not set or empty',
          requiredEnvVars: ['SEMAPHORE_API'],
        );
      }

      return ProviderValidationResult(
        isValid: true,
        provider: 'semaphore',
        message: 'Semaphore configuration is valid',
        apiKeyPresent: true,
      );
    } catch (e) {
      return ProviderValidationResult(
        isValid: false,
        provider: 'semaphore',
        message: 'Semaphore configuration error: $e',
        requiredEnvVars: ['SEMAPHORE_API'],
      );
    }
  }
}

/// Result of provider configuration validation
class ProviderValidationResult {
  /// Whether the configuration is valid
  final bool isValid;

  /// Provider type that was validated
  final String provider;

  /// Validation message (success or error details)
  final String message;

  /// Required environment variables for this provider
  final List<String>? requiredEnvVars;

  /// Whether API key is present (without revealing the key)
  final bool apiKeyPresent;

  ProviderValidationResult({
    required this.isValid,
    required this.provider,
    required this.message,
    this.requiredEnvVars,
    this.apiKeyPresent = false,
  });

  /// Convert to JSON for logging/debugging (safe - no sensitive data)
  Map<String, dynamic> toJson() => {
        'is_valid': isValid,
        'provider': provider,
        'message': message,
        'required_env_vars': requiredEnvVars,
        'api_key_present': apiKeyPresent,
      };

  @override
  String toString() => 'ProviderValidation($provider): $message';
}
