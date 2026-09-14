import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../network/secure_http_client.dart';
import 'vault_service.dart';
import '../utils/secure_logger.dart';

/// Representation of an active Step-Up authorization grant issued by Cloud Functions.
class StepUpGrant {
  final String grantId;
  final String grantToken;
  final DateTime expiresAt;
  final String action;

  StepUpGrant({
    required this.grantId,
    required this.grantToken,
    required this.expiresAt,
    required this.action,
  });

  bool get isValid => DateTime.now().isBefore(expiresAt);

  Map<String, String> get headers => {
        'X-Zenith-Step-Up-Id': grantId,
        'X-Zenith-Step-Up-Token': grantToken,
        'X-Zenith-Step-Up-Action': action,
      };
}

/// [StepUpAuthService] — Zero-Trust Step-Up Authentication for High-Risk Operations.
///
/// Prevents stolen or stale sessions from executing sensitive actions such as:
/// - Changing email or password
/// - Guide payouts / banking info changes
/// - Admin role or moderation actions
/// - Subscription and tier elevations
///
/// Requires fresh user re-authentication, issues a cryptographically-signed
/// 10-minute elevation grant via Cloud Functions, and gates sensitive execution.
class StepUpAuthService {
  static final StepUpAuthService _instance = StepUpAuthService._internal();
  factory StepUpAuthService() => _instance;
  StepUpAuthService._internal();

  final _auth = FirebaseAuth.instance;

  final Map<String, StepUpGrant> _activeGrants = {};

  /// Checks if a valid, unexpired grant already exists for this action.
  bool hasValidGrant(String action) {
    final grant = _activeGrants[action];
    if (grant == null) return false;
    if (!grant.isValid) {
      _activeGrants.remove(action);
      return false;
    }
    return true;
  }

  /// Retrieves the active grant token to attach to sensitive request headers.
  String? getGrantToken(String action) {
    if (hasValidGrant(action)) {
      return _activeGrants[action]?.grantToken;
    }
    return null;
  }

  Map<String, String> getGrantHeaders(String action) =>
      hasValidGrant(action) ? _activeGrants[action]!.headers : const {};

  void consumeGrant(String action) => _activeGrants.remove(action);

  /// Enforces Step-Up Authentication before allowing a sensitive action.
  ///
  /// If an active grant exists (< 10 minutes old), returns `true` immediately.
  /// Otherwise, presents a re-authentication prompt to the user.
  Future<bool> requireStepUp({
    required BuildContext context,
    required String action,
    String? reason,
  }) async {
    if (hasValidGrant(action)) {
      return true;
    }

    final user = _auth.currentUser;
    if (user == null) {
      SecureLogger.warning('StepUpAuthService: No authenticated user present.');
      return false;
    }

    // Show re-authentication dialog/bottomsheet
    final authenticated = await _promptUserReauth(context, user, reason ?? 'Verification required for sensitive action');
    if (!authenticated) {
      return false;
    }

    // Callable auth_time comes from the ID token; force a new token after
    // reauthentication so the server can enforce its five-minute freshness.
    await user.getIdToken(true);

    // Request Step-Up Grant from Backend
    try {
      final deviceId = await VaultService.getDeviceId();
      final firebaseToken=await user.getIdToken(true);
      final response=await SecureHttpClient(http.Client()).post(Uri.parse('${AppConfig.laravelUrl}/security/step-up'),headers:{'Content-Type':'application/json','Accept':'application/json','X-API-KEY':AppConfig.hiddenGemsApiKey},body:jsonEncode({'action':action,'deviceId':deviceId,'firebaseIdToken':firebaseToken})).timeout(const Duration(seconds:15));
      if(response.statusCode!=200) throw StateError('Step-up request failed (${response.statusCode}).');
      final data=jsonDecode(response.body) as Map<String,dynamic>;
      final grantId = data['grantId'] as String;
      final grantToken = data['grantToken'] as String;
      final expiresAtMs = data['expiresAt'] as int;

      final grant = StepUpGrant(
        grantId: grantId,
        grantToken: grantToken,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMs),
        action: action,
      );

      _activeGrants[action] = grant;
      SecureLogger.info('StepUpAuthService: Elevated grant issued for action: $action (valid 10m)');
      return true;
    } catch (e) {
      SecureLogger.error('StepUpAuthService: Failed to acquire backend step-up grant ($e)');
      return false;
    }
  }

  /// Displays a streamlined, secure re-authentication dialog to verify identity.
  Future<bool> _promptUserReauth(BuildContext context, User user, String reason) async {
    final providers = user.providerData.map((p) => p.providerId).toSet();
    try {
      if (providers.contains('google.com')) {
        await user.reauthenticateWithProvider(GoogleAuthProvider());
        return true;
      }
      if (providers.contains('apple.com')) {
        await user.reauthenticateWithProvider(AppleAuthProvider());
        return true;
      }
    } on FirebaseAuthException catch (e) {
      SecureLogger.warning('Federated step-up authentication failed: ${e.code}');
      return false;
    }
    if (!providers.contains('password')) {
      SecureLogger.warning('Step-up is unavailable for this authentication provider.');
      return false;
    }
    final passwordController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Security Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Logged in as: ${user.email ?? user.phoneNumber ?? "User"}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      errorText: errorMessage,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final password = passwordController.text.trim();
                          if (password.isEmpty) {
                            setDialogState(() => errorMessage = 'Password is required');
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });

                          try {
                            if (user.email != null) {
                              final cred = EmailAuthProvider.credential(
                                email: user.email!,
                                password: password,
                              );
                              await user.reauthenticateWithCredential(cred);
                            }
                            if (dialogCtx.mounted) {
                              Navigator.of(ctx).pop(true);
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = e.message ?? 'Authentication failed';
                            });
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = 'Verification error occurred';
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    return result == true;
  }

  /// Clears all active step-up grants on user logout.
  void clearGrants() {
    _activeGrants.clear();
  }
}
