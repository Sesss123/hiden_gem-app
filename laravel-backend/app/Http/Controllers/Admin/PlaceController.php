<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Jobs\ProcessImageUpload;
use App\Models\Place;
use App\Models\PlaceImage;
use App\Models\DatasetImport;
use App\Services\GeohashService;
use App\Services\ImageProcessingService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\QueryException;
use Carbon\Carbon;

class PlaceController extends Controller
{
    use LogsAdminActivity;

    protected $imageService;

    public function __construct(ImageProcessingService $imageService)
    {
        $this->imageService = $imageService;
    }

    public function index(Request $request)
    {
        // Store filter in session if provided, otherwise retrieve from session
        if ($request->has('search') || $request->has('category')) {
            session([
                'admin_places_index_search' => $request->input('search'),
                'admin_places_index_category' => $request->input('category'),
            ]);
        }
        $search = session('admin_places_index_search');
        $category = session('admin_places_index_category');

        $query = Place::with('coverImage');
        $hasCreatedBy = Schema::hasColumn('places', Place::COL_CREATED_BY);
        $hasStatus = Schema::hasColumn('places', Place::COL_STATUS);

        // content_manager sees places they personally created plus unclaimed
        // drafts (created_by null — e.g. bulk-imported data awaiting first
        // review) that anyone may pick up. No visibility into other content
        // managers' submissions. Edit access follows the same scoping (see
        // authorizePlaceOwner()); destroy stays full_admin-only regardless.
        if (!Auth::user()->isFullAdmin()) {
            if (!$hasCreatedBy) {
                abort(503, 'Database upgrade in progress. Please run pending migrations.');
            }
            $query->where(function ($q) {
                $q->where('created_by', Auth::id())->orWhereNull('created_by');
            });
        } elseif ($hasStatus) {
            // Full admins should only see Approved places in the main list.
            // Pending places are reviewed in the Pending tab.
            $query->where('status', Place::STATUS_APPROVED);
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('district', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%");
            });
        }

        if ($category) {
            $query->where('category', $category);
        }

        $places = $query->orderBy('updated_at', 'desc')->paginate(15);
        $datasetImports = $this->getRecentDatasetImports();
        $categories = Cache::remember('admin_places_categories', 300, function () {
            try {
                return Place::select('category')->distinct()->whereNotNull('category')->orderBy('category')->pluck('category');
            } catch (\Throwable $e) {
                return collect();
            }
        });
        return view('admin.places.index', compact('places', 'datasetImports', 'search', 'category', 'categories'));
    }

    public function create()
    {
        return view('admin.places.form', ['place' => new Place()]);
    }

    /**
     * Content manager's own submissions, defaulting to just the ones still
     * awaiting admin approval — unlike index(), which full_admin also uses
     * to browse the whole catalog, this is always scoped to the caller.
     * The status filter tabs let the caller widen to approved/rejected/all.
     */
    public function mySubmissions(Request $request)
    {
        $query = Place::with('coverImage')
            ->where('is_deleted', false)
            ->where('created_by', Auth::id());

        $status = $request->input('status', Place::STATUS_PENDING);
        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $places = $query->orderBy('updated_at', 'desc')->paginate(15);
        $datasetImports = $this->getRecentDatasetImports();
        return view('admin.places.my-submissions', compact('places', 'datasetImports'));
    }

    /**
     * Resolves a shortened Google Maps link (maps.app.goo.gl/...) to the
     * full URL it redirects to, so the browser-side coordinate parser (which
     * can't follow a cross-origin redirect itself) can run on the resolved
     * URL. Restricted to Google's own short-link/maps domains — this fetches
     * a user-supplied URL server-side, so an open allowlist would be an SSRF
     * vector letting a client probe internal network addresses.
     */
    public function resolveMapsLink(Request $request)
    {
        $request->validate(['url' => 'required|url|max:500']);
        $url = $request->input('url');

        $host = parse_url($url, PHP_URL_HOST);
        $allowedHosts = ['maps.app.goo.gl', 'goo.gl', 'maps.google.com', 'www.google.com', 'google.com'];
        if (!$host || !in_array(strtolower($host), $allowedHosts, true)) {
            return response()->json(['error' => 'Only Google Maps links are supported.'], 422);
        }

        try {
            $resolvedUrl = $url;
            for ($redirects = 0; $redirects < 5; $redirects++) {
                $response = \Illuminate\Support\Facades\Http::withOptions(['allow_redirects' => false])
                    ->timeout(6)
                    ->get($resolvedUrl);

                if (!$response->redirect()) {
                    break;
                }

                $next = $response->header('Location');
                $nextHost = $next ? strtolower((string) parse_url($next, PHP_URL_HOST)) : '';
                $nextScheme = $next ? strtolower((string) parse_url($next, PHP_URL_SCHEME)) : '';
                if ($nextScheme !== 'https' || !in_array($nextHost, $allowedHosts, true)) {
                    return response()->json(['error' => 'Google Maps redirected to an unsupported destination.'], 422);
                }
                $resolvedUrl = $next;
            }

            $resolvedHost = strtolower((string) parse_url($resolvedUrl, PHP_URL_HOST));
            if (!in_array($resolvedHost, $allowedHosts, true)) {
                return response()->json(['error' => 'Resolved URL is not a permitted Google Maps host.'], 422);
            }

            return response()->json(['resolved_url' => $resolvedUrl]);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Could not reach that link.'], 502);
        }
    }

    public function store(Request $request)
    {
        $data = $this->validatePlace($request);
        $isContentManager = Auth::user()->isContentManager();

        // Ratings are review-derived. Never manufacture a positive score for
        // a place that has not received any verified traveler reviews.
        $data['rating'] = 0.0;
        $data['verified_at'] = $isContentManager ? null : now();
        $data['created_by'] = Auth::id();
        // Places submitted by a content_manager need a real admin's sign-off before
        // going live; places created by a full admin keep today's behavior (live immediately).
        $data['status'] = $isContentManager ? Place::STATUS_PENDING : Place::STATUS_APPROVED;

        $place = null;
        $maxRetries = 3;
        $retryCount = 0;

        while ($retryCount < $maxRetries) {
            try {
                // BUG-L004 & BUG-L006: Wrap ID generation, model creation, and image processing in a transaction
                $place = DB::transaction(function () use ($data, $request) {
                    if (empty($data['id'])) {
                        $data['id'] = $this->generateSmartId($data['category'] ?? 'General', $data['district'] ?? 'SL');
                    }

                    // Creating will trigger PlaceObserver::saving to stamp sync_version
                    $place = Place::create($data);

                    $this->handleImages($request, $place);
                    return $place;
                });
                break;
            } catch (\Illuminate\Database\QueryException $e) {
                // Catch unique constraint collision (23000) and retry after generating next seq ID
                if ($e->getCode() == 23000 && $retryCount < $maxRetries - 1) {
                    $retryCount++;
                    $data['id'] = null; // force regeneration on next attempt
                    continue;
                }
                throw $e;
            }
        }

        if ($isContentManager) {
            Cache::forget('admin_pending_place_count');
        }

        $this->logAdminAction('place.created', 'Place', $place->id, ['name' => $place->name, 'status' => $place->status]);

        $message = $isContentManager
            ? "Place '{$place->name}' submitted and is awaiting admin approval."
            : "Place '{$place->name}' created successfully.";

        // A content_manager's submission won't show up on the main Places
        // list scoped view the way a full admin's would expect — send them
        // straight to My Pending Places so they land on the page that
        // actually shows what they just did, instead of Manage Places.
        $redirectRoute = $isContentManager ? 'admin.places.my-submissions' : 'admin.places.index';

        return redirect()->route($redirectRoute)->with('success', $message);
    }

    public function edit($id)
    {
        $place = Place::with('images')->findOrFail($id);
        $this->authorizePlaceOwner($place);
        return view('admin.places.form', compact('place'));
    }

    public function update(Request $request, $id)
    {
        $place = Place::findOrFail($id);
        $this->authorizePlaceOwner($place);
        $data = $this->validatePlace($request, true);
        $isContentManager = Auth::user()->isContentManager();
        $data['verified_at'] = $isContentManager ? null : now();

        // A content_manager editing an already-approved place sends it back
        // for re-review rather than letting the edit go live unreviewed —
        // same safety net as a brand-new submission. Editing a place that's
        // already pending/rejected just keeps it in that state (no change).
        if ($isContentManager && $place->status === Place::STATUS_APPROVED) {
            $data['status'] = Place::STATUS_PENDING;
            $data['reviewed_by'] = null;
            $data['review_reason'] = null;
            $data['verified_at'] = null;
            Cache::forget('admin_pending_place_count');
        } elseif (!$isContentManager && $place->status !== Place::STATUS_APPROVED) {
            // If a Full Admin edits a pending/rejected place, automatically approve it
            $data['status'] = Place::STATUS_APPROVED;
            $data['reviewed_by'] = Auth::id();
            $data['review_reason'] = null;
            $data['verified_at'] = now();
            Cache::forget('admin_pending_place_count');
        }

        // Claim an unclaimed draft (created_by null — bulk-imported data
        // awaiting first review) the moment a content_manager saves it, so
        // it starts showing up under their own "My Pending Places".
        if ($isContentManager && $place->created_by === null) {
            $data['created_by'] = Auth::id();
        }

        // BUG-L006: Wrap model update and image processing in a transaction
        DB::transaction(function () use ($place, $data, $request) {
            // Updating triggers PlaceObserver::saving if dirty
            $place->update($data);

            $this->handleImages($request, $place);
        });

        $this->logAdminAction('place.updated', 'Place', $place->id, ['name' => $place->name, 'status' => $place->status]);

        $sentBackForReview = $isContentManager && $place->status === Place::STATUS_PENDING;
        $message = $sentBackForReview
            ? "Place '{$place->name}' updated and sent back for admin re-approval."
            : "Place '{$place->name}' updated successfully.";

        $redirectRoute = $sentBackForReview ? 'admin.places.my-submissions' : 'admin.places.index';

        return redirect()->route($redirectRoute)->with('success', $message);
    }

    public function destroy($id)
    {
        $place = Place::findOrFail($id);
        $placeName = $place->name;
        // Intercepted by PlaceObserver::deleting -> soft deletes and increments sync_version!
        $place->delete();

        $this->logAdminAction('place.deleted', 'Place', $id, ['name' => $placeName]);

        return redirect()->route('admin.places.index')->with('success', "Place '{$placeName}' moved to trash (soft deleted).");
    }

    /**
     * content_manager may only view/edit places they created themselves —
     * full admins can act on any place. destroy() is full_admin-only at the
     * route level already; this check is defense-in-depth there and the
     * actual gate for edit()/update().
     */
    protected function authorizePlaceOwner(Place $place): void
    {
        $user = Auth::user();
        // created_by === null means an unclaimed draft (e.g. bulk-imported
        // data awaiting first review) — any content_manager may pick it up.
        // Saving it (see update()) stamps created_by, claiming it from then on.
        if (!$user->isFullAdmin() && $place->created_by !== null && $place->created_by !== $user->id) {
            abort(403, 'You can only manage places you created.');
        }
    }

    /**
     * Pending places queue — submissions from content_managers awaiting review.
     * Only reachable via the full_admin route group.
     */
    public function pending(Request $request)
    {
        // Store filter in session if provided, otherwise retrieve from session
        if ($request->has('search') || $request->has('category')) {
            session([
                'admin_places_pending_search' => $request->input('search'),
                'admin_places_pending_category' => $request->input('category'),
            ]);
        }
        $search = session('admin_places_pending_search');
        $category = session('admin_places_pending_category');

        $query = Place::with('creator')
            ->where('status', Place::STATUS_PENDING)
            // Unclaimed drafts (created_by null — bulk-imported data no
            // content_manager has reviewed yet) aren't real submissions and
            // don't belong in the admin review queue.
            ->whereNotNull('created_by');

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('district', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%");
            });
        }

        if ($category) {
            $query->where('category', $category);
        }

        $places = $query->orderBy('created_at', 'asc')->paginate(15);

        $datasetImports = $this->getRecentDatasetImports();

        return view('admin.places.pending', compact('places', 'datasetImports', 'search', 'category'));
    }

    public function rejected(Request $request)
    {
        // Store filter in session if provided, otherwise retrieve from session
        if ($request->has('search') || $request->has('category')) {
            session([
                'admin_places_rejected_search' => $request->input('search'),
                'admin_places_rejected_category' => $request->input('category'),
            ]);
        }
        $search = session('admin_places_rejected_search');
        $category = session('admin_places_rejected_category');

        $query = Place::with(['creator', 'reviewer'])
            ->where('status', Place::STATUS_REJECTED);

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('district', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%");
            });
        }

        if ($category) {
            $query->where('category', $category);
        }

        $places = $query->orderBy('updated_at', 'desc')->paginate(15);
        $categories = Cache::remember('admin_places_categories', 300, function () {
            try {
                return Place::select('category')->distinct()->whereNotNull('category')->orderBy('category')->pluck('category');
            } catch (\Throwable $e) {
                return collect();
            }
        });

        return view('admin.places.rejected', compact('places', 'search', 'category', 'categories'));
    }

    public function approve($id)
    {
        $place = DB::transaction(function () use ($id) {
            $place = Place::lockForUpdate()->findOrFail($id);
            if (!in_array($place->status, [Place::STATUS_PENDING, Place::STATUS_REJECTED], true)) {
                throw ValidationException::withMessages(['status' => 'Only pending or rejected places can be approved.']);
            }
            $place->update([
                'status' => Place::STATUS_APPROVED,
                'reviewed_by' => Auth::id(),
                'review_reason' => null,
                'verified_at' => now(),
            ]);
            $this->logAdminAction('place.approved', 'Place', $id, ['name' => $place->name]);
            return $place;
        });

        Cache::forget('admin_pending_place_count');

        return redirect()->back()
            ->with('success', "Place '{$place->name}' approved and is now live.");
    }

    public function returnToPending($id)
    {
        $place = DB::transaction(function () use ($id) {
            $place = Place::lockForUpdate()->findOrFail($id);
            if ($place->status !== Place::STATUS_REJECTED) {
                throw ValidationException::withMessages(['status' => 'Only rejected places can be returned to pending review.']);
            }
            $oldReason = $place->review_reason;
            $place->update([
                'status' => Place::STATUS_PENDING,
                'reviewed_by' => null,
                'review_reason' => null,
                'verified_at' => null,
            ]);
            $this->logAdminAction('place.returned_to_pending', 'Place', $id, [
                'name' => $place->name,
                'previous_rejection_reason' => $oldReason,
            ]);
            return $place;
        });

        Cache::forget('admin_pending_place_count');

        return redirect()->back()
            ->with('success', "Place '{$place->name}' returned to pending review queue.");
    }

    public function bulkApprove(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'required|string',
        ]);

        $ids = array_values(array_unique($request->input('ids')));
        [$approvedCount, $approvedNames] = DB::transaction(function () use ($ids) {
            $places = Place::whereIn('id', $ids)
                ->where('status', Place::STATUS_PENDING)
                ->lockForUpdate()->get();
            if ($places->count() !== count($ids)) {
                throw ValidationException::withMessages(['ids' => 'One or more selected places no longer exist or are not pending. Refresh the queue and try again.']);
            }
            $approvedNames = [];
            foreach ($places as $place) {
                $place->update([
                    'status' => Place::STATUS_APPROVED,
                    'reviewed_by' => Auth::id(),
                    'review_reason' => null,
                    'verified_at' => now(),
                ]);
                $approvedNames[] = $place->name;
            }
            $this->logAdminAction('place.bulk_approved', 'Place', 'bulk', [
                'count' => $places->count(),
                'places' => array_slice($approvedNames, 0, 10),
            ]);
            return [$places->count(), $approvedNames];
        });

        Cache::forget('admin_pending_place_count');

        return redirect()->back()->with('success', "{$approvedCount} place(s) approved and are now live.");
    }

    public function reject(Request $request, $id)
    {
        $request->validate(['review_reason' => 'required|string|max:1000']);
        $place = DB::transaction(function () use ($request, $id) {
            $place = Place::lockForUpdate()->findOrFail($id);
            if ($place->status !== Place::STATUS_PENDING) {
                throw ValidationException::withMessages(['status' => 'Only pending places can be rejected.']);
            }
            $place->update([
                'status' => Place::STATUS_REJECTED,
                'reviewed_by' => Auth::id(),
                'review_reason' => $request->input('review_reason'),
                'verified_at' => null,
            ]);
            $this->logAdminAction('place.rejected', 'Place', $id, ['name' => $place->name, 'reason' => $request->input('review_reason')]);
            return $place;
        });

        Cache::forget('admin_pending_place_count');

        return redirect()->back()
            ->with('success', "Place '{$place->name}' rejected.");
    }

    public function deleteImage($imageId)
    {
        $image = PlaceImage::findOrFail($imageId);

        // thumb_path/full_path are stored as "/storage/{relative path}" —
        // strip that prefix since Storage::disk('public') paths are already
        // relative to the public disk root.
        foreach ([$image->thumb_path, $image->full_path] as $path) {
            if ($path) {
                Storage::disk('public')->delete(str_replace('/storage/', '', $path));
            }
        }

        // Deleting image touches parent place -> increments sync_version!
        $image->delete();

        $this->logAdminAction('place.image_deleted', 'Place', $image->place_id, ['image_id' => $imageId]);

        return back()->with('success', 'Image removed.');
    }

    public function setCoverImage($imageId)
    {
        $image = PlaceImage::findOrFail($imageId);
        // BUG-L005: Atomic cover image swap in transaction
        DB::transaction(function () use ($image) {
            PlaceImage::where('place_id', $image->place_id)->update(['is_cover' => false]);
            $image->update(['is_cover' => true]);
        });

        $this->logAdminAction('place.cover_image_changed', 'Place', $image->place_id, ['image_id' => $imageId]);

        return back()->with('success', 'Cover image updated.');
    }

    public function importJson(Request $request)
    {
        $request->validate([
            'json_file' => 'required|file|max:10240', // Max 10MB
        ]);

        $file = $request->file('json_file');
        $extension = strtolower($file->getClientOriginalExtension());
        
        if (!in_array($extension, ['json', 'jsonl', 'txt'])) {
            return back()->with('error', 'Invalid file type. Please upload a .json or .jsonl file.');
        }

        $fileHash = hash_file('sha256', $file->getRealPath());
        $isForce = $request->boolean('force_reimport');

        // Check for duplicate file import if schema supports file_hash
        if (!$isForce && Schema::hasTable('dataset_imports') && Schema::hasColumn('dataset_imports', 'file_hash')) {
            $existingImport = DatasetImport::where('file_hash', $fileHash)->latest()->first();
            if ($existingImport) {
                $importedAt = optional($existingImport->created_at)->format('M d, Y · h:i A') ?? 'previously';
                return back()->with('duplicate_file_warning', [
                    'message' => "Duplicate Detected: An identical dataset ('{$existingImport->filename}') was already imported on {$importedAt} ({$existingImport->record_count} records).",
                    'filename' => $file->getClientOriginalName(),
                ]);
            }
        }

        $jsonStr = trim(file_get_contents($file->getRealPath()));

        // Fix concatenated JSON objects (e.g. `} {` or `}\n{` -> `},{`) 
        // This handles cases where items in an array are missing commas, or raw JSONL lines.
        $jsonStr = preg_replace('/\}\s*\{/', '},{', $jsonStr);

        // If it's still just a sequence of objects not wrapped in an array, wrap it.
        if (str_starts_with($jsonStr, '{') && str_ends_with($jsonStr, '}')) {
            $jsonStr = '[' . $jsonStr . ']';
        }

        $data = json_decode($jsonStr, true);

        if (!is_array($data)) {
            return back()->with('error', 'Invalid JSON format. Please upload a valid JSON array or concatenated JSON objects.');
        }

        $newCount = 0;
        $updatedCount = 0;
        $skippedCount = 0;
        $batchId = (string) Str::uuid();

        try {
        DB::transaction(function () use ($data, $file, $fileHash, $batchId, $isForce, &$newCount, &$updatedCount, &$skippedCount) {
            foreach ($data as $item) {
                if (!isset($item['name']) || empty(trim($item['name']))) {
                    $skippedCount++;
                    continue;
                }

                $rawId = $item['id'] ?? null;
                $category = $item['category'] ?? $item['category_id'] ?? 'General';
                $district = $item['district'] ?? $item['district_id'] ?? 'Unknown';

                if ($rawId && preg_match('/^[A-Z]{2,4}-[A-Z]{3}-\d{3}$/', $rawId)) {
                    $id = $rawId;
                } else {
                    $id = $this->generateSmartId($category, $district);
                }

                $exists = Place::where('id', $id)->exists();
                if ($exists) {
                    $updatedCount++;
                } else {
                    $newCount++;
                }

                Place::updateOrCreate(
                    ['id' => $id],
                    [
                    'name' => $item['name'] ?? 'Unnamed Gem',
                    'description' => $item['description'] ?? '',
                    'district' => $district,
                    'province' => $item['province'] ?? $item['province_id'] ?? '',
                    'category' => $category,
                    'lat' => (float) ($item['lat'] ?? 0),
                    'lng' => (float) ($item['lng'] ?? 0),
                    'rating' => (float) ($item['rating'] ?? 4.5),
                    'ticket_price' => $item['ticket_price'] ?? $item['ticketRange'] ?? 'Free',
                    'road_condition' => $item['road_condition'] ?? $item['roadType'] ?? 'Unknown',
                    'vehicle_access' => $item['vehicleAccess'] ?? $item['vehicle_access'] ?? '',
                    'opening_hours' => $item['opening_hours'] ?? $item['openingHours'] ?? '',
                    'mobile_signal' => $item['mobile_signal'] ?? '',
                    'activities' => $item['activities'] ?? '',
                    'tourist_popularity' => $item['tourist_popularity'] ?? '',
                    'family_friendly' => $item['family_friendly'] ?? '',
                    'budget_category' => $item['budget_category'] ?? $item['budgetCategory'] ?? '',
                    'parking_avail' => $item['parking_avail'] ?? '',
                    'parking_range' => $item['parkingRange'] ?? ($item['parking_avail'] === 'yes' ? 'Available' : 'No'),
                    'toilets' => $item['toilets'] ?? '',
                    'food_nearby' => $item['food_nearby'] ?? '',
                    'wheelchair_access' => $item['wheelchair_access'] ?? '',
                    'camping_allowed' => $item['camping_allowed'] ?? '',
                    'safety_level' => $item['safety_level'] ?? $item['safetyLevel'] ?? '',
                    'wildlife_hazard' => $item['wildlife_hazard'] ?? '',
                    'guide_required' => $item['guide_required'] ?? '',
                    'rain_sensitivity' => $item['rain_sensitivity'] ?? '',
                    'monsoon_note' => $item['monsoon_note'] ?? '',
                    'best_time_to_visit' => $item['best_time_to_visit'] ?? $item['bestTime'] ?? 'Anytime',
                    'height_m' => $item['Height_m'] ?? $item['height_m'] ?? '0',
                    'length_km' => $item['Length_km'] ?? $item['length_km'] ?? '0',
                    'surfing' => $item['Surfing'] ?? $item['surfing'] ?? 'no',
                    'risk_tags' => is_array($item['riskTags'] ?? null) ? $item['riskTags'] : [],
                    'facilities' => is_array($item['facilities'] ?? null) ? $item['facilities'] : [],
                    'ar_supported' => (bool) ($item['arSupported'] ?? false),
                    'ar_tier' => (int) ($item['arTier'] ?? 3),
                    'ar_brand_name' => $item['arBrandName'] ?? '',
                    'ar_model_url' => $item['arModelUrl'] ?? '',
                    'ar_historical_model_url' => $item['arHistoricalModelUrl'] ?? '',
                    'ar_model_scale' => (float) ($item['arModelScale'] ?? 0.01),
                    'historical_period' => $item['historicalPeriod'] ?? '',
                    'ar_file_size_mb' => (float) ($item['ar_file_size_mb'] ?? 0),
                    'audio_guide_url_si' => $item['audio_guide_url_si'] ?? '',
                    'audio_guide_url_en' => $item['audio_guide_url_en'] ?? '',
                    'geohash' => $item['geohash'] ?? '',
                    'image_url' => $item['imageUrl'] ?? null,
                    'status' => Place::STATUS_PENDING,
                    'created_by' => Auth::id(),
                ]);
            }

            $totalProcessed = $newCount + $updatedCount;
            if (Schema::hasTable('dataset_imports')) {
                $importPayload = [
                    'filename' => $file->getClientOriginalName(),
                    'record_count' => $totalProcessed,
                    'user_id' => Auth::id(),
                ];

                if (Schema::hasColumn('dataset_imports', 'file_hash')) {
                    // The original non-forced import retains the unique hash.
                    // Forced audit/history rows remain identifiable by batch ID
                    // without defeating the concurrency constraint.
                    $importPayload['file_hash'] = $isForce ? null : $fileHash;
                }
                if (Schema::hasColumn('dataset_imports', 'batch_id')) {
                    $importPayload['batch_id'] = $batchId;
                }
                if (Schema::hasColumn('dataset_imports', 'imported_count')) {
                    $importPayload['imported_count'] = $newCount;
                }
                if (Schema::hasColumn('dataset_imports', 'skipped_count')) {
                    $importPayload['skipped_count'] = $skippedCount;
                }
                if (Schema::hasColumn('dataset_imports', 'updated_count')) {
                    $importPayload['updated_count'] = $updatedCount;
                }
                if (Schema::hasColumn('dataset_imports', 'duplicate_count')) {
                    $importPayload['duplicate_count'] = 0;
                }

                DatasetImport::create($importPayload);
            }

            $this->logAdminAction('place.imported', 'Place', null, [
                'total' => $totalProcessed,
                'new' => $newCount,
                'updated' => $updatedCount,
                'skipped' => $skippedCount,
                'filename' => $file->getClientOriginalName(),
                'file_hash' => $fileHash,
                'batch_id' => $batchId,
            ]);
        });
        } catch (QueryException $e) {
            if ((string) $e->getCode() === '23000' && !$isForce) {
                return back()->with('duplicate_file_warning', [
                    'message' => 'This identical dataset was imported concurrently by another request. No records from this attempt were committed.',
                    'filename' => $file->getClientOriginalName(),
                ]);
            }
            throw $e;
        }

        $totalProcessed = $newCount + $updatedCount;

        $redirectRoute = Auth::user()->isFullAdmin() ? 'admin.places.pending' : 'admin.places.my-submissions';

        return redirect()->route($redirectRoute)->with('success', "Processed {$totalProcessed} places from JSON: {$newCount} created, {$updatedCount} updated, {$skippedCount} skipped.");
    }

    protected function validatePlace(Request $request, $isUpdate = false)
    {
        $data = $request->validate([
            // Regex constrains the id to the charset generateSmartId() produces
            // (letters/digits/hyphens only) — id is interpolated directly into
            // storage paths in ImageProcessingService::processAndStore(), so
            // without this a crafted id like "../../../etc" would be a path
            // traversal into arbitrary directories under the public disk.
            'id' => $isUpdate ? 'nullable' : 'nullable|string|max:36|regex:/^[A-Za-z0-9\-]+$/|unique:places,id',
            'name' => 'required|string|max:255',
            'district' => 'required|string|max:100',
            'category' => 'required|string|max:100',
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'rating' => 'nullable|numeric|between:0,5',
            'ticket_range' => 'nullable|string|max:100',
            'road_type' => 'nullable|string|max:100',
            'vehicle_access' => 'nullable|string|max:100',
            'parking_range' => 'nullable|string|max:100',
            'best_time' => 'nullable|string|max:100',
            'best_time_to_visit' => 'nullable|string|max:100',
            'description' => 'nullable|string',
            'province' => 'nullable|string|max:100',
            'opening_hours' => 'nullable|string|max:255',
            'weekly_hours' => 'nullable|array',
            'weekly_hours.*.closed' => 'nullable|boolean',
            'weekly_hours.*.open' => ['nullable', 'date_format:H:i'],
            'weekly_hours.*.close' => ['nullable', 'date_format:H:i'],
            'temporarily_closed' => 'nullable|boolean',
            'closure_note' => 'nullable|string|max:255',
            'closure_until' => 'nullable|date',
            'holiday_hours_note' => 'nullable|string|max:255',
            'mobile_signal' => 'nullable|string|max:100',
            'activities_selected' => 'nullable|array',
            'activities_selected.*' => 'string|max:100',
            'activities_other' => 'nullable|string|max:500',
            'tourist_popularity' => 'nullable|string|max:100',
            'family_friendly' => 'nullable|string|max:50',
            'budget_category' => 'nullable|string|max:100',
            'ticket_price' => 'nullable|string|max:100',
            'parking_avail' => 'nullable|string|max:50',
            'toilets' => 'nullable|string|max:50',
            'food_nearby' => 'nullable|string|max:50',
            'wheelchair_access' => 'nullable|string|max:50',
            'camping_allowed' => 'nullable|string|max:50',
            'safety_level' => 'nullable|string|max:100',
            'wildlife_hazard' => 'nullable|string|max:100',
            'guide_required' => 'nullable|string|max:50',
            'rain_sensitivity' => 'nullable|string|max:100',
            'monsoon_note' => 'nullable|string|max:255',
            'height_m' => 'nullable|string|max:50',
            'length_km' => 'nullable|string|max:50',
            'surfing' => 'nullable|string|max:50',
            'road_condition' => 'nullable|string|max:255',
            'ar_supported' => 'nullable|boolean',
            'ar_tier' => 'nullable|integer',
            'ar_brand_name' => 'nullable|string|max:100',
            'ar_model_url' => 'nullable|string|max:500',
            'ar_historical_model_url' => 'nullable|string|max:500',
            'ar_model_scale' => 'nullable|numeric',
            'historical_period' => 'nullable|string|max:100',
            'ar_file_size_mb' => 'nullable|numeric',
            'audio_guide_url_si' => 'nullable|string|max:500',
            'audio_guide_url_en' => 'nullable|string|max:500',
            'geohash' => 'nullable|string|max:20',
            'access_tier' => 'nullable|string|in:Free,PRO,VIP',
            'images' => 'nullable|array|max:5', // BUG-010 Fix: hard constraint on max files per upload
            'images.*' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120',
        ]);

        // Activities form UI is checkboxes + a free-text "Other" field; merge
        // both back into the single comma-separated `activities` column.
        $selected = $data['activities_selected'] ?? [];
        $other = array_filter(array_map('trim', explode(',', $data['activities_other'] ?? '')));
        $data['activities'] = implode(', ', array_merge($selected, $other)) ?: null;
        unset($data['activities_selected'], $data['activities_other']);

        // Geohash is a pure function of lat/lng — always derive it server-side
        // rather than trusting a manually-typed value, which drifts the
        // moment someone edits coordinates without remembering to update it.
        $data['geohash'] = GeohashService::encode((float) $data['lat'], (float) $data['lng']);
        
        // HTML checkboxes are omitted from the request if unchecked. We must
        // explicitly set it to false so that we can turn off AR support after
        // it was previously turned on.
        $data['ar_supported'] = $request->has('ar_supported');
        $data['temporarily_closed'] = $request->boolean('temporarily_closed');
        if (!empty($data['closure_until'])) {
            $data['closure_until'] = Carbon::parse(
                $data['closure_until'],
                'Asia/Colombo'
            )->utc();
        }

        $weekly = [];
        foreach (['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'] as $day) {
            $row = $data['weekly_hours'][$day] ?? [];
            $closed = filter_var($row['closed'] ?? false, FILTER_VALIDATE_BOOLEAN);
            $open = $row['open'] ?? null;
            $close = $row['close'] ?? null;
            if ($closed || ($open && $close)) {
                $weekly[$day] = ['closed' => $closed, 'open' => $open, 'close' => $close];
            }
        }
        $data['weekly_hours'] = $weekly ?: null;

        return $data;
    }

    /**
     * Creates each image row immediately with the shared "processing"
     * placeholder, then dispatches the actual GD resize/WebP-encode work to
     * ProcessImageUpload — the CPU-bound part no longer runs inside the
     * caller's DB::transaction(), which previously stayed open for the
     * entire multi-second pipeline on a multi-photo submission.
     */
    protected function handleImages(Request $request, Place $place)
    {
        if ($request->hasFile('images')) {
            $order = $place->images()->max('sort_order') ?: 0;
            $isFirst = $place->images()->count() === 0;

            foreach ($request->file('images') as $file) {
                $order++;
                $isCover = $isFirst && $order === 1;

                // Move the raw bytes off the request-scoped temp path onto the
                // 'local' disk now, synchronously — UploadedFile itself can't
                // survive being serialized onto the queue.
                $holdingPath = 'image_uploads/' . Str::uuid()->toString() . '.' . ($file->getClientOriginalExtension() ?: 'jpg');
                Storage::disk('local')->put($holdingPath, file_get_contents($file->getRealPath()));

                // PlaceImageObserver::saving() rejects a second row for this
                // place with the same full_path (duplicate-detection) — a
                // shared literal placeholder path would collide on any
                // multi-photo upload, so give each row's placeholder a
                // unique query-string tag instead of a bare shared URL.
                $placeholderUrl = '/images/processing-placeholder.webp?row=' . Str::uuid()->toString();

                $image = PlaceImage::create([
                    'place_id' => $place->id,
                    'thumb_path' => $placeholderUrl,
                    'full_path' => $placeholderUrl,
                    'is_cover' => $isCover,
                    'sort_order' => $order,
                    'status' => 'processing',
                ]);

                ProcessImageUpload::dispatch(
                    'place',
                    $image->id,
                    $holdingPath,
                    $place->id,
                    'places',
                    $file->getClientOriginalExtension() ?: 'jpg',
                );
            }
        }
    }

    public function deduplicate(Request $request)
    {
        $idsStr = $request->input('ids');
        if (!$idsStr) {
            return back()->with('error', 'No duplicate IDs provided.');
        }

        $ids = array_filter(array_map('trim', explode(',', $idsStr)));
        if (count($ids) < 2) {
            return back()->with('error', 'Need at least 2 IDs to deduplicate.');
        }

        // Keep the first one, delete the rest
        $keepId = array_shift($ids);
        
        // Soft delete the duplicates
        Place::whereIn('id', $ids)->update(['is_deleted' => true]);

        $this->logAdminAction('place.deduplicated', 'Place', $keepId, [
            'kept' => $keepId,
            'deleted' => $ids
        ]);

        return back()->with('success', count($ids) . ' duplicate records deleted successfully.');
    }

    public function bulkDeduplicate(Request $request)
    {
        $duplicateGroups = $request->input('duplicate_groups'); // Array of comma-separated string of IDs
        
        if (!$duplicateGroups || !is_array($duplicateGroups)) {
            return back()->with('error', 'No duplicate groups selected.');
        }

        $totalDeleted = 0;
        $totalKept = 0;

        foreach ($duplicateGroups as $idsStr) {
            $ids = array_filter(array_map('trim', explode(',', $idsStr)));
            if (count($ids) < 2) continue;

            $keepId = array_shift($ids);
            
            // Soft delete the duplicates
            Place::whereIn('id', $ids)->update(['is_deleted' => true]);

            $this->logAdminAction('place.deduplicated', 'Place', $keepId, [
                'kept' => $keepId,
                'deleted' => $ids
            ]);

            $totalDeleted += count($ids);
            $totalKept++;
        }

        return back()->with('success', "Bulk deduplication complete. Kept {$totalKept} records, deleted {$totalDeleted} duplicates.");
    }

    protected function generateSmartId($category, $district)
    {
        $catMap = [
            'waterfalls' => 'WF',
            'beach' => 'BE',
            'religious places' => 'TM',
            'temple' => 'TM',
            'sacred temple' => 'TM',
            'view point' => 'VP',
            'tea estate' => 'TE',
            'adventure park' => 'AP',
            'ancient architecture' => 'ARC',
            'colonial fort' => 'CF',
            'royal palace' => 'RP',
            'historical monument' => 'HM',
            'wildlife / national park' => 'WL',
            'hiking / trekking' => 'HK',
            'village experience' => 'VE',
            'culinary / food' => 'FD',
            'cultural site' => 'CS',
        ];

        $catKey = strtolower(trim($category));
        $catCode = $catMap[$catKey] ?? strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $category), 0, 3));
        if (empty($catCode)) $catCode = 'GEM';

        // Explicit map, not a generic first-3-letters rule: Matale and Matara
        // both truncate to "MAT", which would silently collide two real
        // districts onto the same ID prefix (and their sequence numbers would
        // interleave). Every other Sri Lankan district happens to already be
        // unique under the naive rule, but they're listed explicitly here too
        // so the whole set stays guaranteed-unique even if a future district
        // name is added.
        $districtCodeMap = [
            'ampara' => 'AMP', 'anuradhapura' => 'ANU', 'badulla' => 'BAD',
            'batticaloa' => 'BAT', 'colombo' => 'COL', 'galle' => 'GAL',
            'gampaha' => 'GAM', 'hambantota' => 'HAM', 'jaffna' => 'JAF',
            'kalutara' => 'KAL', 'kandy' => 'KAN', 'kegalle' => 'KEG',
            'kilinochchi' => 'KIL', 'kurunegala' => 'KUR', 'mannar' => 'MAN',
            'matale' => 'MTL', 'matara' => 'MTR', 'moneragala' => 'MON',
            'mullaitivu' => 'MUL', 'nuwara eliya' => 'NUW', 'polonnaruwa' => 'POL',
            'puttalam' => 'PUT', 'ratnapura' => 'RAT', 'trincomalee' => 'TRI',
            'vavuniya' => 'VAV',
        ];
        $distKey = strtolower(trim($district));
        $distCode = $districtCodeMap[$distKey] ?? strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $district), 0, 3));
        if (empty($distCode)) $distCode = 'SL';

        $prefix = "{$catCode}-{$distCode}-";

        // BUG-L004: Lock matching ID prefix range to prevent concurrent duplicate ID generation.
        // withoutGlobalScopes() is required here: Place's "active" scope hides
        // soft-deleted rows (is_deleted=true), but the physical primary key
        // stays occupied forever — scanning only active rows would regenerate
        // an already-used ID and the INSERT would fail with a duplicate-key
        // error on every subsequent attempt for that category+district.
        $ids = Place::withoutGlobalScopes()
            ->where('id', 'like', "{$prefix}%")
            ->lockForUpdate()
            ->pluck('id');

        $maxNum = 0;
        foreach ($ids as $id) {
            if (preg_match('/-(\d+)$/', $id, $matches)) {
                $num = (int)$matches[1];
                if ($num > $maxNum) {
                    $maxNum = $num;
                }
            }
        }

        $nextNum = $maxNum + 1;

        return $prefix . sprintf('%03d', $nextNum);
    }

    /**
     * Safely retrieves recent dataset imports, gracefully failing if the table
     * does not yet exist on the production database.
     */
    protected function getRecentDatasetImports(int $limit = 10)
    {
        try {
            if (!Schema::hasTable('dataset_imports')) {
                return collect();
            }
            return DatasetImport::with('user')->orderBy('created_at', 'desc')->take($limit)->get();
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('Failed fetching dataset imports: ' . $e->getMessage());
            return collect();
        }
    }
}
