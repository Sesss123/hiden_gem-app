<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EventController extends Controller
{
    use LogsAdminActivity;

    public function index(Request $request)
    {
        $query = Event::with('creator');

        if ($search = $request->input('search')) {
            $query->where('name', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%")
                  ->orWhere('location', 'like', "%{$search}%");
        }

        $events = $query->orderBy('created_at', 'desc')->paginate(15);
        return view('admin.events.index', compact('events'));
    }

    public function create()
    {
        return view('admin.events.form', ['event' => new Event()]);
    }

    public function store(Request $request)
    {
        $data = $this->validateEvent($request);
        $data['created_by'] = Auth::id();
        $event = Event::create($data);

        return redirect()->route('admin.events.index')
            ->with('success', "Event '{$event->name}' created successfully.");
    }

    public function edit($id)
    {
        $event = Event::findOrFail($id);
        $this->authorizeEventOwner($event);
        return view('admin.events.form', compact('event'));
    }

    public function update(Request $request, $id)
    {
        $event = Event::findOrFail($id);
        $this->authorizeEventOwner($event);
        $data = $this->validateEvent($request);
        $event->update($data);

        return redirect()->route('admin.events.index')
            ->with('success', "Event '{$event->name}' updated successfully.");
    }

    public function destroy($id)
    {
        $event = Event::findOrFail($id);
        $this->authorizeEventOwner($event);
        $eventName = $event->name;
        $event->delete();

        $this->logAdminAction('event.deleted', 'Event', $id, ['name' => $eventName]);

        return redirect()->route('admin.events.index')
            ->with('success', "Event '{$eventName}' has been deleted.");
    }

    /**
     * content_manager may only edit/delete events they created themselves —
     * full admins can act on any event. Events have no approval gate (unlike
     * Places), so this ownership check is the only thing stopping one
     * content_manager from editing/deleting another's events.
     */
    protected function authorizeEventOwner(Event $event): void
    {
        $user = Auth::user();
        if (!$user->isFullAdmin() && $event->created_by !== $user->id) {
            abort(403, 'You can only manage events you created.');
        }
    }

    protected function validateEvent(Request $request)
    {
        return $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'category' => 'required|string|max:100',
            'location' => 'nullable|string|max:255',
            'date' => 'nullable|string|max:20|regex:/^[0-1][0-9]-[0-3][0-9]$/', // MM-DD format check
            'start' => 'nullable|string|max:20|regex:/^[0-1][0-9]-[0-3][0-9]$/',
            'end' => 'nullable|string|max:20|regex:/^[0-1][0-9]-[0-3][0-9]$/',
            'is_active' => 'nullable|boolean',
        ], [
            'date.regex' => 'The date must be in MM-DD format (e.g., 04-13).',
            'start.regex' => 'The start date must be in MM-DD format (e.g., 07-01).',
            'end.regex' => 'The end date must be in MM-DD format (e.g., 08-31).',
        ]);
    }
}
