@extends('admin.layout')

@section('title', 'Review Queue - Hidden Gems SL')
@section('header', 'Review Workflow Queue')

@section('content')
<div class="space-y-6">
    <!-- Header Banner -->
    <div class="glass-card p-6 rounded-2xl border border-slate-800 flex items-center justify-between">
        <div>
            <h2 class="text-xl font-bold text-white flex items-center gap-2">
                <span class="p-2 bg-amber-500/20 text-amber-400 rounded-lg">🛡️</span>
                Pending Places Queue
            </h2>
            <p class="text-sm text-slate-400 mt-1">
                Review submissions submitted by local guides and scouts before publishing to mobile synchronization.
            </p>
        </div>
        <div class="px-4 py-2 bg-slate-800/80 rounded-xl border border-slate-700 flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-amber-400 animate-pulse"></span>
            <span class="text-sm font-semibold text-slate-200">{{ $pendingCount }} Pending Review</span>
        </div>
    </div>

    <!-- Alert Messages -->
    @if(session('success'))
        <div class="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center gap-3">
            <span>✅</span>
            <span class="text-sm font-medium">{{ session('success') }}</span>
        </div>
    @endif

    <!-- Pending Table -->
    <div class="glass-card rounded-2xl border border-slate-800 overflow-hidden">
        @if($pendingPlaces->isEmpty())
            <div class="p-12 text-center text-slate-500">
                <div class="text-4xl mb-3">🎉</div>
                <div class="text-lg font-semibold text-slate-300">Queue is completely empty!</div>
                <div class="text-sm">All submitted hidden gems have been reviewed and processed.</div>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="border-b border-slate-800 bg-slate-900/50 text-slate-400 text-xs uppercase tracking-wider font-semibold">
                            <th class="p-4">Place Name</th>
                            <th class="p-4">District</th>
                            <th class="p-4">Category</th>
                            <th class="p-4">Submitted At</th>
                            <th class="p-4">Access Tier</th>
                            <th class="p-4 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-800/60 text-sm text-slate-300">
                        @foreach($pendingPlaces as $place)
                            <tr class="hover:bg-slate-800/30 transition">
                                <td class="p-4 font-semibold text-white flex items-center gap-3">
                                    <span class="w-8 h-8 rounded-lg bg-slate-800 flex items-center justify-center text-indigo-400 font-bold">
                                        {{ substr($place->name, 0, 1) }}
                                    </span>
                                    {{ $place->name }}
                                </td>
                                <td class="p-4 text-slate-400">{{ $place->district }}</td>
                                <td class="p-4">
                                    <span class="px-2.5 py-1 rounded-full text-xs font-medium bg-slate-800 text-indigo-300 border border-slate-700">
                                        {{ $place->category }}
                                    </span>
                                </td>
                                <td class="p-4 text-slate-500 text-xs">{{ $place->created_at ? $place->created_at->diffForHumans() : 'N/A' }}</td>
                                <td class="p-4">
                                    <span class="px-2.5 py-1 rounded-full text-xs font-bold
                                        {{ $place->access_tier === 'VIP' ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30' : ($place->access_tier === 'PRO' ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/30' : 'bg-slate-700/50 text-slate-300') }}">
                                        {{ $place->access_tier ?? 'Free' }}
                                    </span>
                                </td>
                                <td class="p-4 text-right space-x-2">
                                    <!-- Approve Button -->
                                    <form action="{{ route('admin.places.approve', $place->id) }}" method="POST" class="inline-block">
                                        @csrf
                                        <button type="submit" class="px-3 py-1.5 bg-emerald-600/80 hover:bg-emerald-600 text-white rounded-lg text-xs font-semibold transition shadow-lg shadow-emerald-900/30 flex items-center gap-1 inline-flex">
                                            <span>✓</span> Approve
                                        </button>
                                    </form>

                                    <!-- Reject Button (Modal Toggle) -->
                                    <button onclick="openRejectModal('{{ $place->id }}', '{{ addslashes($place->name) }}')" class="px-3 py-1.5 bg-rose-600/80 hover:bg-rose-600 text-white rounded-lg text-xs font-semibold transition shadow-lg shadow-rose-900/30 inline-flex items-center gap-1">
                                        <span>✕</span> Reject
                                    </button>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div class="p-4 border-t border-slate-800">
                {{ $pendingPlaces->links() }}
            </div>
        @endif
    </div>
</div>

<!-- Rejection Modal -->
<div id="rejectModal" class="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 hidden items-center justify-center p-4">
    <div class="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl">
        <div class="flex items-center justify-between border-b border-slate-800 pb-3">
            <h3 class="text-lg font-bold text-white">Reject Place Submission</h3>
            <button onclick="closeRejectModal()" class="text-slate-400 hover:text-white">✕</button>
        </div>
        <p class="text-sm text-slate-300" id="rejectModalText">Please specify the reason for rejecting this hidden gem submission.</p>
        
        <form id="rejectForm" method="POST" action="" class="space-y-4">
            @csrf
            <div>
                <label class="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">Rejection Reason</label>
                <textarea name="review_reason" rows="3" required placeholder="e.g. Inaccurate location data, duplicate submission, or safety concern..." class="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-sm text-white focus:outline-none focus:border-indigo-500"></textarea>
            </div>
            <div class="flex justify-end gap-3 pt-2">
                <button type="button" onclick="closeRejectModal()" class="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-sm font-semibold transition">Cancel</button>
                <button type="submit" class="px-4 py-2 bg-rose-600 hover:bg-rose-500 text-white rounded-xl text-sm font-semibold transition">Confirm Rejection</button>
            </div>
        </form>
    </div>
</div>

<script>
    function openRejectModal(placeId, placeName) {
        document.getElementById('rejectModalText').innerText = `Please specify the reason for rejecting '${placeName}'.`;
        document.getElementById('rejectForm').action = `/admin/places/${placeId}/reject`;
        document.getElementById('rejectModal').classList.remove('hidden');
        document.getElementById('rejectModal').classList.add('flex');
    }

    function closeRejectModal() {
        document.getElementById('rejectModal').classList.remove('flex');
        document.getElementById('rejectModal').classList.add('hidden');
    }
</script>
@endsection
