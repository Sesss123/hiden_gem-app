<?php

use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
|
*/

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// `featured-listings` and `ar-enabled-locations` are intentionally public
// channels (no Broadcast::channel() entry needed) — both broadcast the same
// reference data every device already gets via the cached
// /v1/listings/featured and /v1/ar/enabled-locations HTTP endpoints, so
// there is no per-user authorization to enforce here.
