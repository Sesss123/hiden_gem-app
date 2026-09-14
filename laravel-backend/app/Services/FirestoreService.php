<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Client\PendingRequest;

/**
 * FirestoreService
 * 
 * Lightweight REST-based wrapper around Google Cloud Firestore Admin API.
 * Uses Service Account credentials directly over HTTP/REST to bypass Firestore
 * security rules without requiring the gRPC C-extension (ext-grpc) on XAMPP/Windows.
 */
class FirestoreService
{
    private string $projectId;
    /** @var array<string,mixed>|string */
    private $credentials;

    /**
     * Initialize Firestore REST service using service account credentials.
     */
    public function __construct()
    {
        try {
            $inlineCredentials = config('services.firebase_credentials');
            if ($inlineCredentials) {
                $json = json_decode($inlineCredentials, true);
                if (!is_array($json)) {
                    throw new \Exception('FIREBASE_CREDENTIALS is not valid JSON.');
                }
                $this->credentials = $json;
            } else {
                $credentialsPath = config('firebase.credentials', 'config/firebase-credentials.json');
                $fullPath = is_file($credentialsPath) ? $credentialsPath : base_path($credentialsPath);
                if (!is_file($fullPath)) {
                    throw new \Exception("Firebase credentials not found at {$credentialsPath} or {$fullPath}");
                }
                $this->credentials = $fullPath;
                $json = json_decode(file_get_contents($fullPath), true);
            }
            $this->projectId = $json['project_id'] ?? '';
            
            if (empty($this->projectId)) {
                throw new \Exception('project_id not found in Firebase credentials JSON.');
            }
        } catch (\Exception $e) {
            Log::error("FirestoreService initialization failed: " . $e->getMessage());
            // Keep read-only admin pages available even when Firebase is
            // temporarily misconfigured. Individual operations will fail in
            // their existing guarded paths instead of crashing controller
            // construction and turning the whole panel into a 500 page.
            $this->credentials = [];
            $this->projectId = '';
        }
    }

    /**
     * Fetch OAuth2 access token for Google Cloud Datastore/Firestore API.
     */
    private function getToken(): string
    {
        if ($this->projectId === '' || empty($this->credentials)) {
            throw new \RuntimeException('Firestore is not configured.');
        }
        $scopes = ['https://www.googleapis.com/auth/datastore'];
        $credentials = new ServiceAccountCredentials($scopes, $this->credentials);
        $token = $credentials->fetchAuthToken();
        return $token['access_token'] ?? '';
    }

    private function client(string $token): PendingRequest
    {
        return Http::withToken($token)
            ->connectTimeout(5)
            ->timeout(15)
            ->retry(2, 250, throw: false);
    }

    /**
     * Convert PHP primitive or array value to Firestore REST API field format.
     */
    private function encodeValue($val): array
    {
        if (is_string($val)) return ['stringValue' => $val];
        if (is_int($val)) return ['integerValue' => (string) $val];
        if (is_float($val)) return ['doubleValue' => $val];
        if (is_bool($val)) return ['booleanValue' => $val];
        if (is_null($val)) return ['nullValue' => 'NULL_VALUE'];
        if (is_array($val)) {
            // Check if array is associative or sequential
            $isAssociative = false;
            if (count($val) > 0) {
                $keys = array_keys($val);
                $isAssociative = array_keys($keys) !== $keys;
            }

            if ($isAssociative) {
                $fields = [];
                foreach ($val as $k => $v) {
                    $fields[$k] = $this->encodeValue($v);
                }
                return ['mapValue' => ['fields' => $fields]];
            } else {
                $values = [];
                foreach ($val as $v) {
                    $values[] = $this->encodeValue($v);
                }
                return ['arrayValue' => ['values' => $values]];
            }
        }
        return ['stringValue' => (string) $val];
    }

    /**
     * Decode a single Firestore REST API field value back to a PHP primitive/array.
     */
    private function decodeValue(array $field)
    {
        if (array_key_exists('stringValue', $field)) return $field['stringValue'];
        if (array_key_exists('integerValue', $field)) return (int) $field['integerValue'];
        if (array_key_exists('doubleValue', $field)) return (float) $field['doubleValue'];
        if (array_key_exists('booleanValue', $field)) return $field['booleanValue'];
        if (array_key_exists('timestampValue', $field)) return $field['timestampValue'];
        if (array_key_exists('nullValue', $field)) return null;
        if (array_key_exists('mapValue', $field)) {
            $out = [];
            foreach (($field['mapValue']['fields'] ?? []) as $k => $v) {
                $out[$k] = $this->decodeValue($v);
            }
            return $out;
        }
        if (array_key_exists('arrayValue', $field)) {
            return array_map(fn ($v) => $this->decodeValue($v), $field['arrayValue']['values'] ?? []);
        }
        return null;
    }

    /**
     * Patch/merge fields into a Firestore document via REST API.
     */
    public function patchDocument(string $collection, string $documentId, array $data): bool
    {
        try {
            $token = $this->getToken();
            $fields = [];
            $updateMask = [];
            foreach ($data as $key => $val) {
                $fields[$key] = $this->encodeValue($val);
                $updateMask[] = "updateMask.fieldPaths=" . urlencode($key);
            }
            
            $url = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents/{$collection}/{$documentId}?" . implode('&', $updateMask);
            
            $response = $this->client($token)->patch($url, ['fields' => $fields]);
            
            if ($response->successful()) {
                Log::info("Firestore {$collection}/{$documentId} updated via REST: " . json_encode($data));
                return true;
            } else {
                Log::error("Firestore REST error ({$response->status()}): " . $response->body());
                return false;
            }
        } catch (\Exception $e) {
            Log::error("Firestore REST exception for {$collection}/{$documentId}: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Deletes a Firestore document via REST API.
     */
    public function deleteDocument(string $collection, string $documentId): bool
    {
        try {
            $token = $this->getToken();
            $url = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents/{$collection}/{$documentId}";
            $response = $this->client($token)->delete($url);

            if ($response->successful()) {
                Log::info("Firestore {$collection}/{$documentId} deleted via REST.");
                return true;
            }
            Log::error("Firestore REST delete error ({$response->status()}): " . $response->body());
            return false;
        } catch (\Exception $e) {
            Log::error("Firestore REST exception deleting {$collection}/{$documentId}: " . $e->getMessage());
            throw $e;
        }
    }

    /** Send a data-first FCM message to a subscribed topic via HTTP v1. */
    public function sendFcmTopic(string $topic, string $title, string $body, array $data = [], bool $showNotification = true): bool
    {
        try {
            $token = $this->getToken();
            $message = [
                    'topic' => $topic,
                    'data' => array_map(fn ($value) => (string) $value, $data),
                    'android' => ['priority' => 'high'],
            ];
            if ($showNotification) {
                $message['notification'] = ['title' => $title, 'body' => $body];
            }
            $payload = ['message' => $message];
            $response = $this->client($token)->post(
                "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send",
                $payload
            );
            if (!$response->successful()) {
                Log::error("FCM topic send failed ({$response->status()}): " . $response->body());
            }
            return $response->successful();
        } catch (\Throwable $e) {
            Log::error('FCM topic send exception: ' . $e->getMessage());
            return false;
        }
    }

    /** Atomically commit multiple document creates/partial updates. */
    public function commitDocuments(array $writes): bool
    {
        $commitWrites = [];
        foreach ($writes as $write) {
            $fields = [];
            foreach ($write['data'] as $key => $value) {
                $fields[$key] = $this->encodeValue($value);
            }
            $entry = [
                'update' => [
                    'name' => 'projects/' . $this->projectId . '/databases/(default)/documents/' . $write['collection'] . '/' . $write['id'],
                    'fields' => $fields,
                ],
            ];
            if (!empty($write['updateMask'])) {
                $entry['updateMask'] = ['fieldPaths' => array_values($write['updateMask'])];
            }
            if (array_key_exists('exists', $write)) {
                $entry['currentDocument'] = ['exists' => (bool) $write['exists']];
            }
            $commitWrites[] = $entry;
        }

        $token = $this->getToken();
        $url = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents:commit";
        $response = $this->client($token)->post($url, ['writes' => $commitWrites]);
        if (!$response->successful()) {
            Log::error("Firestore atomic commit failed ({$response->status()}): " . $response->body());
            return false;
        }
        return true;
    }

    /** Delete a document and all nested subcollections below it. */
    public function deleteDocumentRecursively(string $collection, string $documentId): bool
    {
        return $this->deleteDocumentPathRecursively("{$collection}/{$documentId}");
    }

    private function deleteDocumentPathRecursively(string $documentPath): bool
    {
        $token = $this->getToken();
        $base = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents";
        $pageToken = null;

        do {
            $body = ['pageSize' => 1000];
            if ($pageToken) $body['pageToken'] = $pageToken;
            $collectionsResponse = $this->client($token)->post("{$base}/{$documentPath}:listCollectionIds", $body);
            if (!$collectionsResponse->successful()) {
                throw new \RuntimeException("Failed listing subcollections for {$documentPath} ({$collectionsResponse->status()}).");
            }

            foreach (($collectionsResponse->json('collectionIds') ?? []) as $collectionId) {
                $documentsPageToken = null;
                do {
                    $query = ['pageSize' => 1000];
                    if ($documentsPageToken) $query['pageToken'] = $documentsPageToken;
                    $documentsResponse = $this->client($token)->get("{$base}/{$documentPath}/{$collectionId}", $query);
                    if (!$documentsResponse->successful()) {
                        throw new \RuntimeException("Failed listing {$documentPath}/{$collectionId} ({$documentsResponse->status()}).");
                    }
                    foreach (($documentsResponse->json('documents') ?? []) as $document) {
                        $childPath = explode('/documents/', $document['name'], 2)[1] ?? null;
                        if (!$childPath || !$this->deleteDocumentPathRecursively($childPath)) {
                            throw new \RuntimeException("Failed recursively deleting a child of {$documentPath}.");
                        }
                    }
                    $documentsPageToken = $documentsResponse->json('nextPageToken');
                } while ($documentsPageToken);
            }
            $pageToken = $collectionsResponse->json('nextPageToken');
        } while ($pageToken);

        $response = $this->client($token)->delete("{$base}/{$documentPath}");
        return $response->successful();
    }

    /**
     * Update or merge data into a guide application document in Firestore.
     */
    public function updateGuideApplication($userId, array $data)
    {
        return $this->patchDocument('guide_applications', $userId, $data);
    }

    /**
     * Update or merge data into a user profile document in Firestore.
     */
    public function updateGuideUser($userId, array $data)
    {
        return $this->patchDocument('users', $userId, $data);
    }

    /**
     * Update or merge data into a subscription record document in Firestore.
     */
    public function updateSubscriptionRecord($subscriptionId, array $data)
    {
        return $this->patchDocument('subscriptions', $subscriptionId, $data);
    }

    /**
     * Update or merge data into a guide_listings document in Firestore.
     * Used by GuideListingController — the only trusted path allowed to set
     * moderationStatus/isFeatured (blocked for clients by firestore.rules).
     */
    public function updateGuideListing($listingId, array $data)
    {
        return $this->patchDocument('guide_listings', $listingId, $data);
    }

    /**
     * Update or merge data into a booking_requests document in Firestore.
     * Used by PayHereController — the only trusted path allowed to set the
     * payment fields (payoutStatus/paidAt/paymentStatus and the confirmed
     * status), which firestore.rules block clients from writing.
     */
    public function updateBooking($bookingId, array $data)
    {
        return $this->patchDocument('booking_requests', $bookingId, $data);
    }

    /**
     * Fetch a single document's decoded fields, or null if it doesn't exist.
     */
    public function getDocument(string $collection, string $documentId): ?array
    {
        try {
            $token = $this->getToken();
            $url = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents/{$collection}/{$documentId}";
            $response = $this->client($token)->get($url);

            if (!$response->successful()) {
                return null;
            }

            $doc = $response->json();
            $fields = [];
            foreach (($doc['fields'] ?? []) as $k => $v) {
                $fields[$k] = $this->decodeValue($v);
            }
            return array_merge(['id' => $documentId], $fields);
        } catch (\Exception $e) {
            Log::error("Firestore REST exception fetching {$collection}/{$documentId}: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Check whether a document exists at collection/documentId.
     */
    public function documentExists(string $collection, string $documentId): bool
    {
        try {
            $token = $this->getToken();
            $url = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents/{$collection}/{$documentId}";
            $response = $this->client($token)->get($url);
            return $response->successful();
        } catch (\Exception $e) {
            Log::error("Firestore REST exception checking existence of {$collection}/{$documentId}: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Runs a simple structured query (single equality filter) against a
     * collection and returns decoded documents (each with an 'id' key).
     */
    public function queryDocuments(string $collection, string $field, string $op, $value, ?int $limit = null, bool $strict = false): array
    {
        try {
            $token = $this->getToken();
            $url = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents:runQuery";

            $structuredQuery = [
                'from' => [['collectionId' => $collection]],
                'where' => [
                    'fieldFilter' => [
                        'field' => ['fieldPath' => $field],
                        'op' => $op,
                        'value' => $this->encodeValue($value),
                    ],
                ],
            ];
            if ($limit !== null) {
                $structuredQuery['limit'] = $limit;
            }

            $response = $this->client($token)->post($url, ['structuredQuery' => $structuredQuery]);
            if (!$response->successful()) {
                Log::error("Firestore REST query error ({$response->status()}): " . $response->body());
                if ($strict) {
                    throw new \RuntimeException("Firestore query failed for {$collection} ({$response->status()}).");
                }
                return [];
            }

            $results = [];
            foreach ($response->json() as $result) {
                if (!isset($result['document'])) continue;
                $doc = $result['document'];
                $id = basename($doc['name']);
                $fields = [];
                foreach (($doc['fields'] ?? []) as $k => $v) {
                    $fields[$k] = $this->decodeValue($v);
                }
                $results[] = array_merge(['id' => $id], $fields);
            }
            return $results;
        } catch (\Exception $e) {
            Log::error("Firestore REST exception querying {$collection} where {$field} {$op} " . json_encode($value) . ": " . $e->getMessage());
            if ($strict) {
                throw $e;
            }
            return [];
        }
    }

    /**
     * Counts booking_requests docs for a guide created on/after a given
     * ISO8601 timestamp. Runs server-side with admin credentials because
     * firestore.rules can't let a tourist client query another guide's full
     * booking list (the rule can only be proven safe for the guide
     * themselves, or a single doc the tourist already owns).
     */
    public function countBookingsForGuideSince(string $guideId, string $sinceIso8601): int
    {
        try {
            $token = $this->getToken();
            $url = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents:runQuery";

            $structuredQuery = [
                'from' => [['collectionId' => 'booking_requests']],
                'where' => [
                    'compositeFilter' => [
                        'op' => 'AND',
                        'filters' => [
                            [
                                'fieldFilter' => [
                                    'field' => ['fieldPath' => 'guideId'],
                                    'op' => 'EQUAL',
                                    'value' => $this->encodeValue($guideId),
                                ],
                            ],
                            [
                                'fieldFilter' => [
                                    'field' => ['fieldPath' => 'createdAt'],
                                    'op' => 'GREATER_THAN_OR_EQUAL',
                                    'value' => $this->encodeValue($sinceIso8601),
                                ],
                            ],
                        ],
                    ],
                ],
            ];

            $response = $this->client($token)->post($url, ['structuredQuery' => $structuredQuery]);
            if (!$response->successful()) {
                Log::error("Firestore REST query error ({$response->status()}): " . $response->body());
                return 0;
            }

            $count = 0;
            foreach ($response->json() as $result) {
                if (isset($result['document'])) $count++;
            }
            return $count;
        } catch (\Exception $e) {
            Log::error("Firestore REST exception counting bookings for guide {$guideId}: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Finds the first subscriptions/{id} document whose accountId field matches
     * the given value. Returns ['id' => ..., ...decoded fields] or null.
     */
    public function findSubscriptionByAccountId(string $accountId): ?array
    {
        $results = $this->queryDocuments('subscriptions', 'accountId', 'EQUAL', $accountId, 1);
        return $results[0] ?? null;
    }

    /**
     * Lists every document in a collection (no filter). Used for small,
     * rarely-changing reference collections where a single-field equality
     * filter isn't expressive enough (e.g. a non-empty-string check).
     */
    public function listDocuments(string $collection, int $maxDocuments = 500): array
    {
        try {
            $token = $this->getToken();
            $url = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents/{$collection}";

            $results = [];
            $pageToken = null;
            do {
                $query = ['pageSize' => min(100, max(1, $maxDocuments - count($results)))];
                if ($pageToken) $query['pageToken'] = $pageToken;
                $response = $this->client($token)->get($url, $query);
                if (!$response->successful()) {
                    Log::error("Firestore REST list error ({$response->status()}): " . $response->body());
                    return [];
                }

                foreach (($response->json()['documents'] ?? []) as $doc) {
                    $id = basename($doc['name']);
                    $fields = [];
                    foreach (($doc['fields'] ?? []) as $k => $v) {
                        $fields[$k] = $this->decodeValue($v);
                    }
                    $results[] = array_merge(['id' => $id], $fields);
                    if (count($results) >= $maxDocuments) {
                        break 2;
                    }
                }
                $pageToken = $response->json('nextPageToken');
            } while ($pageToken);
            return $results;
        } catch (\Exception $e) {
            Log::error("Firestore REST exception listing {$collection}: " . $e->getMessage());
            return [];
        }
    }
}
