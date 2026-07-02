<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;

class EventController extends Controller
{
    public function index(Request $request)
    {
        $query = Event::query();

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
        $event = Event::create($data);

        return redirect()->route('admin.events.index')
            ->with('success', "Event '{$event->name}' created successfully.");
    }

    public function edit($id)
    {
        $event = Event::findOrFail($id);
        return view('admin.events.form', compact('event'));
    }

    public function update(Request $request, $id)
    {
        $event = Event::findOrFail($id);
        $data = $this->validateEvent($request);
        $event->update($data);

        return redirect()->route('admin.events.index')
            ->with('success', "Event '{$event->name}' updated successfully.");
    }

    public function destroy($id)
    {
        $event = Event::findOrFail($id);
        $event->delete();

        return redirect()->route('admin.events.index')
            ->with('success', "Event '{$event->name}' has been deleted.");
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
