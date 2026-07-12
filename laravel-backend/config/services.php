<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme' => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'revenuecat' => [
        'webhook_secret' => env('REVENUECAT_WEBHOOK_SECRET'),
    ],

    // Must match AppConfig.sharedSecret (HMAC_SECRET dart-define) in the
    // Flutter app — see VerifyZenithSignature middleware. This is a
    // client-embedded shared secret (extractable from the APK), so it
    // doesn't stop an attacker who has decompiled the app, but it does stop
    // a passive network observer from replaying a captured request
    // unmodified (nonce + timestamp window), which is the real threat this
    // header set exists to cover.
    'zenith_hmac_secret' => env('HMAC_SECRET'),

];
