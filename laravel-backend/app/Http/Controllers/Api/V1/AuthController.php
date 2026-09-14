<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Place;
use App\Models\User;
use App\Models\GuideApplication;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Exception\Auth\UserNotFound;

class AuthController extends Controller
{
    /**
     * Issues a Sanctum token honoring config('sanctum.expiration') — used by
     * all three login/register paths so a stolen token has the same bounded
     * lifetime regardless of how it was obtained.
     */
    private function issueToken(User $user): string
    {
        $expiresAt = config('sanctum.expiration')
            ? now()->addMinutes(config('sanctum.expiration'))
            : null;

        return $user->createToken('auth_token', ['*'], $expiresAt)->plainTextToken;
    }

    /**
     * Register a new Tourist or Local user.
     */
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            // BUG-L04 Fix: Cap password length to 255 characters to prevent bcrypt DoS attacks
            'password' => 'required|string|min:8|max:255',
            'role' => 'nullable|string|in:tourist,local',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'] ?? 'tourist',
            'subscription_tier' => 'Free', // Defaults to Free tier
        ]);

        $token = $this->issueToken($user);

        return response()->json([
            'status' => 'success',
            'message' => 'User registered successfully!',
            'data' => [
                'user' => $user,
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
        ], 201);
    }

    /**
     * Login user and generate Sanctum token.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email|max:255',
            // BUG-L04 Fix: Cap password length to 255 characters to prevent bcrypt DoS attacks
            'password' => 'required|string|max:255',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid email or password credentials.',
            ], 401);
        }

        // Limit token bloat: Keep only the most recent 4 tokens (so this new one makes 5)
        $excessTokens = $user->tokens()->orderBy('created_at', 'desc')->skip(4)->take(PHP_INT_MAX)->pluck('id');
        if ($excessTokens->isNotEmpty()) {
            $user->tokens()->whereIn('id', $excessTokens)->delete();
        }
        $token = $this->issueToken($user);

        return response()->json([
            'status' => 'success',
            'message' => 'Logged in successfully!',
            'data' => [
                'user' => $user,
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
        ]);
    }

    /**
     * Get authenticated user profile.
     */
    public function profile(Request $request)
    {
        return response()->json([
            'status' => 'success',
            'data' => [
                'user' => $request->user(),
            ],
        ]);
    }

    /**
     * Logout user and revoke token.
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Successfully logged out and token revoked.',
        ]);
    }

    /**
     * Authenticate a user via a Firebase ID token.
     */
    public function firebaseLogin(Request $request)
    {
        $request->validate([
            'firebase_token' => 'required|string',
        ]);

        try {
            // Instantiate the Kreait Firebase Factory
            // BUG: was env('FIREBASE_CREDENTIALS') — always null once
            // `php artisan config:cache` runs (standard prod deploy step),
            // silently falling through to the file-path branch below.
            $credentials = config('services.firebase_credentials');
            
            $factory = new \Kreait\Firebase\Factory();
            
            if ($credentials) {
                // BUG-QA-003 fix: Use environment variable JSON string if available
                $factory = $factory->withServiceAccount(json_decode($credentials, true));
            } else {
                // Fallback to path if the string isn't set
                $path = base_path(config('firebase.credentials', 'config/firebase-credentials.json'));
                if (file_exists($path)) {
                    $factory = $factory->withServiceAccount($path);
                } else {
                    // For local development bypass or if not configured properly, just decode the token payload insecurely if needed,
                    // but we should fail secure.
                    throw new \Exception("Firebase credentials not configured.");
                }
            }

            $auth = $factory->createAuth();

            // Verify the token
            $verifiedIdToken = $auth->verifyIdToken($request->firebase_token);
            $uid = $verifiedIdToken->claims()->get('sub');
            $email = $verifiedIdToken->claims()->get('email');
            $phoneNumber = $verifiedIdToken->claims()->get('phone_number');
            $name = $verifiedIdToken->claims()->get('name') ?? 'Firebase User';
            $emailVerified = $verifiedIdToken->claims()->get('email_verified') === true;

            // Find by firebase_uid first; fall back to matching by email so a
            // Firebase account that was deleted and re-created (new uid, same
            // email) re-links to its existing Laravel row instead of hitting
            // the email unique constraint on insert. This fallback link is
            // gated on email_verified: without that check, anyone could
            // create a new Firebase account using a victim's (unverified)
            // email and hijack the victim's existing Laravel account/token.
            $user = User::where('firebase_uid', $uid)->first();
            if (!$user && $email && $emailVerified) {
                $user = User::where('email', $email)->first();
                if ($user && $user->firebase_uid !== $uid) {
                    // A verified Firebase email proves ownership of the
                    // existing Laravel identity. Relink provider/account UID
                    // changes and revoke tokens issued to the old identity.
                    $user->tokens()->delete();
                    $user->update(['firebase_uid' => $uid]);
                }
            }
            if ($phoneNumber) {
                $phoneOwner = User::where('phone_number', $phoneNumber)->first();
                if ($phoneOwner && (!$user || $phoneOwner->id !== $user->id)) {
                    return response()->json([
                        'status' => 'error',
                        'message' => 'This verified phone number is already linked to another account.',
                        'code' => 'phone_already_linked',
                    ], 409);
                }
            }
            if (!$user) {
                // The legacy users table requires a unique non-null email.
                // Phone-only Firebase accounts therefore receive a stable,
                // non-routable internal address keyed by their verified UID.
                $databaseEmail = $email ?: "firebase-{$uid}@phone.invalid";
                $user = User::create([
                    'firebase_uid' => $uid,
                    'email' => $databaseEmail,
                    'name' => $name !== 'Firebase User'
                        ? $name
                        : ($phoneNumber ?: 'Phone User'),
                    'password' => Hash::make(\Illuminate\Support\Str::random(32)),
                    'role' => 'tourist',
                    'subscription_tier' => 'Free',
                    'email_verified_at' => $emailVerified ? now() : null,
                    'phone_number' => $phoneNumber,
                    'phone_verified_at' => $phoneNumber ? now() : null,
                ]);
            } elseif ($emailVerified && !$user->email_verified_at) {
                // Track verification even for pre-existing rows — Firebase's
                // own claim is the source of truth, re-synced on every login
                // so a user who verifies their email after initial signup
                // gets credit for it without a separate endpoint.
                $user->update(['email_verified_at' => now()]);
            }
            if ($phoneNumber && ($user->phone_number !== $phoneNumber || !$user->phone_verified_at)) {
                $user->update(['phone_number' => $phoneNumber, 'phone_verified_at' => now()]);
            }

            if ($user->role === User::ROLE_BANNED) {
                $user->tokens()->delete();
                return response()->json([
                    'status' => 'error',
                    'message' => 'This account has been disabled.',
                    'code' => 'account_disabled',
                ], 403);
            }

            // Limit token bloat
            $excessTokens = $user->tokens()->orderBy('created_at', 'desc')->skip(4)->take(PHP_INT_MAX)->pluck('id');
            if ($excessTokens->isNotEmpty()) {
                $user->tokens()->whereIn('id', $excessTokens)->delete();
            }

            $token = $this->issueToken($user);

            return response()->json([
                'status' => 'success',
                'message' => 'Firebase login successful!',
                'data' => [
                    'user' => $user,
                    'access_token' => $token,
                    'token_type' => 'Bearer',
                ],
            ]);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Firebase Login Error: " . $e->getMessage());
            $response = [
                'status' => 'error',
                'message' => 'Invalid or expired Firebase token.',
            ];
            if (config('app.debug')) {
                $response['debug_message'] = $e->getMessage();
            }
            return response()->json($response, 401);
        }
    }

    /**
     * DELETE /v1/auth/account   (GDPR right-to-erasure)
     *
     * The real cleanup that AuthService.deleteAccount() (Flutter) previously
     * skipped — it only ever deleted the Firebase Auth user and the single
     * users/{uid} Firestore doc, leaving bookings/reviews/saved plans/
     * security records/etc. fully intact and still joinable by uid. This is
     * called FIRST (before the Flutter side touches Firebase Auth), so a
     * failure here leaves the user still able to sign in and retry, instead
     * of the account being gone but the data surviving.
     *
     * Content authorship (places/events created_by) is nulled, not
     * cascade-deleted — that's public tourism content, not personal data,
     * and created_by rows are almost always content_manager/admin staff
     * sharing this same users table. Safety/fraud records (incident reports,
     * SOS alerts, security/device-trust events, abuse reports) are
     * anonymized rather than deleted — security_events' own firestore.rules
     * forbid delete entirely (`allow update, delete: if false`), signaling
     * these are meant to stay as immutable audit records.
     */
    public function deleteAccount(Request $request, FirestoreService $firestore)
    {
        $user = $request->user();
        $uid = $user->firebase_uid;

        if ($uid) {
            // All cleanup is idempotent and must succeed before either login
            // identity is removed. A retry can therefore safely finish a
            // partially-completed deletion after a transient Firestore error.
            $this->purgeFirestoreData($firestore, $uid);
            GuideApplication::where('user_id', $uid)->delete();
            Storage::disk('local')->deleteDirectory("guide_documents/{$uid}");
            Storage::disk('public')->deleteDirectory("listing_photos/{$uid}");

            try {
                $this->firebaseFactory()->createAuth()->deleteUser($uid);
            } catch (UserNotFound $e) {
                // A previous retry may already have removed the identity.
                Log::info('Firebase identity already absent during account deletion.', ['uid' => $uid]);
            }
        }

        // Content authorship: keep the content, drop the link to this account.
        Place::where('created_by', $user->id)->update(['created_by' => null]);
        Event::where('created_by', $user->id)->update(['created_by' => null]);

        // Revoke every token (including the one authenticating this request)
        // before the row itself goes — this request is the account's last
        // authenticated action either way.
        $user->tokens()->delete();
        $user->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Account and associated data deleted.',
        ]);
    }

    /**
     * Deletes personal Firestore data owned by $uid, and anonymizes
     * safety/fraud records instead of deleting them. Each collection is
     * wrapped independently — one collection's transient failure shouldn't
     * abort cleanup of the rest, mirroring the tolerant logging pattern
     * already used in RevenueCatWebhookController/PayHereController.
     */
    private function purgeFirestoreData(FirestoreService $firestore, string $uid): void
    {
        $hardDeleteQueries = [
            ['booking_requests', 'touristId'],
            ['booking_requests', 'guideId'],
            ['tour_reviews', 'touristId'],
            ['tour_sessions', 'guideId'],
            ['tour_links', 'touristId'],
            ['tour_links', 'guideId'],
            ['family_share_links', 'touristId'],
            ['saved_plans', 'userId'],
            ['ar_sessions', 'hostUid'],
            ['guide_client_notes', 'guideId'],
            ['vehicles', 'guideId'],
            ['vehicles', 'operatorId'],
            ['user_progress', 'userId'],
            ['user_gamification', 'userId'],
            ['community_memories', 'userId'],
            ['guide_listings', 'guideId'],
            ['tour_packages', 'ownerId'],
            ['operator_accounts', 'ownerUserId'],
            ['subscriptions', 'accountId'],
            ['user_notifications', 'recipientId'],
            ['profile_view_markers', 'viewerUid'],
            ['guide_analytics', 'guideId'],
        ];

        foreach ($hardDeleteQueries as $query) {
            [$collection, $field] = $query;
            $op = $query[2] ?? 'EQUAL';
            $docs = $firestore->queryDocuments($collection, $field, $op, $uid, null, true);
            foreach ($docs as $doc) {
                $deleted = $collection === 'tour_sessions'
                    ? $firestore->deleteDocumentRecursively($collection, $doc['id'])
                    : $firestore->deleteDocument($collection, $doc['id']);
                if (!$deleted) {
                    throw new \RuntimeException("Failed deleting {$collection}/{$doc['id']}.");
                }
            }
        }

        // A tourist deleting their account must be removed from a shared
        // session, not delete the guide's session and every other tourist's
        // live-tour data. Guide-owned sessions above are still deleted.
        $joinedSessions = $firestore->queryDocuments('tour_sessions', 'touristIds', 'ARRAY_CONTAINS', $uid, null, true);
        foreach ($joinedSessions as $session) {
            $remainingTourists = array_values(array_filter(
                $session['touristIds'] ?? [],
                fn ($touristId) => $touristId !== $uid
            ));
            if (!$firestore->patchDocument('tour_sessions', $session['id'], ['touristIds' => $remainingTourists])) {
                throw new \RuntimeException("Failed removing deleted tourist from tour_sessions/{$session['id']}.");
            }
        }

        // Remove membership references in operator accounts owned by someone
        // else; leaving a deleted UID here would retain personal linkage and
        // can break future team permission checks.
        foreach (['teamGuideIds', 'pendingTeamGuideIds'] as $teamField) {
            $operators = $firestore->queryDocuments('operator_accounts', $teamField, 'ARRAY_CONTAINS', $uid, null, true);
            foreach ($operators as $operator) {
                $remaining = array_values(array_filter($operator[$teamField] ?? [], fn ($memberId) => $memberId !== $uid));
                if (!$firestore->patchDocument('operator_accounts', $operator['id'], [$teamField => $remaining])) {
                    throw new \RuntimeException("Failed removing deleted user from operator_accounts/{$operator['id']}.");
                }
            }
        }

        // Doc ID IS the uid for these two — no query needed.
        foreach (['guide_applications', 'users', 'join_attempts'] as $collection) {
            // Firestore DELETE is idempotent, so avoid a separate existence
            // request whose network failure could be mistaken for "missing".
            $deleted = $collection === 'users'
                ? $firestore->deleteDocumentRecursively($collection, $uid)
                : $firestore->deleteDocument($collection, $uid);
            if (!$deleted) {
                throw new \RuntimeException("Failed deleting {$collection}/{$uid}.");
            }
        }

        $anonymizeQueries = [
            ['incident_reports', 'reportedBy'],
            ['sos_alerts', 'triggeredBy'],
            ['security_events', 'uid'],
            ['security_alerts', 'userId'],
            ['device_trust', 'uid'],
            ['quarantined_sessions', 'uid'],
            ['abuse_reports', 'reportedBy'],
            ['abuse_events', 'userId'],
            ['location_pings', 'uid'],
        ];

        foreach ($anonymizeQueries as [$collection, $field]) {
            $docs = $firestore->queryDocuments($collection, $field, 'EQUAL', $uid, null, true);
            foreach ($docs as $doc) {
                if (!$firestore->patchDocument($collection, $doc['id'], [$field => 'deleted_user'])) {
                    throw new \RuntimeException("Failed anonymizing {$collection}/{$doc['id']}.");
                }
            }
        }
    }

    private function firebaseFactory(): Factory
    {
        $jsonCredentials = config('services.firebase_credentials');
        if ($jsonCredentials) {
            $decoded = json_decode($jsonCredentials, true);
            if (!is_array($decoded)) {
                throw new \RuntimeException('FIREBASE_CREDENTIALS is not valid JSON.');
            }
            return (new Factory())->withServiceAccount($decoded);
        }

        $configuredPath = config('firebase.credentials', 'config/firebase-credentials.json');
        $credentialsPath = is_file($configuredPath)
            ? $configuredPath
            : base_path($configuredPath);
        if (!is_file($credentialsPath)) {
            throw new \RuntimeException('Firebase credentials are not configured.');
        }
        return (new Factory())->withServiceAccount($credentialsPath);
    }
}
