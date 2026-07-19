@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-hourglass-half text-amber-500"></i> Pending Places
        </h2>
        <p class="text-sm text-slate-400">Places submitted by content managers, awaiting your approval before they go live to app users.</p>
    </div>

    <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/60 text-slate-400 text-xs font-semibold uppercase tracking-wider border-b border-slate-800">
                        <th class="py-4 px-6">Gem Name & ID</th>
                        <th class="py-4 px-6">Location</th>
                        <th class="py-4 px-6">Category</th>
                        <th class="py-4 px-6">Submitted By</th>
                        <th class="py-4 px-6">Submitted</th>
                        <th class="py-4 px-6 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/60 text-sm">
                    @forelse($places as $place)
                    <tr class="hover:bg-slate-800/40 transition duration-150">
                        <td class="py-3 px-6 font-medium text-white">
                            <div class="font-bold">{{ $place->name }}</div>
                            <div class="text-xs text-slate-500 font-mono mt-0.5">{{ $place->id }}</div>
                        </td>
                        <td class="py-3 px-6 text-slate-300">
                            <span class="inline-flex items-center gap-1 bg-slate-900 px-2.5 py-1 rounded-lg text-xs text-slate-300 border border-slate-800">
                                <i class="fa-solid fa-location-dot text-teal-400 text-[10px]"></i> {{ $place->district }}
                            </span>
                        </td>
                        <td class="py-3 px-6">
                            <span class="inline-block px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                                {{ $place->category }}
                            </span>
                        </td>
                        <td class="py-3 px-6 text-slate-300 text-xs">
                            @if($place->creator)
                                <span class="inline-flex items-center gap-1.5">
                                    <i class="fa-solid fa-user-pen text-slate-500"></i> {{ $place->creator->name }}
                                </span>
                            @else
                                <span class="text-slate-600 italic">Unknown</span>
                            @endif
                        </td>
                        <td class="py-3 px-6 text-slate-400 font-mono text-xs">
                            {{ $place->created_at ? $place->created_at->diffForHumans() : 'N/A' }}
                        </td>
                        <td class="py-3 px-6 text-right">
                            <div class="flex items-center justify-end gap-2">
                                <a href="{{ route('admin.places.edit', $place->id) }}" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition shadow" title="Review Details">
                                    <i class="fa-solid fa-eye text-xs"></i>
                                </a>
                                <form action="{{ route('admin.places.approve', $place->id) }}" method="POST" class="inline-block" onsubmit="return confirm('Approve {{ $place->name }}? It will immediately become visible to app users.')">
                                    @csrf
                                    <button type="submit" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-emerald-600 text-slate-300 hover:text-white transition shadow" title="Approve">
                                        <i class="fa-solid fa-check text-xs"></i>
                                    </button>
                                </form>
                                <button type="button" onclick="document.getElementById('reject-modal-{{ $place->id }}').classList.remove('hidden')"
                                    class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-red-600 text-slate-300 hover:text-white transition shadow" title="Reject">
                                    <i class="fa-solid fa-xmark text-xs"></i>
                                </button>
                            </div>
                        </td>
                    </tr>

                    <!-- Reject reason row -->
                    <tr id="reject-modal-{{ $place->id }}" class="hidden">
                        <td colspan="6" class="px-6 py-4 bg-slate-900/50">
                            <form action="{{ route('admin.places.reject', $place->id) }}" method="POST" class="flex items-center gap-3">
                                @csrf
                                <input type="text" name="review_reason" required maxlength="1000" placeholder="Reason for rejecting this place..."
                                    class="flex-1 bg-slate-950 border border-slate-800 rounded-xl py-2 px-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-red-500/50 transition">
                                <button type="submit" class="bg-red-600 hover:bg-red-500 text-white px-4 py-2 rounded-xl text-xs font-semibold transition">
                                    Confirm Reject
                                </button>
                                <button type="button" onclick="document.getElementById('reject-modal-{{ $place->id }}').classList.add('hidden')"
                                    class="text-slate-400 text-xs px-2">Cancel</button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="py-12 text-center text-slate-500">
                            <i class="fa-solid fa-circle-check text-3xl mb-3 block opacity-40"></i>
                            No places awaiting review. All caught up.
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($places->hasPages())
            <div class="p-4 border-t border-slate-800 bg-slate-900/40">
                {{ $places->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
