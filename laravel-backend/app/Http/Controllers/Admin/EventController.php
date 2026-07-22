<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\EventImage;
use App\Services\ImageProcessingService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class EventController extends Controller
{
    use LogsAdminActivity;

    protected $imageService;

    public function __construct(ImageProcessingService $imageService)
    {
        $this->imageService = $imageService;
    }

    public function index(Request $request)
    {
        $query = Event::with(['creator', 'coverImage']);

        // Same ownership scoping PlaceController::index() applies — a
        // content_manager only sees events they created plus unclaimed
        // drafts (created_by null), never another content_manager's queue.
        if (!Auth::user()->isFullAdmin()) {
            $query->where(function ($q) {
                $q->where('created_by', Auth::id())->orWhereNull('created_by');
            });
        }

        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%")
                  ->orWhere('location', 'like', "%{$search}%");
            });
        }

        $events = $query->orderBy('created_at', 'desc')->paginate(15)->withQueryString();

        // "Already happened this year" is a display/sort concern only — dates
        // are MM-DD with no year because every event here is annual/recurring
        // (see plan section 9). Computed at read time, not stored.
        $todayMd = now()->format('m-d');
        $events->getCollection()->transform(function ($event) use ($todayMd) {
            $anchor = $event->date ?: $event->start;
            $event->passedThisYear = $anchor ? ($anchor < $todayMd) : false;
            return $event;
        });
        $sorted = $events->getCollection()->sortBy('passedThisYear')->values();
        $events->setCollection($sorted);

        return view('admin.events.index', compact('events'));
    }

    public function create()
    {
        return view('admin.events.form', ['event' => new Event()]);
    }

    /**
     * Content manager's own event submissions — mirrors
     * PlaceController::mySubmissions().
     */
    public function mySubmissions(Request $request)
    {
        $query = Event::with('coverImage')
            ->where('created_by', Auth::id());

        $status = $request->input('status', Event::STATUS_PENDING);
        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $events = $query->orderBy('updated_at', 'desc')->paginate(15);
        return view('admin.events.my-submissions', compact('events'));
    }

    /**
     * Pending events queue — full_admin only, mirrors PlaceController::pending().
     */
    public function pending()
    {
        $events = Event::with('creator')
            ->where('status', Event::STATUS_PENDING)
            ->whereNotNull('created_by')
            ->orderBy('created_at', 'asc')
            ->paginate(15);

        return view('admin.events.pending', compact('events'));
    }

    public function store(Request $request)
    {
        $data = $this->validateEvent($request);
        $isContentManager = Auth::user()->isContentManager();

        $data['created_by'] = Auth::id();
        $data['status'] = $isContentManager ? Event::STATUS_PENDING : Event::STATUS_APPROVED;

        $event = DB::transaction(function () use ($data, $request) {
            $event = Event::create($data);
            $this->handleImages($request, $event);
            return $event;
        });

        if ($isContentManager) {
            Cache::forget('admin_pending_event_count');
        }

        $message = $isContentManager
            ? "Event '{$event->name}' submitted and is awaiting admin approval."
            : "Event '{$event->name}' created successfully.";

        $redirectRoute = $isContentManager ? 'admin.events.my-submissions' : 'admin.events.index';

        return redirect()->route($redirectRoute)->with('success', $message);
    }

    public function edit($id)
    {
        $event = Event::with('images')->findOrFail($id);
        $this->authorizeEventOwner($event);
        return view('admin.events.form', compact('event'));
    }

    public function update(Request $request, $id)
    {
        $event = Event::findOrFail($id);
        $this->authorizeEventOwner($event);
        $data = $this->validateEvent($request);
        $isContentManager = Auth::user()->isContentManager();

        if ($isContentManager && $event->status === Event::STATUS_APPROVED) {
            $data['status'] = Event::STATUS_PENDING;
            $data['reviewed_by'] = null;
            $data['review_reason'] = null;
            Cache::forget('admin_pending_event_count');
        }

        if ($isContentManager && $event->created_by === null) {
            $data['created_by'] = Auth::id();
        }

        DB::transaction(function () use ($event, $data, $request) {
            $event->update($data);
            $this->handleImages($request, $event);
        });

        $sentBackForReview = $isContentManager && $event->status === Event::STATUS_PENDING;
        $message = $sentBackForReview
            ? "Event '{$event->name}' updated and sent back for admin re-approval."
            : "Event '{$event->name}' updated successfully.";

        $redirectRoute = $sentBackForReview ? 'admin.events.my-submissions' : 'admin.events.index';

        return redirect()->route($redirectRoute)->with('success', $message);
    }

    public function destroy($id)
    {
        $event = Event::findOrFail($id);
        $this->authorizeEventOwner($event);
        $eventName = $event->name;
        // Intercepted by EventObserver::deleting -> soft deletes and increments sync_version.
        $event->delete();

        $this->logAdminAction('event.deleted', 'Event', $id, ['name' => $eventName]);

        return redirect()->route('admin.events.index')
            ->with('success', "Event '{$eventName}' has been deleted.");
    }

    public function approve($id)
    {
        $event = Event::findOrFail($id);

        $event->update([
            'status' => Event::STATUS_APPROVED,
            'reviewed_by' => Auth::id(),
            'review_reason' => null,
        ]);

        Cache::forget('admin_pending_event_count');
        $this->logAdminAction('event.approved', 'Event', $id, ['name' => $event->name]);

        return redirect()->route('admin.events.pending')
            ->with('success', "Event '{$event->name}' approved and is now live.");
    }

    public function reject(Request $request, $id)
    {
        $request->validate(['review_reason' => 'required|string|max:1000']);
        $event = Event::findOrFail($id);

        $event->update([
            'status' => Event::STATUS_REJECTED,
            'reviewed_by' => Auth::id(),
            'review_reason' => $request->input('review_reason'),
        ]);

        Cache::forget('admin_pending_event_count');
        $this->logAdminAction('event.rejected', 'Event', $id, ['name' => $event->name, 'reason' => $request->input('review_reason')]);

        return redirect()->route('admin.events.pending')
            ->with('success', "Event '{$event->name}' rejected.");
    }

    public function deleteImage($imageId)
    {
        $image = EventImage::findOrFail($imageId);

        foreach ([$image->thumb_path, $image->full_path] as $path) {
            if ($path) {
                Storage::disk('public')->delete(str_replace('/storage/', '', $path));
            }
        }

        $image->delete();

        return back()->with('success', 'Image removed.');
    }

    public function setCoverImage($imageId)
    {
        $image = EventImage::findOrFail($imageId);
        DB::transaction(function () use ($image) {
            EventImage::where('event_id', $image->event_id)->update(['is_cover' => false]);
            $image->update(['is_cover' => true]);
        });

        return back()->with('success', 'Cover image updated.');
    }

    /**
     * content_manager may only edit/delete events they created themselves,
     * or unclaimed drafts (created_by null) — full admins can act on any
     * event. Mirrors PlaceController::authorizePlaceOwner().
     */
    protected function authorizeEventOwner(Event $event): void
    {
        $user = Auth::user();
        if (!$user->isFullAdmin() && $event->created_by !== null && $event->created_by !== $user->id) {
            abort(403, 'You can only manage events you created.');
        }
    }

    protected function validateEvent(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'category' => 'required|string|max:100',
            'location' => 'nullable|string|max:255',
            'date' => 'nullable|string|max:20|regex:/^[0-1][0-9]-[0-3][0-9]$/', // MM-DD format check
            'start' => 'nullable|string|max:20|regex:/^[0-1][0-9]-[0-3][0-9]$/',
            'end' => 'nullable|string|max:20|regex:/^[0-1][0-9]-[0-3][0-9]$/',
            'is_active' => 'nullable|boolean',
            'images' => 'nullable|array|max:5',
            'images.*' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120',
        ], [
            'date.regex' => 'The date must be in MM-DD format (e.g., 04-13).',
            'start.regex' => 'The start date must be in MM-DD format (e.g., 07-01).',
            'end.regex' => 'The end date must be in MM-DD format (e.g., 08-31).',
        ]);

        unset($data['images']);
        return $data;
    }

    protected function handleImages(Request $request, Event $event)
    {
        if ($request->hasFile('images')) {
            $order = $event->images()->max('sort_order') ?: 0;
            $isFirst = $event->images()->count() === 0;

            foreach ($request->file('images') as $file) {
                $paths = $this->imageService->processAndStore($file, (string) $event->id, 'events');
                $order++;

                EventImage::create([
                    'event_id' => $event->id,
                    'thumb_path' => $paths['thumb_path'],
                    'full_path' => $paths['full_path'],
                    'is_cover' => $isFirst && $order === 1,
                    'sort_order' => $order,
                ]);
            }
        }
    }
}
