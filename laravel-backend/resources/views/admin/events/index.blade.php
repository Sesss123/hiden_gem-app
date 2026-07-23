@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
            <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
                <i class="fa-solid fa-calendar-days text-emerald-500"></i> Calendar Events
            </h2>
            <p class="text-sm text-slate-400">Manage cultural, festival, and seasonal tourist events in Sri Lanka.</p>
        </div>
        <div>
            <a href="{{ route('admin.events.create') }}" class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-4 py-2 rounded-xl text-sm font-semibold shadow-md shadow-emerald-950/20 transition duration-200 flex items-center gap-2 glow-effect">
                <i class="fa-solid fa-plus"></i> Add Event
            </a>
        </div>
    </div>

    <!-- Filter & Search Bar -->
    <div class="glass-card p-4 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4">
        <form action="{{ route('admin.events.index') }}" method="GET" class="w-full flex flex-col md:flex-row gap-4">
            <div class="flex-1 relative">
                <i class="fa-solid fa-magnifying-glass absolute left-4 top-3 text-slate-400"></i>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search by name, category, or location..." class="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 pl-11 pr-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500/50 transition">
            </div>
            <div class="flex gap-2">
                <button type="submit" class="bg-slate-800 hover:bg-slate-700 text-white px-5 py-2.5 rounded-xl text-sm font-semibold border border-slate-700 transition">
                    Filter
                </button>
                @if(request('search'))
                    <a href="{{ route('admin.events.index') }}" class="bg-slate-900 hover:bg-slate-850 text-slate-400 border border-slate-800 px-5 py-2.5 rounded-xl text-sm font-semibold transition flex items-center justify-center">
                        Clear
                    </a>
                @endif
            </div>
        </form>
    </div>

    <!-- Events List Table -->
    <div class="glass-card rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-6 py-4"></th>
                        <th class="px-6 py-4">Event Details</th>
                        <th class="px-6 py-4">Category</th>
                        <th class="px-6 py-4">Location</th>
                        <th class="px-6 py-4">Date/Duration</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4">Created By</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($events as $event)
                        <tr class="hover:bg-slate-900/30 transition">
                            <td class="px-6 py-5">
                                @php $thumb = $event->coverImage->thumb_path ?? null; @endphp
                                @if($thumb)
                                    <img src="{{ $thumb }}" alt="{{ $event->name }}" class="w-12 h-12 rounded-xl object-cover border border-slate-700 shadow-sm">
                                @else
                                    <div class="w-12 h-12 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-500">
                                        <i class="fa-solid fa-calendar-days text-sm"></i>
                                    </div>
                                @endif
                            </td>
                            <td class="px-6 py-5">
                                <div class="font-bold text-white">{{ $event->name }}</div>
                                <div class="text-xs text-slate-400 max-w-xs truncate mt-0.5">{{ $event->description }}</div>
                            </td>
                            <td class="px-6 py-5">
                                <span class="bg-emerald-500/10 text-emerald-400 text-xs px-2.5 py-1 rounded-full font-medium border border-emerald-500/20">
                                    {{ ucfirst($event->category) }}
                                </span>
                            </td>
                            <td class="px-6 py-5 text-slate-300">
                                <i class="fa-solid fa-location-dot text-slate-500 mr-1.5"></i> {{ $event->location ?? 'Island-wide' }}
                            </td>
                            <td class="px-6 py-5 text-slate-300 font-mono text-xs">
                                @if($event->date)
                                    <i class="fa-regular fa-calendar mr-1.5 text-slate-500"></i> {{ $event->date }}
                                @elseif($event->start && $event->end)
                                    <i class="fa-regular fa-calendar mr-1.5 text-slate-500"></i> {{ $event->start }} to {{ $event->end }}
                                @else
                                    <span class="text-slate-500">N/A</span>
                                @endif
                                @if($event->passedThisYear ?? false)
                                    <div class="mt-1 inline-flex items-center gap-1 text-[10px] text-slate-500 bg-slate-800/60 px-1.5 py-0.5 rounded border border-slate-700">
                                        <i class="fa-solid fa-clock-rotate-left"></i> Already happened this year
                                    </div>
                                @endif
                            </td>
                            <td class="px-6 py-5">
                                @php $estatus = $event->status ?? 'approved'; @endphp
                                <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2 py-0.5 rounded-md border
                                    {{ $estatus === 'approved' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : ($estatus === 'rejected' ? 'bg-red-500/10 text-red-400 border-red-500/20' : 'bg-amber-500/10 text-amber-400 border-amber-500/20') }}">
                                    {{ ucfirst($estatus) }}
                                </span>
                                @if(!$event->is_active)
                                    <span class="inline-flex items-center gap-1.5 text-xs text-slate-400 font-semibold bg-slate-800 px-2 py-0.5 rounded-md border border-slate-700 mt-1">
                                        Inactive
                                    </span>
                                @endif
                            </td>
                            <td class="px-6 py-5 text-slate-300 text-xs">
                                @if($event->creator)
                                    <span class="inline-flex items-center gap-1.5">
                                        <i class="fa-solid fa-user-pen text-slate-500"></i> {{ $event->creator->name }}
                                    </span>
                                @else
                                    <span class="text-slate-600 italic">System / Unknown</span>
                                @endif
                            </td>
                            <td class="px-6 py-5 text-right">
                                <div class="flex items-center justify-end gap-2">
                                    <a href="{{ route('admin.events.edit', $event->id) }}" class="text-slate-400 hover:text-emerald-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Edit">
                                        <i class="fa-solid fa-pen-to-square"></i>
                                    </a>
                                    <form action="{{ route('admin.events.destroy', $event->id) }}" method="POST" onsubmit="return confirm('Are you sure you want to delete this event?');" class="inline">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="text-slate-400 hover:text-red-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Delete">
                                            <i class="fa-solid fa-trash-can"></i>
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="px-6 py-10 text-center text-slate-500">
                                <div class="flex flex-col items-center justify-center gap-2">
                                    <i class="fa-solid fa-calendar-xmark text-3xl text-slate-600"></i>
                                    <span>No events registered yet.</span>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($events->hasPages())
            <div class="px-6 py-4 border-t border-slate-800/40 bg-slate-900/10">
                {{ $events->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
