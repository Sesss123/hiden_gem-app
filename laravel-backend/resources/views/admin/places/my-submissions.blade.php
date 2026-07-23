@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-file-lines text-emerald-400"></i> My Pending Places
        </h2>
        <p class="text-sm text-slate-400">Places you've created or edited, and their current approval status.</p>
    </div>

    @php $activeStatus = request('status', 'pending'); @endphp
    <div class="glass-card p-4 rounded-2xl flex items-center gap-2">
        <a href="{{ route('admin.places.my-submissions', ['status' => 'pending']) }}"
            class="px-3 py-1.5 rounded-lg text-xs font-semibold {{ $activeStatus === 'pending' ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20' : 'text-slate-400 hover:text-white' }}">Pending</a>
        <a href="{{ route('admin.places.my-submissions', ['status' => 'all']) }}"
            class="px-3 py-1.5 rounded-lg text-xs font-semibold {{ $activeStatus === 'all' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'text-slate-400 hover:text-white' }}">All</a>
        <a href="{{ route('admin.places.my-submissions', ['status' => 'approved']) }}"
            class="px-3 py-1.5 rounded-lg text-xs font-semibold {{ $activeStatus === 'approved' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'text-slate-400 hover:text-white' }}">Approved</a>
        <a href="{{ route('admin.places.my-submissions', ['status' => 'rejected']) }}"
            class="px-3 py-1.5 rounded-lg text-xs font-semibold {{ $activeStatus === 'rejected' ? 'bg-red-500/10 text-red-400 border border-red-500/20' : 'text-slate-400 hover:text-white' }}">Rejected</a>
    </div>

    <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/60 text-slate-400 text-xs font-semibold uppercase tracking-wider border-b border-slate-800">
                        <th class="py-4 px-6">Gem Name & ID</th>
                        <th class="py-4 px-6 hidden sm:table-cell">Location</th>
                        <th class="py-4 px-6 hidden lg:table-cell">Category</th>
                        <th class="py-4 px-6">Status</th>
                        <th class="py-4 px-6 hidden md:table-cell">Last Updated</th>
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
                        <td class="py-3 px-6 text-slate-300 hidden sm:table-cell">
                            <span class="inline-flex items-center gap-1 bg-slate-900 px-2.5 py-1 rounded-lg text-xs text-slate-300 border border-slate-800">
                                <i class="fa-solid fa-location-dot text-teal-400 text-[10px]"></i> {{ $place->district }}
                            </span>
                        </td>
                        <td class="py-3 px-6 hidden lg:table-cell">
                            <span class="inline-block px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                                {{ $place->category }}
                            </span>
                        </td>
                        <td class="py-3 px-6">
                            @php $pstatus = $place->status ?? 'approved'; @endphp
                            <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2 py-0.5 rounded-md border
                                {{ $pstatus === 'approved' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : ($pstatus === 'rejected' ? 'bg-red-500/10 text-red-400 border-red-500/20' : 'bg-amber-500/10 text-amber-400 border-amber-500/20') }}">
                                {{ ucfirst($pstatus) }}
                            </span>
                            @if($pstatus === 'rejected' && $place->review_reason)
                                <div class="text-[11px] text-slate-500 mt-1 max-w-xs">{{ $place->review_reason }}</div>
                            @endif
                        </td>
                        <td class="py-3 px-6 text-slate-400 font-mono text-xs hidden md:table-cell">
                            {{ $place->updated_at ? $place->updated_at->diffForHumans() : 'N/A' }}
                        </td>
                        <td class="py-3 px-6 text-right">
                            <a href="{{ route('admin.places.edit', $place->id) }}" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-emerald-600 text-slate-300 hover:text-white transition shadow" title="Edit">
                                <i class="fa-solid fa-pen text-xs"></i>
                            </a>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="py-12 text-center text-slate-500">
                            <i class="fa-solid fa-inbox text-3xl mb-3 block opacity-40"></i>
                            No submissions yet.
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($places->hasPages())
            <div class="p-4 border-t border-slate-800 bg-slate-900/40">
                {{ $places->appends(request()->query())->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
