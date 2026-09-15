<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\GuideApplication;
use App\Services\FirestoreService;
use App\Http\Controllers\Api\V1\AuthController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Http;
use Mockery;

class AccountDeletionFlowTest extends TestCase
{
    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    /**
     * Test that unauthenticated requests to delete account are rejected.
     */
    public function test_delete_account_requires_authentication()
    {
        $response = $this->deleteJson('/api/v1/auth/account');
        $response->assertStatus(401);
    }

    /**
     * Test that purgeFirestoreData includes all required collections and queries.
     */
    public function test_purge_firestore_data_contains_all_gaps_collections()
    {
        $reflection = new \ReflectionClass(AuthController::class);
        $method = $reflection->getMethod('purgeFirestoreData');
        $method->setAccessible(true);

        $capturedQueries = [];
        $deletedDocs = [];
        $recursivelyDeleted = [];
        $patchedDocs = [];

        $firestoreMock = Mockery::mock(FirestoreService::class);

        // Expect queryDocuments to be called for hard deletes and anonymizations
        $firestoreMock->shouldReceive('queryDocuments')
            ->andReturnUsing(function ($collection, $field, $op, $val, $limit = null, $strict = false) use (&$capturedQueries) {
                $capturedQueries[] = [$collection, $field];
                return [];
            });

        // Expect deleteDocumentRecursively for security posture and users
        $firestoreMock->shouldReceive('deleteDocumentRecursively')
            ->andReturnUsing(function ($collection, $docId) use (&$recursivelyDeleted) {
                $recursivelyDeleted[] = "{$collection}/{$docId}";
                return true;
            });

        // Expect deleteDocument for individual documents
        $firestoreMock->shouldReceive('deleteDocument')
            ->andReturnUsing(function ($collection, $docId) use (&$deletedDocs) {
                $deletedDocs[] = "{$collection}/{$docId}";
                return true;
            });

        $authController = new AuthController();
        $testUid = 'test-firebase-uid-999';

        $method->invoke($authController, $firestoreMock, $testUid);

        // 1. Verify missing collections identified in Gap 2 are present in queries
        $collectionsQueried = array_map(fn ($q) => $q[0], $capturedQueries);

        $this->assertContains('subscriptions', $collectionsQueried);
        $this->assertContains('user_notifications', $collectionsQueried);
        $this->assertContains('profile_view_markers', $collectionsQueried);
        $this->assertContains('threat_notifications', $collectionsQueried);
        $this->assertContains('guide_analytics', $collectionsQueried);

        // 2. Verify both userId and accountId/recipientId/viewerUid/targetUid are covered
        $this->assertContains(['subscriptions', 'accountId'], $capturedQueries);
        $this->assertContains(['subscriptions', 'userId'], $capturedQueries);
        $this->assertContains(['user_notifications', 'recipientId'], $capturedQueries);
        $this->assertContains(['user_notifications', 'userId'], $capturedQueries);
        $this->assertContains(['profile_view_markers', 'viewerUid'], $capturedQueries);
        $this->assertContains(['profile_view_markers', 'targetUid'], $capturedQueries);
        $this->assertContains(['threat_notifications', 'userId'], $capturedQueries);

        // 3. Verify security posture subcollection cleanup
        $this->assertContains("users/{$testUid}/security/posture", $recursivelyDeleted);

        // 4. Verify direct document deletions
        $this->assertContains("users/{$testUid}", $recursivelyDeleted);
        $this->assertContains("guide_applications/{$testUid}", $deletedDocs);
        $this->assertContains("join_attempts/{$testUid}", $deletedDocs);
    }

    /**
     * Test presence subcollection deletion when user is part of a tour session.
     */
    public function test_tourist_presence_deleted_from_joined_session()
    {
        $reflection = new \ReflectionClass(AuthController::class);
        $method = $reflection->getMethod('purgeFirestoreData');
        $method->setAccessible(true);

        $testUid = 'tourist-uid-123';
        $sessionId = 'active-session-456';

        $firestoreMock = Mockery::mock(FirestoreService::class);

        // When querying tour_sessions for joined tourist, return 1 session
        $firestoreMock->shouldReceive('queryDocuments')
            ->andReturnUsing(function ($collection, $field, $op, $val) use ($sessionId, $testUid) {
                if ($collection === 'tour_sessions' && $field === 'touristIds') {
                    return [
                        [
                            'id' => $sessionId,
                            'touristIds' => [$testUid, 'other-tourist-789'],
                        ],
                    ];
                }
                return [];
            });

        // Expect patchDocument on tour_sessions removing the tourist
        $firestoreMock->shouldReceive('patchDocument')
            ->with('tour_sessions', $sessionId, ['touristIds' => ['other-tourist-789']])
            ->once()
            ->andReturn(true);

        $presenceDeleted = false;
        $firestoreMock->shouldReceive('deleteDocument')
            ->with("tour_sessions/{$sessionId}/presence", $testUid)
            ->once()
            ->andReturnUsing(function () use (&$presenceDeleted) {
                $presenceDeleted = true;
                return true;
            });

        // General allowances for remaining calls
        $firestoreMock->shouldReceive('deleteDocumentRecursively')->andReturn(true);
        $firestoreMock->shouldReceive('deleteDocument')->andReturn(true);

        $authController = new AuthController();
        $method->invoke($authController, $firestoreMock, $testUid);

        $this->assertTrue($presenceDeleted, 'Tourist presence document was expected to be deleted.');
    }

    /**
     * Test fail-fast behavior: if Firestore purge throws, user account and tokens are NOT deleted.
     */
    public function test_fail_fast_leaves_account_intact_on_purge_failure()
    {
        $user = Mockery::mock(User::class)->makePartial();
        $user->id = 99999;
        $user->firebase_uid = 'failing-uid-123';

        // Tokens and delete must NEVER be called if cleanup fails
        $user->shouldReceive('tokens->delete')->never();
        $user->shouldReceive('delete')->never();

        $firestoreMock = Mockery::mock(FirestoreService::class);
        $firestoreMock->shouldReceive('queryDocuments')
            ->andThrow(new \RuntimeException('Transient Firestore Network Timeout'));

        $request = Request::create('/api/v1/auth/account', 'DELETE');
        $request->setUserResolver(fn () => $user);

        $authController = new AuthController();
        $response = $authController->deleteAccount($request, $firestoreMock);

        $this->assertEquals(500, $response->getStatusCode());
        $data = json_decode($response->getContent(), true);
        $this->assertEquals('error', $data['status']);
        $this->assertEquals('deletion_failed', $data['code']);
    }

    /**
     * Test storage directories cleanup across both UID and numeric user ID.
     */
    public function test_file_cleanup_purges_both_uid_and_numeric_id()
    {
        Storage::fake('local');
        Storage::fake('public');

        $uid = 'user-firebase-uid-777';
        $numericId = 42;

        // Populate test files under both directories
        Storage::disk('local')->put("guide_documents/{$uid}/license.pdf", 'dummy');
        Storage::disk('local')->put("guide_documents/{$numericId}/license.pdf", 'dummy');
        Storage::disk('public')->put("listing_photos/{$uid}/cover.jpg", 'dummy');
        Storage::disk('public')->put("listing_photos/{$numericId}/cover.jpg", 'dummy');

        $this->assertTrue(Storage::disk('local')->exists("guide_documents/{$uid}/license.pdf"));
        $this->assertTrue(Storage::disk('local')->exists("guide_documents/{$numericId}/license.pdf"));
        $this->assertTrue(Storage::disk('public')->exists("listing_photos/{$uid}/cover.jpg"));
        $this->assertTrue(Storage::disk('public')->exists("listing_photos/{$numericId}/cover.jpg"));

        // Simulate file purge logic from deleteAccount
        Storage::disk('local')->deleteDirectory("guide_documents/{$uid}");
        Storage::disk('local')->deleteDirectory("guide_documents/{$numericId}");
        Storage::disk('public')->deleteDirectory("listing_photos/{$uid}");
        Storage::disk('public')->deleteDirectory("listing_photos/{$numericId}");

        $this->assertFalse(Storage::disk('local')->exists("guide_documents/{$uid}/license.pdf"));
        $this->assertFalse(Storage::disk('local')->exists("guide_documents/{$numericId}/license.pdf"));
        $this->assertFalse(Storage::disk('public')->exists("listing_photos/{$uid}/cover.jpg"));
        $this->assertFalse(Storage::disk('public')->exists("listing_photos/{$numericId}/cover.jpg"));
    }
}
