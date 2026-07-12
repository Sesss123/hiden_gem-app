@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
            <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
                <i class="fa-solid fa-handshake text-emerald-500"></i> Curator Partners
            </h2>
            <p class="text-sm text-slate-400">Manage boutique stays, cafes, and guides shown as nearby partners — flag one as a premium deal to surface it in the app's Curator Deals screen.</p>
        </div>
        <div>
            <a href="{{ route('admin.partners.create') }}" class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-4 py-2 rounded-xl text-sm font-semibold shadow-md shadow-emerald-950/20 transition duration-200 flex items-center gap-2 glow-effect">
                <i class="fa-solid fa-plus"></i> Add Partner
            </a>
        </div>
    </div>

    <!-- Filter & Search Bar -->
    <div class="glass-card p-4 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4">
        <form action="{{ route('admin.partners.index') }}" method="GET" class="w-full flex flex-col md:flex-row gap-4">
            <div class="flex-1 relative">
                <i class="fa-solid fa-magnifying-glass absolute left-4 top-3 text-slate-400"></i>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search by name or category..." class="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 pl-11 pr-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500/50 transition">
            </div>
            <div class="flex gap-2">
                <button type="submit" class="bg-slate-800 hover:bg-slate-700 text-white px-5 py-2.5 rounded-xl text-sm font-semibold border border-slate-700 transition">
                    Filter
                </button>
                @if(request('search'))
                    <a href="{{ route('admin.partners.index') }}" class="bg-slate-900 hover:bg-slate-850 text-slate-400 border border-slate-800 px-5 py-2.5 rounded-xl text-sm font-semibold transition flex items-center justify-center">
                        Clear
                    </a>
                @endif
            </div>
        </form>
    </div>

    <!-- Partners List Table -->
    <div class="glass-card rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-6 py-4">Partner</th>
                        <th class="px-6 py-4">Category</th>
                        <th class="px-6 py-4">Curator Deal</th>
                        <th class="px-6 py-4">Verified</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($partners as $partner)
                        <tr class="hover:bg-slate-900/30 transition">
                            <td class="px-6 py-5">
                                <div class="font-bold text-white">{{ $partner['name'] ?? '—' }}</div>
                                <div class="text-xs text-slate-400 max-w-xs truncate mt-0.5">{{ $partner['description'] ?? '' }}</div>
                            </td>
                            <td class="px-6 py-5">
                                <span class="bg-emerald-500/10 text-emerald-400 text-xs px-2.5 py-1 rounded-full font-medium border border-emerald-500/20">
                                    {{ ucfirst($partner['category'] ?? 'unknown') }}
                                </span>
                            </td>
                            <td class="px-6 py-5 text-slate-300">
                                @if(!empty($partner['isPremiumDeal']))
                                    <span class="inline-flex items-center gap-1.5 text-xs text-amber-400 font-semibold bg-amber-500/5 px-2 py-0.5 rounded-md border border-amber-500/10">
                                        <i class="fa-solid fa-tag"></i> {{ $partner['discountPercent'] ?? 0 }}% off
                                    </span>
                                @else
                                    <span class="text-slate-500 text-xs">None</span>
                                @endif
                            </td>
                            <td class="px-6 py-5">
                                @if(!empty($partner['isVerified']))
                                    <span class="inline-flex items-center gap-1.5 text-xs text-emerald-400 font-semibold bg-emerald-500/5 px-2 py-0.5 rounded-md border border-emerald-500/10">
                                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-400"></span> Verified
                                    </span>
                                @else
                                    <span class="inline-flex items-center gap-1.5 text-xs text-slate-400 font-semibold bg-slate-800 px-2 py-0.5 rounded-md border border-slate-700">
                                        <span class="w-1.5 h-1.5 rounded-full bg-slate-500"></span> Unverified
                                    </span>
                                @endif
                            </td>
                            <td class="px-6 py-5 text-right">
                                <div class="flex items-center justify-end gap-2">
                                    <a href="{{ route('admin.partners.edit', $partner['id']) }}" class="text-slate-400 hover:text-emerald-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Edit">
                                        <i class="fa-solid fa-pen-to-square"></i>
                                    </a>
                                    <form action="{{ route('admin.partners.destroy', $partner['id']) }}" method="POST" onsubmit="return confirm('Are you sure you want to remove this partner?');" class="inline">
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
                            <td colspan="5" class="px-6 py-10 text-center text-slate-500">
                                <div class="flex flex-col items-center justify-center gap-2">
                                    <i class="fa-solid fa-handshake-slash text-3xl text-slate-600"></i>
                                    <span>No curator partners registered yet.</span>
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
