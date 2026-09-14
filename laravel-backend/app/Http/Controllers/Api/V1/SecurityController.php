<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class SecurityController extends Controller
{
    private function uid(Request $request): string { return (string) $request->user()->firebase_uid; }

    public function registerDeviceKey(Request $request, FirestoreService $firestore)
    {
        $d=$request->validate(['deviceId'=>'required|string|max:100','publicKeyPem'=>'required|string|max:2000','platform'=>'nullable|string|max:30']);
        if(!openssl_pkey_get_public($d['publicKeyPem'])) return response()->json(['error'=>'Invalid public key.'],422);
        $uid=$this->uid($request);$path="users/{$uid}/devices";$old=$firestore->getDocument($path,$d['deviceId']);
        if($old&&($old['keyVersion']??null)==='native-v1'&&!hash_equals((string)$old['publicKeyPem'],$d['publicKeyPem'])) return response()->json(['error'=>'Key replacement requires revocation.'],403);
        $ok=$firestore->patchDocument($path,$d['deviceId'],['deviceId'=>$d['deviceId'],'publicKeyPem'=>$d['publicKeyPem'],'platform'=>$d['platform']??'unknown','keyVersion'=>'native-v1','isRevoked'=>false,'lastActiveAt'=>gmdate('c')]);
        return $ok?response()->json(['success'=>true]):response()->json(['error'=>'Registration failed.'],503);
    }

    public function rotateSession(Request $request, FirestoreService $firestore)
    {
        $d=$request->validate(['sessionId'=>'required|string|max:100','deviceId'=>'required|string|max:100','presentedTokenHash'=>'nullable|string|size:64']);$uid=$this->uid($request);$path="users/{$uid}/sessions";$s=$firestore->getDocument($path,$d['sessionId']);$p=$d['presentedTokenHash']??'';
        if(!$firestore->getDocument("users/{$uid}/devices",$d['deviceId']))return response()->json(['error'=>'Unregistered device.'],403);
        if($s&&(($s['isRevoked']??false)||time()-(strtotime($s['createdAt']??'')?:0)>43200||($s['deviceId']??null)!==$d['deviceId']||!$p||!hash_equals((string)($s['currentActiveTokenHash']??''),$p)||in_array($p,$s['consumedTokenHashes']??[],true))){$firestore->patchDocument($path,$d['sessionId'],['isRevoked'=>true,'revokedAt'=>gmdate('c')]);return response()->json(['error'=>'Session revoked.'],403);}
        if(!$s&&$p)return response()->json(['error'=>'Unknown session.'],403);$token=Str::random(64);$used=$s['consumedTokenHashes']??[];if($p)$used[]=$p;
        $ok=$firestore->patchDocument($path,$d['sessionId'],['sessionId'=>$d['sessionId'],'familyId'=>$s['familyId']??(string)Str::uuid(),'deviceId'=>$d['deviceId'],'createdAt'=>$s['createdAt']??gmdate('c'),'lastSeenAt'=>gmdate('c'),'currentActiveTokenHash'=>hash('sha256',$token),'consumedTokenHashes'=>array_slice($used,-100),'isRevoked'=>false]);
        return $ok?response()->json(['success'=>true,'newToken'=>$token,'expiresInSeconds'=>3600]):response()->json(['error'=>'Rotation failed.'],503);
    }

    public function issueStepUpGrant(Request $request, FirestoreService $firestore)
    {
        $d=$request->validate(['action'=>'required|in:change_email,change_password,admin_moderation,guide_payout,subscription_change','deviceId'=>'required|string|max:100','firebaseIdToken'=>'required|string']);$uid=$this->uid($request);$secret=config('services.step_up_hmac_secret');if(!$secret||strlen($secret)<32)return response()->json(['error'=>'Step-up not configured.'],503);
        try{$credentials=config('services.firebase_credentials');$factory=new \Kreait\Firebase\Factory();$factory=$credentials?$factory->withServiceAccount(json_decode($credentials,true)):$factory->withServiceAccount(base_path(config('firebase.credentials')));$verified=$factory->createAuth()->verifyIdToken($d['firebaseIdToken']);if($verified->claims()->get('sub')!==$uid||time()-(int)$verified->claims()->get('auth_time')>300)return response()->json(['error'=>'Fresh authentication required.'],403);}catch(\Throwable $e){return response()->json(['error'=>'Invalid authentication proof.'],403);}
        $id=bin2hex(random_bytes(16));$expires=(int)round(microtime(true)*1000)+600000;$token=hash_hmac('sha256',"{$uid}|{$d['action']}|{$id}|{$expires}",$secret);$firestore->patchDocument("users/{$uid}/step_up_grants",$id,['grantId'=>$id,'action'=>$d['action'],'deviceId'=>$d['deviceId'],'expiresAt'=>$expires,'isUsed'=>false]);
        return response()->json(['grantId'=>$id,'grantToken'=>$token,'expiresAt'=>$expires,'action'=>$d['action']]);
    }

    public function evaluatePosture(Request $request, FirestoreService $firestore)
    {
        $d=$request->validate(['signals'=>'array|max:50','signals.*'=>'string|max:100','deviceId'=>'required|string|max:100','action'=>'nullable|string|max:100']);
        $weights=['device_rooted_jailbroken'=>50,'package_name_mismatch'=>90,'signature_mismatch'=>80,'debugger_attached'=>40,'emulator_detected'=>30,'mock_location_detected'=>35,'honeypot_triggered'=>70];
        $score=0;$threats=[];foreach($d['signals']??[] as $signal){if(isset($weights[$signal])){$score+=$weights[$signal];$threats[]=$signal;}}
        $uid=$this->uid($request);$device=$firestore->getDocument("users/{$uid}/devices",$d['deviceId']);
        if(!$device||($device['isRevoked']??false)){$score+=60;$threats[]='untrusted_device';}
        $score=min(100,$score);$allowed=$score<90;
        $firestore->patchDocument("users/{$uid}/security",'posture',['riskScore'=>$score,'isBlocked'=>!$allowed,'activeThreats'=>$threats,'deviceId'=>$d['deviceId'],'lastAction'=>$d['action']??'general','lastDecisionAllowed'=>$allowed,'evaluatedAt'=>gmdate('c')]);
        return response()->json(['riskScore'=>$score,'isBlocked'=>!$allowed,'allowed'=>$allowed,'activeThreats'=>$threats]);
    }

    public function revokeSession(Request $request, FirestoreService $firestore)
    {
        $d=$request->validate(['sessionId'=>'required|string|max:100']);$uid=$this->uid($request);
        $firestore->patchDocument("users/{$uid}/sessions",$d['sessionId'],['isRevoked'=>true,'revokedAt'=>gmdate('c'),'revocationReason'=>'user_requested']);
        return response()->json(['success'=>true]);
    }

    public function revokeAllSessions(Request $request, FirestoreService $firestore)
    {
        $uid=$this->uid($request);$count=0;
        foreach($firestore->listDocuments("users/{$uid}/sessions") as $session){if(!($session['isRevoked']??false)&&$firestore->patchDocument("users/{$uid}/sessions",$session['id'],['isRevoked'=>true,'revokedAt'=>gmdate('c'),'revocationReason'=>'user_requested_all']))$count++;}
        return response()->json(['success'=>true,'count'=>$count]);
    }
    /**
     * GET /v1/security/device-account-count?deviceHash=...
     *
     * Counts distinct accounts bound to a device hash, for
     * DeviceTrustGraph's multi-account-per-device fraud check. Runs
     * server-side because firestore.rules only allows admins to read the
     * device_trust collection directly — a regular client can write its own
     * binding but can never query other users' bindings, so this specific
     * count has to be resolved here with admin Firestore credentials.
     */
    public function deviceAccountCount(Request $request, FirestoreService $firestore)
    {
        $deviceHash = $request->query('deviceHash');
        if (!$deviceHash) {
            return response()->json(['error' => 'deviceHash is required'], 422);
        }

        // Security: the legitimate caller (DeviceTrustGraph.recordAndVerifyLogin)
        // always queries its OWN device's hash, right after binding it — never
        // an arbitrary one. Without this check, any authenticated user could
        // pass any deviceHash and learn account-count fraud signals about a
        // device they don't own, bypassing the admin-only Firestore rule this
        // endpoint exists to bridge around. Requiring the caller's own binding
        // to already exist confirms they're asking about their own device.
        $callerUid = (string) $request->user()->firebase_uid;
        $ownBinding = $firestore->getDocument('device_trust', "{$deviceHash}_{$callerUid}");
        if (!$ownBinding) {
            return response()->json(['error' => 'No binding found for this device and caller.'], 403);
        }

        try {
            $bindings = $firestore->queryDocuments('device_trust', 'deviceHash', 'EQUAL', $deviceHash);
            $distinctAccounts = collect($bindings)->pluck('uid')->unique()->count();

            return response()->json(['accountCount' => $distinctAccounts]);
        } catch (\Exception $e) {
            Log::error('Device account count failed', ['device_hash' => $deviceHash, 'error' => $e->getMessage()]);
            return response()->json(['error' => 'Failed to check device account count'], 500);
        }
    }
}
