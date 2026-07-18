@extends('admin.layout')

@push('head')
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
@endpush

@section('content')
<div class="space-y-8 animate-fadeIn">
    <!-- Welcome Header & Quick Stats Banner -->
    <div class="glass-card p-6 md:p-8 rounded-3xl border border-slate-800 bg-gradient-to-r from-slate-900 via-slate-900/90 to-emerald-950/30 shadow-2xl relative overflow-hidden">
        <div class="absolute -right-10 -bottom-10 w-64 h-64 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none"></div>
        <div class="absolute -left-10 -top-10 w-64 h-64 bg-teal-500/10 rounded-full blur-3xl pointer-events-none"></div>
        
        <div class="relative z-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
            <div>
                <span class="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 mb-3">
                    <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span> System Live & Operational
                </span>
                <h2 class="text-2xl md:text-3xl font-extrabold text-white tracking-tight">
                    Enterprise Analytics & Overview
                </h2>
                <p class="text-sm text-slate-400 mt-1 max-w-2xl">
                    Real-time intelligence from your Hidden Gems Sri Lanka backend, tracking subscriptions, AR models, user wishlist bookmarks, and spatial geodata.
                </p>
            </div>
            <div class="flex items-center gap-3">
                <a href="{{ route('admin.places.create') }}" class="bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 hover:to-teal-400 text-slate-950 font-bold px-5 py-3 rounded-xl shadow-lg shadow-emerald-500/20 transition duration-200 flex items-center gap-2 text-sm transform hover:-translate-y-0.5">
                    <i class="fa-solid fa-plus-circle"></i> Add New Gem
                </a>
                <a href="{{ route('admin.places.index') }}" class="bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold px-5 py-3 rounded-xl border border-slate-700 transition duration-200 flex items-center gap-2 text-sm">
                    <i class="fa-solid fa-list-ul"></i> Manage Places
                </a>
            </div>
        </div>
    </div>

    <!-- 4 Key Metric Stat Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
        <!-- Total Places -->
        <div class="glass-card p-6 rounded-2xl border border-slate-800 hover:border-emerald-500/40 transition duration-300 relative overflow-hidden group">
            <div class="flex justify-between items-start mb-4">
                <div class="w-12 h-12 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 group-hover:scale-110 transition duration-300">
                    <i class="fa-solid fa-map-location-dot text-2xl"></i>
                </div>
                <span class="text-xs font-bold text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-full border border-emerald-500/20 shrink-0 whitespace-nowrap">
                    100% Active
                </span>
            </div>
            <h3 class="text-3xl font-black text-white tracking-tight">{{ number_format($totalPlaces) }}</h3>
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider mt-1">Total Hidden Gems</p>
            <div class="mt-3 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
                <span>🟢 {{ $totalPlaces - ($proPlaces + $vipPlaces) }} Public</span>
                <span>👑 {{ $proPlaces + $vipPlaces }} Premium</span>
            </div>
        </div>

        <!-- Premium Access Gems -->
        <div class="glass-card p-6 rounded-2xl border border-slate-800 hover:border-amber-500/40 transition duration-300 relative overflow-hidden group">
            <div class="flex justify-between items-start mb-4">
                <div class="w-12 h-12 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400 group-hover:scale-110 transition duration-300">
                    <i class="fa-solid fa-crown text-2xl"></i>
                </div>
                <span class="text-xs font-bold text-amber-400 bg-amber-500/10 px-2.5 py-1 rounded-full border border-amber-500/20 shrink-0 whitespace-nowrap">
                    Monetized
                </span>
            </div>
            <h3 class="text-3xl font-black text-amber-300 tracking-tight">{{ number_format($proPlaces + $vipPlaces) }}</h3>
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider mt-1">Exclusive Tier Gems</p>
            <div class="mt-3 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
                <span>⭐ {{ $proPlaces }} PRO</span>
                <span>👑 {{ $vipPlaces }} VIP Exclusive</span>
            </div>
        </div>

        <!-- AR Supported Places -->
        <div class="glass-card p-6 rounded-2xl border border-slate-800 hover:border-cyan-500/40 transition duration-300 relative overflow-hidden group">
            <div class="flex justify-between items-start mb-4">
                <div class="w-12 h-12 rounded-xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center text-cyan-400 group-hover:scale-110 transition duration-300">
                    <i class="fa-solid fa-cube text-2xl"></i>
                </div>
                <span class="text-xs font-bold text-cyan-400 bg-cyan-500/10 px-2.5 py-1 rounded-full border border-cyan-500/20 shrink-0 whitespace-nowrap">
                    3D Ready
                </span>
            </div>
            <h3 class="text-3xl font-black text-cyan-300 tracking-tight">{{ number_format($arPlaces) }}</h3>
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider mt-1">AR Supported Sites</p>
            <div class="mt-3 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
                <span>QR Scan Ready</span>
                <span>{{ $totalPlaces > 0 ? round(($arPlaces / $totalPlaces) * 100) : 0 }}% of Total</span>
            </div>
        </div>

        <!-- Wishlist Bookmarks -->
        <div class="glass-card p-6 rounded-2xl border border-slate-800 hover:border-rose-500/40 transition duration-300 relative overflow-hidden group">
            <div class="flex justify-between items-start mb-4">
                <div class="w-12 h-12 rounded-xl bg-rose-500/10 border border-rose-500/20 flex items-center justify-center text-rose-400 group-hover:scale-110 transition duration-300">
                    <i class="fa-solid fa-heart text-2xl"></i>
                </div>
                <span class="text-xs font-bold text-rose-400 bg-rose-500/10 px-2.5 py-1 rounded-full border border-rose-500/20 shrink-0 whitespace-nowrap">
                    User Wishlist
                </span>
            </div>
            <h3 class="text-3xl font-black text-rose-300 tracking-tight">{{ number_format($totalWishlists) }}</h3>
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider mt-1">Total Saved Bookmarks</p>
            <div class="mt-3 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
                <span>👥 {{ $totalUsers }} Users</span>
                <span>⭐ {{ $proUsers + $vipUsers }} Subscribers</span>
            </div>
        </div>
    </div>

    <!-- Charts Row -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div class="glass-card p-6 rounded-2xl border border-slate-800 lg:col-span-1">
            <h3 class="font-bold text-base text-white flex items-center gap-2 mb-4">
                <i class="fa-solid fa-chart-pie text-emerald-400"></i> Access Tier Split
            </h3>
            <div class="h-56 relative">
                <canvas id="tierChart"></canvas>
            </div>
        </div>
        <div class="glass-card p-6 rounded-2xl border border-slate-800 lg:col-span-2">
            <h3 class="font-bold text-base text-white flex items-center gap-2 mb-4">
                <i class="fa-solid fa-chart-column text-teal-400"></i> Top Categories
            </h3>
            <div class="h-56">
                <canvas id="categoryChart"></canvas>
            </div>
        </div>
    </div>

    <!-- AI Duplicate Detection & Database Integrity Scanner -->
    @if($duplicates->isNotEmpty())
        <div class="p-6 rounded-3xl bg-amber-500/10 border-2 border-amber-500/40 shadow-2xl relative overflow-hidden">
            <div class="flex items-start gap-4">
                <div class="w-12 h-12 rounded-2xl bg-amber-500/20 border border-amber-500/40 flex items-center justify-center text-amber-400 shrink-0 mt-0.5 animate-bounce">
                    <i class="fa-solid fa-triangle-exclamation text-2xl"></i>
                </div>
                <div class="flex-1">
                    <div class="flex items-center justify-between flex-wrap gap-2">
                        <h3 class="text-lg font-black text-amber-300 tracking-tight flex items-center gap-2">
                            ⚠️ AI Duplicate Detection Alert
                        </h3>
                        <span class="bg-amber-500 text-slate-950 text-xs font-black px-3 py-1 rounded-full uppercase tracking-wider">
                            {{ $duplicates->count() }} Duplicate Groups Found
                        </span>
                    </div>
                    <p class="text-xs text-amber-200/80 mt-1">
                        Our AI Integrity Scanner detected places with identical names in the same district. Please review and remove or rename accidental duplicates.
                    </p>

                    <div class="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                        @foreach($duplicates as $dup)
                            <div class="p-3 rounded-xl bg-slate-900/90 border border-amber-500/30 flex flex-col justify-between">
                                <div>
                                    <div class="flex justify-between items-start">
                                        <h4 class="text-xs font-bold text-white truncate">{{ $dup->name }}</h4>
                                        <span class="text-[10px] font-extrabold bg-red-500/20 text-red-400 px-2 py-0.5 rounded border border-red-500/30">{{ $dup->cnt }}x Copies</span>
                                    </div>
                                    <p class="text-[11px] text-slate-400 mt-0.5"><i class="fa-solid fa-location-dot text-amber-400 mr-1"></i> {{ $dup->district }}</p>
                                </div>
                                <div class="mt-2 pt-2 border-t border-slate-800 flex items-center justify-between text-[10px] text-slate-400">
                                    <span>IDs: <strong class="text-slate-200">{{ $dup->duplicate_ids }}</strong></span>
                                    <a href="{{ route('admin.places.index', ['search' => $dup->name]) }}" class="text-amber-400 hover:underline font-bold flex items-center gap-1">
                                        Fix <i class="fa-solid fa-arrow-right"></i>
                                    </a>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            </div>
        </div>
    @else
        <div class="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-between text-emerald-300 shadow-lg">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-emerald-500/20 flex items-center justify-center text-emerald-400 text-lg">
                    <i class="fa-solid fa-shield-halved"></i>
                </div>
                <div>
                    <h4 class="text-sm font-bold text-white">AI Database Integrity Scanner: 100% Clean</h4>
                    <p class="text-xs text-emerald-300/80">No duplicate places or conflicting records detected across all {{ number_format($totalPlaces) }} hidden gems.</p>
                </div>
            </div>
            <span class="text-xs font-bold bg-emerald-500/20 text-emerald-300 px-3 py-1 rounded-full border border-emerald-500/30">
                <i class="fa-solid fa-check mr-1"></i> Verified Clean
            </span>
        </div>
    @endif

    <!-- Analytics Section: Districts & Categories -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- District Breakdown -->
        <div class="glass-card p-6 rounded-2xl border border-slate-800">
            <div class="flex items-center justify-between border-b border-slate-800 pb-4 mb-4">
                <h3 class="font-bold text-base text-white flex items-center gap-2">
                    <i class="fa-solid fa-map-pin text-emerald-400"></i> All Districts Breakdown (Sri Lanka)
                </h3>
                <span class="text-xs text-slate-400 font-medium">All 25 Districts</span>
            </div>
            
            <div class="space-y-4">
                @forelse($byDistrict as $index => $item)
                    @php
                        $percentage = $totalPlaces > 0 ? round(($item->total / $totalPlaces) * 100) : 0;
                    @endphp
                    @if($index === 10)
                        </div>
                        <div id="more-districts-box" class="hidden space-y-4 pt-4 mt-4 border-t border-slate-800/80">
                    @endif
                    <div>
                        <div class="flex justify-between text-xs font-semibold mb-1">
                            <span class="text-slate-300"><span class="text-slate-500 mr-1">{{ $index + 1 }}.</span> {{ $item->district ?: 'Unassigned' }}</span>
                            <span class="text-emerald-400">{{ $item->total }} Places (<span class="text-slate-400">{{ $percentage }}%</span>)</span>
                        </div>
                        <div class="w-full h-2 bg-slate-800 rounded-full overflow-hidden">
                            <div class="h-full bg-gradient-to-r from-emerald-500 to-teal-400 rounded-full" style="width: {{ $percentage }}%"></div>
                        </div>
                    </div>
                @empty
                    <p class="text-sm text-slate-500 py-4 text-center">No district data available yet.</p>
                @endforelse
                @if($byDistrict->count() > 10)
                    </div>
                    <button type="button" onclick="toggleDistricts()" class="w-full mt-4 py-2.5 px-4 rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-800 hover:border-emerald-500/40 text-xs font-bold text-emerald-400 hover:text-emerald-300 transition duration-200 flex items-center justify-center gap-2">
                        <span id="toggle-btn-text">🔻 Show {{ $byDistrict->count() - 10 }} More Districts</span>
                    </button>
                    <script>
                        function toggleDistricts() {
                            const box = document.getElementById('more-districts-box');
                            const text = document.getElementById('toggle-btn-text');
                            if (box.classList.contains('hidden')) {
                                box.classList.remove('hidden');
                                text.innerHTML = '🔺 Show Less (Top 10 Only)';
                            } else {
                                box.classList.add ("hidden");
                                text.innerHTML = '🔻 Show {{ $byDistrict->count() - 10 }} More Districts';
                            }
                        }
                    </script>
                @else
                    </div>
                @endif
            </div>
        </div>

        <!-- Category Distribution -->
        <div class="glass-card p-6 rounded-2xl border border-slate-800">
            <div class="flex items-center justify-between border-b border-slate-800 pb-4 mb-4">
                <h3 class="font-bold text-base text-white flex items-center gap-2">
                    <i class="fa-solid fa-layer-group text-teal-400"></i> Top Categories & Heritage Types
                </h3>
                <span class="text-xs text-slate-400 font-medium">Top 12 Categories</span>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 max-h-[480px] overflow-y-auto pr-2 custom-scrollbar">
                @forelse($byCategory as $cat)
                    <div class="p-4 rounded-xl bg-slate-900/80 border border-slate-800/80 flex items-center justify-between hover:border-teal-500/30 transition">
                        <div class="flex items-center gap-3">
                            <div class="w-9 h-9 rounded-lg bg-teal-500/10 border border-teal-500/20 flex items-center justify-center text-teal-400 text-sm">
                                <i class="fa-solid fa-tag"></i>
                            </div>
                            <div>
                                <h4 class="text-xs font-bold text-white truncate max-w-[120px]">{{ $cat->category ?: 'General' }}</h4>
                                <p class="text-[10px] text-slate-400">Heritage Site</p>
                            </div>
                        </div>
                        <span class="text-sm font-extrabold text-teal-300 bg-teal-500/10 px-2.5 py-1 rounded-lg border border-teal-500/20">
                            {{ $cat->total }}
                        </span>
                    </div>
                @empty
                    <p class="text-sm text-slate-500 py-4 text-center col-span-2">No categories available yet.</p>
                @endforelse
            </div>
        </div>
    </div>





    <!-- Recently Updated Hidden Gems Table -->
    <div class="glass-card p-6 rounded-2xl border border-slate-800">
        <div class="flex items-center justify-between border-b border-slate-800 pb-4 mb-6">
            <div>
                <h3 class="font-bold text-base text-white flex items-center gap-2">
                    <i class="fa-solid fa-clock-rotate-left text-emerald-400"></i> Recently Updated Hidden Gems
                </h3>
                <p class="text-xs text-slate-400 mt-0.5">The most recent modifications across Sri Lanka's districts.</p>
            </div>
            <a href="{{ route('admin.places.index') }}" class="text-xs font-semibold text-emerald-400 hover:text-emerald-300 transition flex items-center gap-1">
                View All Places <i class="fa-solid fa-arrow-right"></i>
            </a>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="border-b border-slate-800 text-slate-400 font-semibold text-xs uppercase tracking-wider">
                        <th class="py-3 px-4">Place Name</th>
                        <th class="py-3 px-4">District</th>
                        <th class="py-3 px-4">Category</th>
                        <th class="py-3 px-4">Access Tier</th>
                        <th class="py-3 px-4">AR Supported</th>
                        <th class="py-3 px-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/60 text-xs">
                    @forelse($recentPlaces as $place)
                        <tr class="hover:bg-slate-900/50 transition">
                            <td class="py-3.5 px-4 font-bold text-white flex items-center gap-3">
                                @if($place->images->isNotEmpty())
                                    @php $cover = $place->images->firstWhere('is_cover', true) ?? $place->images->first(); @endphp
                                    <img src="{{ asset($cover->thumb_path) }}" alt="" class="w-8 h-8 rounded-lg object-cover border border-slate-700">
                                @else
                                    <div class="w-8 h-8 rounded-lg bg-slate-800 flex items-center justify-center text-slate-500">
                                        <i class="fa-solid fa-image"></i>
                                    </div>
                                @endif
                                <span>{{ $place->name }}</span>
                            </td>
                            <td class="py-3.5 px-4 text-slate-300 font-medium">{{ $place->district }}</td>
                            <td class="py-3.5 px-4 text-slate-400">{{ $place->category }}</td>
                            <td class="py-3.5 px-4">
                                @if($place->access_tier === 'VIP')
                                    <span class="inline-flex items-center gap-1 bg-amber-500/10 text-amber-400 border border-amber-500/20 px-2.5 py-0.5 rounded-full font-bold">
                                        👑 VIP Exclusive
                                    </span>
                                @elseif($place->access_tier === 'PRO')
                                    <span class="inline-flex items-center gap-1 bg-teal-500/10 text-teal-300 border border-teal-500/20 px-2.5 py-0.5 rounded-full font-bold">
                                        ⭐ PRO Subscriber
                                    </span>
                                @else
                                    <span class="inline-flex items-center gap-1 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2.5 py-0.5 rounded-full font-medium">
                                        🟢 Free (Public)
                                    </span>
                                @endif
                            </td>
                            <td class="py-3.5 px-4">
                                @if($place->ar_supported)
                                    <span class="text-cyan-400 font-semibold flex items-center gap-1"><i class="fa-solid fa-cube"></i> Tier {{ $place->ar_tier }}</span>
                                @else
                                    <span class="text-slate-500">No</span>
                                @endif
                            </td>
                            <td class="py-3.5 px-4 text-right space-x-2">
                                <a href="{{ route('admin.places.edit', $place->id) }}" class="bg-slate-800 hover:bg-slate-700 text-slate-200 px-3 py-1.5 rounded-lg border border-slate-700 font-medium transition inline-flex items-center gap-1">
                                    <i class="fa-solid fa-pen-to-square"></i> Edit
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="py-8 text-center text-slate-500">No places added yet.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

@push('scripts')
<script>
    Chart.defaults.color = '#94a3b8';
    Chart.defaults.font.family = "'Inter', sans-serif";
    Chart.defaults.font.size = 11;

    new Chart(document.getElementById('tierChart'), {
        type: 'doughnut',
        data: {
            labels: ['Free (Public)', 'PRO', 'VIP Exclusive'],
            datasets: [{
                data: [
                    {{ $totalPlaces - ($proPlaces + $vipPlaces) }},
                    {{ $proPlaces }},
                    {{ $vipPlaces }},
                ],
                backgroundColor: ['#10b981', '#2dd4bf', '#f59e0b'],
                borderColor: '#1e293b',
                borderWidth: 3,
            }],
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '68%',
            plugins: {
                legend: { position: 'bottom', labels: { padding: 14, boxWidth: 10, boxHeight: 10 } },
            },
        },
    });

    new Chart(document.getElementById('categoryChart'), {
        type: 'bar',
        data: {
            labels: {!! json_encode($byCategory->pluck('category')->map(fn($c) => $c ?: 'General')) !!},
            datasets: [{
                label: 'Places',
                data: {!! json_encode($byCategory->pluck('total')) !!},
                backgroundColor: '#2dd4bf',
                borderRadius: 6,
                maxBarThickness: 36,
            }],
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                x: { grid: { display: false } },
                y: { beginAtZero: true, grid: { color: 'rgba(51, 65, 85, 0.4)' }, ticks: { precision: 0 } },
            },
        },
    });
</script>
@endpush
@endsection
