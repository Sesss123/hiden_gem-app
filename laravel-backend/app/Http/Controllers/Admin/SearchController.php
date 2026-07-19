<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\GuideApplication;
use App\Models\Place;
use App\Models\User;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;

class SearchController extends Controller
{
    protected const MIN_QUERY_LENGTH = 2;
    protected const PER_SECTION_LIMIT = 5;

    public function index(Request $request, FirestoreService $firestore)
    {
        $q = trim((string) $request->input('q', ''));
        $tooShort = $q !== '' && mb_strlen($q) < self::MIN_QUERY_LENGTH;
        $isFullAdmin = Auth::user()->isFullAdmin();

        $results = [
            'places' => collect(),
            'events' => collect(),
            'users' => collect(),
            'guides' => collect(),
            'partners' => collect(),
        ];

        if ($q !== '' && !$tooShort) {
            // Places — same created_by scoping as PlaceController::index()
            $placesQuery = Place::with('coverImage')->where('is_deleted', false);
            if (!$isFullAdmin) {
                $placesQuery->where('created_by', Auth::id());
            }
            $placesQuery->where(function ($query) use ($q) {
                $query->where('name', 'like', "%{$q}%")
                    ->orWhere('district', 'like', "%{$q}%")
                    ->orWhere('category', 'like', "%{$q}%");
            });
            $results['places'] = $placesQuery->orderBy('updated_at', 'desc')->limit(self::PER_SECTION_LIMIT)->get();

            // Events — no ownership restriction, matches EventController::index() today
            $results['events'] = Event::where(function ($query) use ($q) {
                $query->where('name', 'like', "%{$q}%")
                    ->orWhere('category', 'like', "%{$q}%")
                    ->orWhere('location', 'like', "%{$q}%");
            })->orderBy('created_at', 'desc')->limit(self::PER_SECTION_LIMIT)->get();

            // Users, Guides, Partners: content_manager has no route access to
            // these sections at all, so the queries must never run for that
            // role — a true early-return per source, not a fetch-then-hide.
            if ($isFullAdmin) {
                $results['users'] = User::where(function ($query) use ($q) {
                    $query->where('name', 'like', "%{$q}%")
                        ->orWhere('email', 'like', "%{$q}%");
                })->orderBy('created_at', 'desc')->limit(self::PER_SECTION_LIMIT)->get();

                $results['guides'] = GuideApplication::with('user')
                    ->where(function ($query) use ($q) {
                        $query->whereHas('user', function ($userQuery) use ($q) {
                            $userQuery->where('name', 'like', "%{$q}%")
                                ->orWhere('email', 'like', "%{$q}%");
                        })->orWhere('license_number', 'like', "%{$q}%");
                    })
                    ->orderBy('created_at', 'desc')
                    ->limit(self::PER_SECTION_LIMIT)
                    ->get();

                $needle = strtolower($q);
                $partners = $firestore->listDocuments('partners');
                $partners = array_values(array_filter($partners, function ($p) use ($needle) {
                    return str_contains(strtolower($p['name'] ?? ''), $needle)
                        || str_contains(strtolower($p['category'] ?? ''), $needle);
                }));
                usort($partners, fn ($a, $b) => strcmp($a['name'] ?? '', $b['name'] ?? ''));
                $results['partners'] = collect(array_slice($partners, 0, self::PER_SECTION_LIMIT));
            }
        }

        return view('admin.search.index', [
            'q' => $q,
            'tooShort' => $tooShort,
            'results' => $results,
        ]);
    }
}
