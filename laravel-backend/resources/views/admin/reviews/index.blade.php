@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-star-half-stroke text-amber-500"></i> Review Moderation
        </h2>
        <p class="text-sm text-slate-400">Tour reviews left by tourists for guides.</p>
    </div>

    <div class="flex flex-wrap gap-2">
        @foreach(['flagged' => 'Flagged', 'under_review' => 'Under Review', 'hidden' => 'Hidden', 'active' => 'Active', 'all' => 'All'] as $key => $label)
            <a href="{{ route('admin.reviews.index', ['status' => $key]) }}"
               class="px-4 py-2 rounded-xl text-sm font-semibold transition {{ $status === $key ? 'bg-amber-500/20 text-amber-300 border border-amber-500/40' : 'bg-slate-900 text-slate-400 border border-slate-800 hover:text-white' }}">
                {{ $label }}
            </a>
        @endforeach
    </div>

    <div class="glass-card rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-6 py-4">Review</th>
                        <th class="px-6 py-4">Rating</th>
                        <th class="px-6 py-4">Guide / Tourist</th>
                        <th class="px-6 py-4">Filed</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($reviews as $review)
                        <tr class="hover:bg-slate-900/30 transition">
                            <td class="px-6 py-5 max-w-sm">
                                <div class="text-slate-200 text-sm">{{ \Illuminate\Support\Str::limit($review['comment'] ?? '', 120) }}</div>
                                @if(!empty($review['isFlagged']))
                                    <div class="text-[10px] text-red-400 mt-1"><i class="fa-solid fa-flag"></i> {{ $review['flagReason'] ?? 'Flagged' }}</div>
                                @endif
                            </td>
                            <td class="px-6 py-5">
                                <span class="text-amber-400 font-bold">{{ number_format($review['overallRating'] ?? 0, 1) }}</span>
                                <i class="fa-solid fa-star text-amber-400 text-xs ml-0.5"></i>
                            </td>
                            <td class="px-6 py-5 text-slate-300 text-xs">
                                <div>G: {{ \Illuminate\Support\Str::limit($review['guideId'] ?? 'N/A', 16) }}</div>
                                <div>T: {{ \Illuminate\Support\Str::limit($review['touristId'] ?? 'N/A', 16) }}</div>
                            </td>
                            <td class="px-6 py-5 text-slate-400 font-mono text-xs">
                                {{ \Illuminate\Support\Str::of($review['createdAt'] ?? '')->limit(16, '') }}
                            </td>
                            <td class="px-6 py-5">
                                @php $mst = $review['moderationStatus'] ?? 'active'; @endphp
                                <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2 py-0.5 rounded-md border
                                    {{ $mst === 'hidden' ? 'bg-red-500/10 text-red-400 border-red-500/20' : ($mst === 'active' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : 'bg-amber-500/10 text-amber-400 border-amber-500/20') }}">
                                    {{ ucfirst(str_replace('_', ' ', $mst)) }}
                                </span>
                            </td>
                            <td class="px-6 py-5 text-right">
                                <div class="flex items-center justify-end gap-2">
                                    @if($mst !== 'hidden')
                                        <button type="button" onclick="document.getElementById('hide-modal-{{ $review['id'] }}').classList.remove('hidden')"
                                            class="text-slate-400 hover:text-red-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Hide">
                                            <i class="fa-solid fa-eye-slash"></i>
                                        </button>
                                    @else
                                        <form action="{{ route('admin.reviews.restore', $review['id']) }}" method="POST" class="inline">
                                            @csrf
                                            <button type="submit" class="text-slate-400 hover:text-emerald-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Restore">
                                                <i class="fa-solid fa-rotate-left"></i>
                                            </button>
                                        </form>
                                    @endif
                                </div>
                            </td>
                        </tr>

                        <!-- Hide reason modal -->
                        <tr id="hide-modal-{{ $review['id'] }}" class="hidden">
                            <td colspan="6" class="px-6 py-4 bg-slate-900/50">
                                <form action="{{ route('admin.reviews.hide', $review['id']) }}" method="POST" class="flex items-center gap-3">
                                    @csrf
                                    <input type="text" name="reason" required maxlength="500" placeholder="Reason for hiding this review..."
                                        class="flex-1 bg-slate-950 border border-slate-800 rounded-xl py-2 px-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-red-500/50 transition">
                                    <button type="submit" class="bg-red-600 hover:bg-red-500 text-white px-4 py-2 rounded-xl text-xs font-semibold transition">
                                        Confirm Hide
                                    </button>
                                    <button type="button" onclick="document.getElementById('hide-modal-{{ $review['id'] }}').classList.add('hidden')"
                                        class="text-slate-400 text-xs px-2">Cancel</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-10 text-center text-slate-500">
                                <div class="flex flex-col items-center justify-center gap-2">
                                    <i class="fa-solid fa-comment-slash text-3xl text-slate-600"></i>
                                    <span>No reviews in this category.</span>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
