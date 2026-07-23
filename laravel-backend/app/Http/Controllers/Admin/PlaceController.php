<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use App\Models\PlaceImage;
use App\Services\ImageProcessingService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

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
        $query = Place::with('coverImage')->where('is_deleted', false);

        // content_manager sees places they personally created plus unclaimed
        // drafts (created_by null — e.g. bulk-imported data awaiting first
        // review) that anyone may pick up. No visibility into other content
        // managers' submissions. Edit access follows the same scoping (see
        // authorizePlaceOwner()); destroy stays full_admin-only regardless.
        if (!Auth::user()->isFullAdmin()) {
            $query->where(function ($q) {
                $q->where('created_by', Auth::id())->orWhereNull('created_by');
            });
        }

        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('district', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%");
            });
        }

        if ($category = $request->input('category')) {
            $query->where('category', $category);
        }

        $places = $query->orderBy('updated_at', 'desc')->paginate(15);
        return view('admin.places.index', compact('places'));
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
        return view('admin.places.my-submissions', compact('places'));
    }

    public function store(Request $request)
    {
        $data = $this->validatePlace($request);
        $isContentManager = Auth::user()->isContentManager();

        // Rating input was removed from the admin form (never fed by a real
        // review system) — seed new places with the same 4.8 default the
        // form used to prefill, instead of the raw DB column default of 0.
        $data['rating'] = $data['rating'] ?? 4.8;
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

        $message = $isContentManager
            ? "Place '{$place->name}' submitted and is awaiting admin approval."
            : "Place '{$place->name}' created successfully.";

        return redirect()->route('admin.places.index')->with('success', $message);
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

        // A content_manager editing an already-approved place sends it back
        // for re-review rather than letting the edit go live unreviewed —
        // same safety net as a brand-new submission. Editing a place that's
        // already pending/rejected just keeps it in that state (no change).
        if ($isContentManager && $place->status === Place::STATUS_APPROVED) {
            $data['status'] = Place::STATUS_PENDING;
            $data['reviewed_by'] = null;
            $data['review_reason'] = null;
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

        $message = ($isContentManager && $place->status === Place::STATUS_PENDING)
            ? "Place '{$place->name}' updated and sent back for admin re-approval."
            : "Place '{$place->name}' updated successfully.";

        return redirect()->route('admin.places.index')->with('success', $message);
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
    public function pending()
    {
        $places = Place::with('creator')
            ->where('status', Place::STATUS_PENDING)
            // Unclaimed drafts (created_by null — bulk-imported data no
            // content_manager has reviewed yet) aren't real submissions and
            // don't belong in the admin review queue.
            ->whereNotNull('created_by')
            ->orderBy('created_at', 'asc')
            ->paginate(15);

        return view('admin.places.pending', compact('places'));
    }

    public function approve($id)
    {
        $place = Place::findOrFail($id);

        // Re-triggers PlaceObserver::saving -> bumps sync_version, which is what
        // makes this place actually appear in the next Flutter delta sync.
        $place->update([
            'status' => Place::STATUS_APPROVED,
            'reviewed_by' => Auth::id(),
            'review_reason' => null,
        ]);

        Cache::forget('admin_pending_place_count');
        $this->logAdminAction('place.approved', 'Place', $id, ['name' => $place->name]);

        return redirect()->route('admin.places.pending')
            ->with('success', "Place '{$place->name}' approved and is now live.");
    }

    public function reject(Request $request, $id)
    {
        $request->validate(['review_reason' => 'required|string|max:1000']);
        $place = Place::findOrFail($id);

        $place->update([
            'status' => Place::STATUS_REJECTED,
            'reviewed_by' => Auth::id(),
            'review_reason' => $request->input('review_reason'),
        ]);

        Cache::forget('admin_pending_place_count');
        $this->logAdminAction('place.rejected', 'Place', $id, ['name' => $place->name, 'reason' => $request->input('review_reason')]);

        return redirect()->route('admin.places.pending')
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

        return back()->with('success', 'Cover image updated.');
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
            'road_condition' => 'nullable|string|max:100',
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

        return $data;
    }

    protected function handleImages(Request $request, Place $place)
    {
        if ($request->hasFile('images')) {
            $order = $place->images()->max('sort_order') ?: 0;
            $isFirst = $place->images()->count() === 0;

            foreach ($request->file('images') as $file) {
                $paths = $this->imageService->processAndStore($file, $place->id);
                $order++;

                PlaceImage::create([
                    'place_id' => $place->id,
                    'thumb_path' => $paths['thumb_path'],
                    'full_path' => $paths['full_path'],
                    'is_cover' => $isFirst && $order === 1,
                    'sort_order' => $order,
                ]);
            }
        }
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

        $distCode = strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $district), 0, 3));
        if (empty($distCode)) $distCode = 'SL';

        $prefix = "{$catCode}-{$distCode}-";
        
        // BUG-L004: Lock matching ID prefix range to prevent concurrent duplicate ID generation
        $lastPlace = Place::where('id', 'like', "{$prefix}%")
            ->lockForUpdate()
            ->orderBy('id', 'desc')
            ->first();

        $nextNum = 1;
        if ($lastPlace && preg_match('/-(\d+)$/', $lastPlace->id, $matches)) {
            $nextNum = ((int)$matches[1]) + 1;
        }

        return $prefix . sprintf('%03d', $nextNum);
    }
}
