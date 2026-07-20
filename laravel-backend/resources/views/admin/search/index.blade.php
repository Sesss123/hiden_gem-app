@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-magnifying-glass text-emerald-500"></i> Search
        </h2>
        @if($q !== '')
            <p class="text-sm text-slate-400">Results for "<span class="text-slate-200 font-medium">{{ $q }}</span>"</p>
        @else
            <p class="text-sm text-slate-400">Search across Places, Events, Users, Guides, and Partners.</p>
        @endif
    </div>

    @if($tooShort)
        <div class="glass-card rounded-2xl p-8 text-center text-slate-500">
            <i class="fa-solid fa-keyboard text-3xl mb-3 block opacity-40"></i>
            Type at least 2 characters to search.
        </div>
    @elseif($q === '')
        <div class="glass-card rounded-2xl p-8 text-center text-slate-500">
            <i class="fa-solid fa-magnifying-glass text-3xl mb-3 block opacity-40"></i>
            Use the search box in the sidebar to find a place, event, user, guide, or partner.
        </div>
    @else
        @php $totalCount = collect($results)->sum(fn($c) => $c->count()); @endphp

        @if($totalCount === 0)
            <div class="glass-card rounded-2xl p-8 text-center text-slate-500">
                <i class="fa-solid fa-circle-question text-3xl mb-3 block opacity-40"></i>
                No matches found for "{{ $q }}".
            </div>
        @endif

        @if($results['places']->isNotEmpty())
            <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
                <div class="px-6 py-4 border-b border-slate-800 flex items-center justify-between">
                    <h3 class="text-sm font-bold text-white flex items-center gap-2">
                        <i class="fa-solid fa-map-location-dot text-emerald-400"></i> Places
                    </h3>
                    <a href="{{ route('admin.places.index', ['search' => $q]) }}" class="text-xs text-emerald-400 hover:text-emerald-300">
                        View all in Places <i class="fa-solid fa-arrow-right text-[10px]"></i>
                    </a>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <tbody class="divide-y divide-slate-800/60 text-sm">
                            @foreach($results['places'] as $place)
                                <tr class="hover:bg-slate-800/40 transition duration-150">
                                    <td class="py-3 px-6">
                                        @php
                                            $thumb = $place->coverImage ? $place->coverImage->thumb_path : $place->image_url;
                                        @endphp
                                        @if($thumb)
                                            <img src="{{ $thumb }}" alt="{{ $place->name }}" class="w-10 h-10 rounded-lg object-cover border border-slate-700">
                                        @else
                                            <div class="w-10 h-10 rounded-lg bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-500">
                                                <i class="fa-solid fa-image"></i>
                                            </div>
                                        @endif
                                    </td>
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
                                    <td class="py-3 px-6 text-right">
                                        <a href="{{ route('admin.places.edit', $place->id) }}" class="text-slate-400 hover:text-emerald-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Edit">
                                            <i class="fa-solid fa-pen text-xs"></i>
                                        </a>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        @endif

        @if($results['events']->isNotEmpty())
            <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
                <div class="px-6 py-4 border-b border-slate-800 flex items-center justify-between">
                    <h3 class="text-sm font-bold text-white flex items-center gap-2">
                        <i class="fa-solid fa-calendar-days text-teal-400"></i> Events
                    </h3>
                    <a href="{{ route('admin.events.index', ['search' => $q]) }}" class="text-xs text-emerald-400 hover:text-emerald-300">
                        View all in Events <i class="fa-solid fa-arrow-right text-[10px]"></i>
                    </a>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <tbody class="divide-y divide-slate-800/60 text-sm">
                            @foreach($results['events'] as $event)
                                <tr class="hover:bg-slate-800/40 transition duration-150">
                                    <td class="py-3 px-6 font-medium text-white">
                                        <div class="font-bold">{{ $event->name }}</div>
                                    </td>
                                    <td class="py-3 px-6">
                                        <span class="bg-emerald-500/10 text-emerald-400 text-xs px-2.5 py-1 rounded-full font-medium border border-emerald-500/20">
                                            {{ ucfirst($event->category) }}
                                        </span>
                                    </td>
                                    <td class="py-3 px-6 text-slate-300">
                                        <i class="fa-solid fa-location-dot text-slate-500 mr-1.5"></i> {{ $event->location ?? 'Island-wide' }}
                                    </td>
                                    <td class="py-3 px-6 text-right">
                                        <a href="{{ route('admin.events.edit', $event->id) }}" class="text-slate-400 hover:text-emerald-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Edit">
                                            <i class="fa-solid fa-pen-to-square text-xs"></i>
                                        </a>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        @endif

        @if($results['users']->isNotEmpty())
            <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
                <div class="px-6 py-4 border-b border-slate-800 flex items-center justify-between">
                    <h3 class="text-sm font-bold text-white flex items-center gap-2">
                        <i class="fa-solid fa-users text-indigo-400"></i> Users
                    </h3>
                    <a href="{{ route('admin.users.index', ['search' => $q]) }}" class="text-xs text-emerald-400 hover:text-emerald-300">
                        View all in Users <i class="fa-solid fa-arrow-right text-[10px]"></i>
                    </a>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <tbody class="divide-y divide-slate-800/60 text-sm">
                            @foreach($results['users'] as $u)
                                <tr class="hover:bg-slate-800/40 transition duration-150">
                                    <td class="py-3 px-6">
                                        <div class="font-bold text-white">{{ $u->name }}</div>
                                        <div class="text-xs text-slate-400 mt-0.5">{{ $u->email }}</div>
                                    </td>
                                    <td class="py-3 px-6">
                                        <span class="bg-slate-800 text-slate-300 text-xs px-2.5 py-1 rounded-full border border-slate-700 font-medium">
                                            {{ ucfirst(str_replace('_', ' ', $u->role)) }}
                                        </span>
                                    </td>
                                    <td class="py-3 px-6 text-right">
                                        <a href="{{ route('admin.users.edit', $u->id) }}" class="text-slate-400 hover:text-emerald-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Edit">
                                            <i class="fa-solid fa-user-pen text-xs"></i>
                                        </a>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        @endif

        @if($results['guides']->isNotEmpty())
            <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
                <div class="px-6 py-4 border-b border-slate-800 flex items-center justify-between">
                    <h3 class="text-sm font-bold text-white flex items-center gap-2">
                        <i class="fa-solid fa-user-tie text-indigo-400"></i> Guides
                    </h3>
                    <a href="{{ route('admin.guides.index', ['search' => $q]) }}" class="text-xs text-emerald-400 hover:text-emerald-300">
                        View all in Guides <i class="fa-solid fa-arrow-right text-[10px]"></i>
                    </a>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <tbody class="divide-y divide-slate-800/60 text-sm">
                            @foreach($results['guides'] as $app)
                                <tr class="hover:bg-slate-800/40 transition duration-150">
                                    <td class="py-3 px-6">
                                        <div class="font-bold text-white">{{ $app->user->name ?? 'Unknown User' }}</div>
                                        <div class="text-xs text-slate-400 mt-0.5">{{ $app->user->email ?? 'No email' }}</div>
                                    </td>
                                    <td class="py-3 px-6">
                                        <span class="font-mono text-xs text-slate-300 bg-slate-900 border border-slate-800/80 px-2 py-1 rounded">
                                            {{ $app->license_number }}
                                        </span>
                                    </td>
                                    <td class="py-3 px-6 text-right">
                                        <a href="{{ route('admin.guides.show', $app->id) }}" class="text-slate-400 hover:text-emerald-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="View Details">
                                            <i class="fa-solid fa-eye text-xs"></i>
                                        </a>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        @endif

        @if($results['partners']->isNotEmpty())
            <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
                <div class="px-6 py-4 border-b border-slate-800 flex items-center justify-between">
                    <h3 class="text-sm font-bold text-white flex items-center gap-2">
                        <i class="fa-solid fa-handshake text-teal-400"></i> Partners
                    </h3>
                    <a href="{{ route('admin.partners.index', ['search' => $q]) }}" class="text-xs text-emerald-400 hover:text-emerald-300">
                        View all in Partners <i class="fa-solid fa-arrow-right text-[10px]"></i>
                    </a>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <tbody class="divide-y divide-slate-800/60 text-sm">
                            @foreach($results['partners'] as $partner)
                                <tr class="hover:bg-slate-800/40 transition duration-150">
                                    <td class="py-3 px-6 font-bold text-white">{{ $partner['name'] ?? '—' }}</td>
                                    <td class="py-3 px-6">
                                        <span class="bg-emerald-500/10 text-emerald-400 text-xs px-2.5 py-1 rounded-full font-medium border border-emerald-500/20">
                                            {{ ucfirst($partner['category'] ?? 'unknown') }}
                                        </span>
                                    </td>
                                    <td class="py-3 px-6 text-right">
                                        <a href="{{ route('admin.partners.edit', $partner['id']) }}" class="text-slate-400 hover:text-emerald-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Edit">
                                            <i class="fa-solid fa-pen-to-square text-xs"></i>
                                        </a>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        @endif
    @endif
</div>
@endsection
