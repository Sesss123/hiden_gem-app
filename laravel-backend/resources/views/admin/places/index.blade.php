@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <!-- Header & Filter Bar -->
    <div class="glass-card p-6 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4">
        <div>
            <h2 class="text-xl font-bold text-white flex items-center gap-2">
                <i class="fa-solid fa-list-check text-emerald-400"></i> Managed Heritage Gems
            </h2>
            <p class="text-xs text-slate-400 mt-0.5">Showing active places syncing to mobile clients</p>
        </div>
        
        <div class="hidden md:flex items-center ml-auto mr-4">
            <form action="{{ route('admin.places.import') }}" method="POST" enctype="multipart/form-data">
                @csrf
                <input type="file" name="json_file" accept=".json,.jsonl,.txt" class="hidden" id="json_import_file" onchange="if(confirm('Import places from this file?')) this.form.submit();">
                <button type="button" onclick="document.getElementById('json_import_file').click()" class="bg-slate-800 hover:bg-slate-700 text-slate-200 px-3 py-2 rounded-xl text-xs font-semibold transition border border-slate-700 flex items-center gap-2 shadow-lg" title="Import Places from JSON/JSONL">
                    <i class="fa-solid fa-file-import text-emerald-400"></i> Import JSON
                </button>
            </form>
        </div>

        <form action="{{ route('admin.places.index') }}" method="GET" class="flex flex-wrap items-center gap-3 w-full md:w-auto">
            <div class="relative flex-1 md:w-64">
                <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                    <i class="fa-solid fa-magnifying-glass text-xs"></i>
                </span>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search gems, districts..."
                    class="w-full pl-9 pr-4 py-2 bg-slate-900/80 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
            </div>

            <select name="category" onchange="this.form.submit()" class="bg-slate-900/80 border border-slate-700 rounded-xl px-3 py-2 text-xs text-slate-300 focus:outline-none focus:border-emerald-500">
                <option value="">All Categories</option>
                @foreach(\App\Models\Place::select('category')->distinct()->orderBy('category')->pluck('category') as $cat)
                    @if($cat)
                        <option value="{{ $cat }}" {{ request('category') == $cat ? 'selected' : '' }}>{{ $cat }}</option>
                    @endif
                @endforeach
            </select>

            @if(request('search') || request('category'))
                <a href="{{ route('admin.places.index') }}" class="text-xs text-slate-400 hover:text-white px-2 py-2">
                    <i class="fa-solid fa-xmark"></i> Clear
                </a>
            @endif
        </form>
    </div>

    <!-- Places Table -->
    <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/60 text-slate-400 text-xs font-semibold uppercase tracking-wider border-b border-slate-800">
                        <th class="py-4 px-6 hidden md:table-cell">Preview</th>
                        <th class="py-4 px-6">Gem Name & ID</th>
                        <th class="py-4 px-6 hidden sm:table-cell">Location</th>
                        <th class="py-4 px-6 hidden lg:table-cell">Category</th>
                        <th class="py-4 px-6 hidden lg:table-cell">AR / Rating</th>
                        <th class="py-4 px-6 hidden xl:table-cell">Sync Version</th>
                        <th class="py-4 px-6">Status</th>
                        <th class="py-4 px-6 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/60 text-sm">
                    @forelse($places as $place)
                    <tr class="hover:bg-slate-800/40 transition duration-150 group">
                        <td class="py-3 px-6 hidden md:table-cell">
                            @php
                                $thumb = $place->coverImage ? $place->coverImage->thumb_path : $place->image_url;
                            @endphp
                            @if($thumb)
                                <img src="{{ $thumb }}" alt="{{ $place->name }}" class="w-12 h-12 rounded-xl object-cover border border-slate-700 shadow-sm group-hover:scale-105 transition duration-300">
                            @else
                                <div class="w-12 h-12 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-500">
                                    <i class="fa-solid fa-image"></i>
                                </div>
                            @endif
                        </td>
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
                        <td class="py-3 px-6 hidden lg:table-cell">
                            <div class="flex items-center gap-2">
                                @if($place->ar_supported)
                                    <span class="bg-purple-500/20 text-purple-300 border border-purple-500/30 text-[10px] font-bold px-2 py-0.5 rounded uppercase">AR Tier {{ $place->ar_tier }}</span>
                                @endif
                                <span class="text-amber-400 font-bold text-xs flex items-center gap-1">
                                    <i class="fa-solid fa-star"></i> {{ number_format($place->rating, 1) }}
                                </span>
                            </div>
                        </td>
                        <td class="py-3 px-6 hidden xl:table-cell">
                            <span class="font-mono bg-slate-900 px-2.5 py-1 rounded text-xs text-teal-300 font-bold border border-teal-900/40">
                                v{{ $place->sync_version }}
                            </span>
                        </td>
                        <td class="py-3 px-6">
                            @php $pstatus = $place->status ?? 'approved'; @endphp
                            <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2 py-0.5 rounded-md border
                                {{ $pstatus === 'approved' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : ($pstatus === 'rejected' ? 'bg-red-500/10 text-red-400 border-red-500/20' : 'bg-amber-500/10 text-amber-400 border-amber-500/20') }}">
                                {{ ucfirst($pstatus) }}
                            </span>
                        </td>
                        <td class="py-3 px-6 text-right space-x-2">
                            <a href="{{ route('admin.places.edit', $place->id) }}" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-emerald-600 text-slate-300 hover:text-white transition shadow" title="Edit">
                                <i class="fa-solid fa-pen text-xs"></i>
                            </a>
                            @if(auth()->user()->isFullAdmin())
                                <form action="{{ route('admin.places.destroy', $place->id) }}" method="POST" class="inline-block" onsubmit="return confirm('Move {{ $place->name }} to trash? This will soft-delete and increment sync version for mobile clients.')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-red-600 text-slate-300 hover:text-white transition shadow" title="Soft Delete">
                                        <i class="fa-solid fa-trash text-xs"></i>
                                    </button>
                                </form>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="7" class="py-12 text-center text-slate-500">
                            <i class="fa-solid fa-compass text-3xl mb-3 block opacity-40"></i>
                            No hidden gems found. Click "Add New Gem" above to begin seeding the database.
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
