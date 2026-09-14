@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div class="glass-card p-6 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4 border border-slate-800">
        <div>
            <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
                <i class="fa-solid fa-ban text-red-400"></i> Rejected Places
            </h2>
            <p class="text-sm text-slate-400">Places rejected during moderation. You can review feedback, return items to pending review, or approve them.</p>
        </div>

        <form action="{{ route('admin.places.rejected') }}" method="GET" class="flex flex-wrap items-center gap-3 w-full md:w-auto">
            <div class="relative flex-1 md:w-64">
                <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                    <i class="fa-solid fa-magnifying-glass text-xs"></i>
                </span>
                <input type="text" name="search" value="{{ $search ?? '' }}" placeholder="Search gems, districts..."
                    class="w-full pl-9 pr-4 py-2 bg-slate-900/80 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-red-500 transition">
            </div>

            <select name="category" onchange="this.form.submit()" class="bg-slate-900/80 border border-slate-700 rounded-xl px-3 py-2 text-xs text-slate-300 focus:outline-none focus:border-red-500 transition">
                <option value="">All Categories</option>
                @foreach($categories ?? [] as $cat)
                    @if($cat)
                        <option value="{{ $cat }}" {{ (isset($category) && $category == $cat) ? 'selected' : '' }}>{{ $cat }}</option>
                    @endif
                @endforeach
            </select>

            @if(!empty($search) || !empty($category))
                <a href="{{ route('admin.places.rejected') }}" class="text-xs text-slate-400 hover:text-white px-2 py-2 transition">
                    <i class="fa-solid fa-xmark"></i> Clear
                </a>
            @endif
        </form>
    </div>

    <!-- Desktop Table View (Hidden on mobile <768px) -->
    <div class="hidden md:block glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/60 text-slate-400 text-xs font-semibold uppercase tracking-wider border-b border-slate-800">
                        <th class="py-4 px-6">Gem Name & ID</th>
                        <th class="py-4 px-6">Location</th>
                        <th class="py-4 px-6">Category</th>
                        <th class="py-4 px-6">Creator</th>
                        <th class="py-4 px-6">Rejection Details</th>
                        <th class="py-4 px-6 text-right sticky right-0 bg-slate-900/90 backdrop-blur">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/60 text-sm">
                    @forelse($places as $place)
                    <tr class="hover:bg-slate-800/40 transition duration-150">
                        <td class="py-3 px-6 font-medium text-white">
                            <div class="font-bold flex items-center gap-1.5">
                                {{ $place->name }}
                            </div>
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
                                <span class="text-slate-600 italic">Unclaimed / System</span>
                            @endif
                        </td>
                        <td class="py-3 px-6 max-w-xs">
                            @if(!empty($place->review_reason))
                                <div class="bg-red-500/10 border border-red-500/20 rounded-lg p-2 text-xs text-red-300 font-sans">
                                    <div class="font-semibold text-[10px] text-red-400 uppercase flex items-center gap-1 mb-0.5">
                                        <i class="fa-solid fa-circle-exclamation"></i> Reason
                                    </div>
                                    <div class="line-clamp-2" title="{{ $place->review_reason }}">{{ $place->review_reason }}</div>
                                </div>
                            @else
                                <span class="text-xs text-slate-600 italic">No reason provided</span>
                            @endif
                            <div class="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
                                <i class="fa-regular fa-clock text-[10px]"></i>
                                @if($place->reviewer)
                                    By {{ $place->reviewer->name }} · {{ optional($place->updated_at)->diffForHumans() }}
                                @else
                                    Rejected {{ optional($place->updated_at)->diffForHumans() }}
                                @endif
                            </div>
                        </td>
                        <td class="py-3 px-6 text-right sticky right-0 bg-slate-900/90 backdrop-blur">
                            <div class="flex items-center justify-end gap-1.5">
                                <a href="{{ route('admin.places.edit', $place->id) }}" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition shadow" title="Edit Place">
                                    <i class="fa-solid fa-pen-to-square text-xs"></i>
                                </a>

                                <!-- Return to Pending -->
                                <form action="{{ route('admin.places.return_to_pending', $place->id) }}" method="POST" class="inline-block" onsubmit="return confirm('Return {{ $place->name }} to pending review queue?')">
                                    @csrf
                                    <button type="submit" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-amber-600 text-amber-300 hover:text-white transition shadow" title="Return to Pending Queue">
                                        <i class="fa-solid fa-rotate-left text-xs"></i>
                                    </button>
                                </form>

                                <!-- Direct Approve -->
                                <form action="{{ route('admin.places.approve', $place->id) }}" method="POST" class="inline-block" onsubmit="return confirm('Approve {{ $place->name }} and make it live now?')">
                                    @csrf
                                    <button type="submit" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-emerald-600 text-emerald-300 hover:text-white transition shadow" title="Approve and Make Live">
                                        <i class="fa-solid fa-check text-xs"></i>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="py-12 text-center text-slate-500">
                            <i class="fa-solid fa-circle-check text-3xl mb-3 block opacity-40 text-emerald-500"></i>
                            No rejected places found.
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

    <!-- Mobile Cards View (<768px) -->
    <div class="md:hidden space-y-4">
        @forelse($places as $place)
        <div class="glass-card p-4 rounded-2xl border border-slate-800 space-y-3">
            <div class="flex items-start justify-between gap-2">
                <div>
                    <h3 class="font-bold text-white text-base">{{ $place->name }}</h3>
                    <div class="text-[11px] text-slate-500 font-mono">{{ $place->id }}</div>
                </div>
                <span class="inline-block px-2.5 py-0.5 rounded-full text-xs font-semibold bg-red-500/10 text-red-400 border border-red-500/20">
                    Rejected
                </span>
            </div>

            <div class="flex flex-wrap gap-2 text-xs">
                <span class="bg-slate-900 px-2.5 py-1 rounded-lg text-slate-300 border border-slate-800 flex items-center gap-1">
                    <i class="fa-solid fa-location-dot text-teal-400 text-[10px]"></i> {{ $place->district }}
                </span>
                <span class="bg-slate-900 px-2.5 py-1 rounded-lg text-slate-300 border border-slate-800">
                    {{ $place->category }}
                </span>
            </div>

            @if(!empty($place->review_reason))
            <div class="bg-red-500/10 border border-red-500/20 rounded-xl p-3 text-xs text-red-300">
                <div class="font-bold text-[10px] text-red-400 uppercase mb-1">Rejection Reason</div>
                <div>{{ $place->review_reason }}</div>
            </div>
            @endif

            <div class="text-[11px] text-slate-500 flex items-center justify-between border-t border-slate-800/60 pt-2">
                <span>By {{ $place->creator ? $place->creator->name : 'Unclaimed' }}</span>
                <span>{{ optional($place->updated_at)->diffForHumans() }}</span>
            </div>

            <div class="grid grid-cols-3 gap-2 pt-1 border-t border-slate-800">
                <a href="{{ route('admin.places.edit', $place->id) }}" class="py-2 text-center rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-slate-200">
                    <i class="fa-solid fa-pen-to-square mr-1"></i> Edit
                </a>
                <form action="{{ route('admin.places.return_to_pending', $place->id) }}" method="POST" onsubmit="return confirm('Return {{ $place->name }} to pending?')">
                    @csrf
                    <button type="submit" class="w-full py-2 text-center rounded-xl bg-amber-500/20 hover:bg-amber-500/30 text-xs font-semibold text-amber-300 border border-amber-500/30">
                        <i class="fa-solid fa-rotate-left mr-1"></i> Pending
                    </button>
                </form>
                <form action="{{ route('admin.places.approve', $place->id) }}" method="POST" onsubmit="return confirm('Approve {{ $place->name }}?')">
                    @csrf
                    <button type="submit" class="w-full py-2 text-center rounded-xl bg-emerald-500/20 hover:bg-emerald-500/30 text-xs font-semibold text-emerald-300 border border-emerald-500/30">
                        <i class="fa-solid fa-check mr-1"></i> Approve
                    </button>
                </form>
            </div>
        </div>
        @empty
        <div class="glass-card p-8 rounded-2xl border border-slate-800 text-center text-slate-500">
            <i class="fa-solid fa-circle-check text-3xl mb-3 block opacity-40 text-emerald-500"></i>
            No rejected places found.
        </div>
        @endforelse

        @if($places->hasPages())
            <div class="glass-card p-3 rounded-2xl border border-slate-800">
                {{ $places->links() }}
            </div>
        @endif
    </div>
</div>
@endsection

