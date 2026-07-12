<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
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

        $token = $user->createToken('auth_token')->plainTextToken;

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
        $token = $user->createToken('auth_token')->plainTextToken;

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
            $credentials = env('FIREBASE_CREDENTIALS'); 
            
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
            $name = $verifiedIdToken->claims()->get('name') ?? 'Firebase User';
            $emailVerified = $verifiedIdToken->claims()->get('email_verified') === true;

            // Find by firebase_uid first; fall back to matching by email so a
            // Firebase account that was deleted and re-created (new uid, same
            // email) re-links to its existing Laravel row instead of hitting
            // the email unique constraint on insert.
            $user = User::where('firebase_uid', $uid)->first();
            if (!$user && $email) {
                $user = User::where('email', $email)->first();
                if ($user && !$user->firebase_uid) {
                    $user->update(['firebase_uid' => $uid]);
                }
            }
            if (!$user) {
                $user = User::create([
                    'firebase_uid' => $uid,
                    'email' => $email,
                    'name' => $name,
                    'password' => Hash::make(\Illuminate\Support\Str::random(32)),
                    'role' => 'tourist',
                    'subscription_tier' => 'Free',
                    'email_verified_at' => $emailVerified ? now() : null,
                ]);
            } elseif ($emailVerified && !$user->email_verified_at) {
                // Track verification even for pre-existing rows — Firebase's
                // own claim is the source of truth, re-synced on every login
                // so a user who verifies their email after initial signup
                // gets credit for it without a separate endpoint.
                $user->update(['email_verified_at' => now()]);
            }

            // Limit token bloat
            $excessTokens = $user->tokens()->orderBy('created_at', 'desc')->skip(4)->take(PHP_INT_MAX)->pluck('id');
            if ($excessTokens->isNotEmpty()) {
                $user->tokens()->whereIn('id', $excessTokens)->delete();
            }

            $token = $user->createToken('auth_token')->plainTextToken;

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
}
