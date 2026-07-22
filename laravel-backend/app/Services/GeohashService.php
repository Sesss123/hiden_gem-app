<?php

namespace App\Services;

/**
 * Standard geohash encoding (base32, the same scheme used by geohash.org
 * and geoflutterfire_plus on the Flutter side). Precision 9 gives ~5cm
 * accuracy, comfortably enough for a place's coordinates.
 */
class GeohashService
{
    private const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

    public static function encode(float $lat, float $lng, int $precision = 9): string
    {
        $latRange = [-90.0, 90.0];
        $lngRange = [-180.0, 180.0];
        $geohash = '';
        $isEven = true;
        $bit = 0;
        $ch = 0;

        while (strlen($geohash) < $precision) {
            if ($isEven) {
                $mid = ($lngRange[0] + $lngRange[1]) / 2;
                if ($lng >= $mid) {
                    $ch |= (1 << (4 - $bit));
                    $lngRange[0] = $mid;
                } else {
                    $lngRange[1] = $mid;
                }
            } else {
                $mid = ($latRange[0] + $latRange[1]) / 2;
                if ($lat >= $mid) {
                    $ch |= (1 << (4 - $bit));
                    $latRange[0] = $mid;
                } else {
                    $latRange[1] = $mid;
                }
            }

            $isEven = !$isEven;

            if ($bit < 4) {
                $bit++;
            } else {
                $geohash .= self::BASE32[$ch];
                $bit = 0;
                $ch = 0;
            }
        }

        return $geohash;
    }
}
