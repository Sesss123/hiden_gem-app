<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

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
    private string $credentialsPath;

    /**
     * Initialize Firestore REST service using service account credentials.
     */
    public function __construct()
    {
        try {
            $credentialsPath = config('firebase.credentials');
            
            // Ensure we resolve relative paths (e.g. 'config/firebase-credentials.json') to absolute base path
            $fullPath = file_exists($credentialsPath) ? $credentialsPath : base_path($credentialsPath);
            
            if (!file_exists($fullPath)) {
                throw new \Exception("Firebase credentials not found at {$credentialsPath} or {$fullPath}");
            }
            
            $this->credentialsPath = $fullPath;
            $json = json_decode(file_get_contents($fullPath), true);
            $this->projectId = $json['project_id'] ?? '';
            
            if (empty($this->projectId)) {
                throw new \Exception("project_id not found in Firebase credentials JSON at {$fullPath}");
            }
        } catch (\Exception $e) {
            Log::error("FirestoreService initialization failed: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Fetch OAuth2 access token for Google Cloud Datastore/Firestore API.
     */
    private function getToken(): string
    {
        $scopes = ['https://www.googleapis.com/auth/datastore'];
        $credentials = new ServiceAccountCredentials($scopes, $this->credentialsPath);
        $token = $credentials->fetchAuthToken();
        return $token['access_token'] ?? '';
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
            $fields = [];
            foreach ($val as $k => $v) {
                $fields[$k] = $this->encodeValue($v);
            }
            return ['mapValue' => ['fields' => $fields]];
        }
        return ['stringValue' => (string) $val];
    }

    /**
     * Patch/merge fields into a Firestore document via REST API.
     */
    private function patchDocument(string $collection, string $documentId, array $data): bool
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
            
            $response = Http::withToken($token)->patch($url, ['fields' => $fields]);
            
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
}
