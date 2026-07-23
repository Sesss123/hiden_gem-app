@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-hourglass-half text-amber-500"></i> Pending Events
        </h2>
        <p class="text-sm text-slate-400">Events submitted by content managers, awaiting your approval before they go live to app users.</p>
    </div>

    <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/60 text-slate-400 text-xs font-semibold uppercase tracking-wider border-b border-slate-800">
                        <th class="py-4 px-6">Event Name</th>
                        <th class="py-4 px-6">Location</th>
                        <th class="py-4 px-6">Category</th>
                        <th class="py-4 px-6">Submitted By</th>
                        <th class="py-4 px-6">Submitted</th>
                        <th class="py-4 px-6 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/60 text-sm">
                    @forelse($events as $event)
                    <tr class="hover:bg-slate-800/40 transition duration-150">
                        <td class="py-3 px-6 font-medium text-white">
                            <div class="font-bold">{{ $event->name }}</div>
                        </td>
                        <td class="py-3 px-6 text-slate-300">
                            <span class="inline-flex items-center gap-1 bg-slate-900 px-2.5 py-1 rounded-lg text-xs text-slate-300 border border-slate-800">
                                <i class="fa-solid fa-location-dot text-teal-400 text-[10px]"></i> {{ $event->location ?? 'Island-wide' }}
                            </span>
                        </td>
                        <td class="py-3 px-6">
                            <span class="inline-block px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                                {{ ucfirst($event->category) }}
                            </span>
                        </td>
                        <td class="py-3 px-6 text-slate-300 text-xs">
                            @if($event->creator)
                                <span class="inline-flex items-center gap-1.5">
                                    <i class="fa-solid fa-user-pen text-slate-500"></i> {{ $event->creator->name }}
                                </span>
                            @else
                                <span class="text-slate-600 italic">Unknown</span>
                            @endif
                        </td>
                        <td class="py-3 px-6 text-slate-400 font-mono text-xs">
                            {{ $event->created_at ? $event->created_at->diffForHumans() : 'N/A' }}
                        </td>
                        <td class="py-3 px-6 text-right">
                            <div class="flex items-center justify-end gap-2">
                                <a href="{{ route('admin.events.edit', $event->id) }}" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition shadow" title="Review Details">
                                    <i class="fa-solid fa-eye text-xs"></i>
                                </a>
                                <form action="{{ route('admin.events.approve', $event->id) }}" method="POST" class="inline-block" onsubmit="return confirm('Approve {{ $event->name }}? It will immediately become visible to app users.')">
                                    @csrf
                                    <button type="submit" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-emerald-600 text-slate-300 hover:text-white transition shadow" title="Approve">
                                        <i class="fa-solid fa-check text-xs"></i>
                                    </button>
                                </form>
                                <button type="button" onclick="document.getElementById('reject-modal-{{ $event->id }}').classList.remove('hidden')"
                                    class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-red-600 text-slate-300 hover:text-white transition shadow" title="Reject">
                                    <i class="fa-solid fa-xmark text-xs"></i>
                                </button>
                            </div>
                        </td>
                    </tr>

                    <!-- Reject reason row -->
                    <tr id="reject-modal-{{ $event->id }}" class="hidden">
                        <td colspan="6" class="px-6 py-4 bg-slate-900/50">
                            <form action="{{ route('admin.events.reject', $event->id) }}" method="POST" class="flex items-center gap-3">
                                @csrf
                                <input type="text" name="review_reason" required maxlength="1000" placeholder="Reason for rejecting this event..."
                                    class="flex-1 bg-slate-950 border border-slate-800 rounded-xl py-2 px-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-red-500/50 transition">
                                <button type="submit" class="bg-red-600 hover:bg-red-500 text-white px-4 py-2 rounded-xl text-xs font-semibold transition">
                                    Confirm Reject
                                </button>
                                <button type="button" onclick="document.getElementById('reject-modal-{{ $event->id }}').classList.add('hidden')"
                                    class="text-slate-400 text-xs px-2">Cancel</button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="py-12 text-center text-slate-500">
                            <i class="fa-solid fa-circle-check text-3xl mb-3 block opacity-40"></i>
                            No events awaiting review. All caught up.
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($events->hasPages())
            <div class="p-4 border-t border-slate-800 bg-slate-900/40">
                {{ $events->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
