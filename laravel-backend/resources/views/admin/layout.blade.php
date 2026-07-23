<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hidden Gems SL — Genesis Dashboard</title>
    <link rel="icon" type="image/svg+xml" href="{{ asset('favicon.svg') }}">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    colors: {
                        gem: {
                            50: '#f0fdf4',
                            500: '#10b981',
                            600: '#059669',
                            900: '#064e3b',
                            dark: '#0f172a',
                            card: '#1e293b',
                            border: '#334155'
                        }
                    },
                    fontFamily: {
                        sans: ['Inter', 'sans-serif'],
                    }
                }
            }
        }
    </script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    @stack('head')
    <style>
        body { font-family: 'Inter', sans-serif; }
        .glass-header {
            background: rgba(15, 23, 42, 0.8);
            backdrop-filter: blur(12px);
            border-bottom: 1px solid rgba(51, 65, 85, 0.5);
        }
        .glass-card {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(16px);
            border: 1px solid rgba(51, 65, 85, 0.6);
        }
        .glow-effect:hover {
            box-shadow: 0 0 25px rgba(16, 185, 129, 0.25);
        }
        .sidebar-link {
            position: relative;
            transition: all 0.15s ease;
        }
        .sidebar-link.active {
            background: rgba(16, 185, 129, 0.1);
            color: #34d399;
        }
        .sidebar-link.active::before {
            content: '';
            position: absolute;
            left: 0; top: 8px; bottom: 8px;
            width: 3px;
            border-radius: 0 4px 4px 0;
            background: linear-gradient(180deg, #10b981, #2dd4bf);
        }
        .sidebar-link:not(.active):hover {
            background: rgba(51, 65, 85, 0.4);
            color: #e2e8f0;
        }
        .custom-scrollbar::-webkit-scrollbar { width: 6px; height: 6px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(51, 65, 85, 0.8); border-radius: 3px; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(4px); } to { opacity: 1; transform: translateY(0); } }
        .animate-fadeIn { animation: fadeIn 0.25s ease-out; }
    </style>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen selection:bg-emerald-500 selection:text-white">

@auth
<div class="flex min-h-screen">
    <!-- Mobile-only top bar: hamburger + logo, hidden entirely on md+ -->
    <header class="md:hidden fixed top-0 inset-x-0 z-30 glass-header border-b border-slate-800/60 flex items-center justify-between px-4 py-3">
        <button type="button" onclick="document.getElementById('mobile-sidebar').classList.remove('-translate-x-full'); document.getElementById('sidebar-backdrop').classList.remove('hidden')" class="text-slate-300 hover:text-white p-2 -ml-2" aria-label="Open menu">
            <i class="fa-solid fa-bars text-lg"></i>
        </button>
        <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-gradient-to-tr from-emerald-600 to-teal-400 flex items-center justify-center shrink-0">
                <i class="fa-solid fa-gem text-white text-sm"></i>
            </div>
            <span class="font-bold text-sm tracking-tight bg-gradient-to-r from-emerald-400 to-teal-200 bg-clip-text text-transparent">Hidden Gems SL</span>
        </div>
        <div class="w-9"></div>
    </header>

    <!-- Backdrop overlay, closes the drawer when tapped -->
    <div id="sidebar-backdrop" onclick="document.getElementById('mobile-sidebar').classList.add('-translate-x-full'); this.classList.add('hidden')" class="hidden md:hidden fixed inset-0 bg-black/60 z-40"></div>

    <!-- Sidebar -->
    <aside id="mobile-sidebar" class="w-64 shrink-0 glass-header border-r border-slate-800/60 flex flex-col fixed inset-y-0 left-0 z-50 transform -translate-x-full transition-transform duration-300 ease-in-out md:translate-x-0 md:z-40">
        <div class="px-5 py-5 flex items-center gap-3 border-b border-slate-800/60">
            <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-400 flex items-center justify-center shadow-lg shadow-emerald-900/40 shrink-0">
                <i class="fa-solid fa-gem text-white text-lg"></i>
            </div>
            <div class="min-w-0">
                <h1 class="font-bold text-sm tracking-tight bg-gradient-to-r from-emerald-400 to-teal-200 bg-clip-text text-transparent truncate">Hidden Gems SL</h1>
                <p class="text-[11px] text-slate-500 font-medium">Genesis Admin</p>
            </div>
        </div>

        <div class="px-3 pt-3">
            <form action="{{ route('admin.search') }}" method="GET">
                <div class="relative">
                    <i class="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 text-xs"></i>
                    <input type="text" name="q" value="{{ request()->routeIs('admin.search') ? request('q') : '' }}"
                        minlength="2" placeholder="Search everything..."
                        class="w-full bg-slate-900/80 border border-slate-700 rounded-xl py-2 pl-9 pr-3 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
                </div>
            </form>
        </div>

        <nav class="flex-1 min-h-0 overflow-y-auto custom-scrollbar px-3 py-4 space-y-6">
            @php
                $isFullAdmin = auth()->user()->isFullAdmin();

                $navGroups = [
                    'Content' => [
                        ['route' => 'admin.places.index', 'match' => 'admin.places.index', 'icon' => 'fa-map-location-dot', 'label' => $isFullAdmin ? 'Places' : 'Manage Places', 'color' => 'text-emerald-400'],
                        $isFullAdmin ? ['route' => 'admin.places.pending', 'match' => 'admin.places.pending', 'icon' => 'fa-hourglass-half', 'label' => 'Pending Places', 'color' => 'text-amber-400', 'badgeKey' => 'pendingPlaceCount'] : null,
                        !$isFullAdmin ? ['route' => 'admin.places.my-submissions', 'match' => 'admin.places.my-submissions', 'icon' => 'fa-file-lines', 'label' => 'My Pending Places', 'color' => 'text-amber-400'] : null,
                        ['route' => 'admin.events.index', 'match' => 'admin.events.*', 'icon' => 'fa-calendar-days', 'label' => 'Events', 'color' => 'text-teal-400'],
                        $isFullAdmin ? ['route' => 'admin.partners.index', 'match' => 'admin.partners.*', 'icon' => 'fa-handshake', 'label' => 'Partners', 'color' => 'text-teal-400'] : null,
                    ],
                ];

                if ($isFullAdmin) {
                    $navGroups = [
                        'Overview' => [
                            ['route' => 'admin.dashboard', 'match' => 'admin.dashboard*', 'icon' => 'fa-gauge-high', 'label' => 'Dashboard', 'color' => 'text-emerald-400'],
                        ],
                    ] + $navGroups + [
                        'Operations' => [
                            ['route' => 'admin.bookings.index', 'match' => 'admin.bookings.*', 'icon' => 'fa-calendar-check', 'label' => 'Bookings', 'color' => 'text-sky-400'],
                            ['route' => 'admin.reviews.index', 'match' => 'admin.reviews.*', 'icon' => 'fa-star-half-stroke', 'label' => 'Reviews', 'color' => 'text-amber-400'],
                            ['route' => 'admin.subscriptions.index', 'match' => 'admin.subscriptions.*', 'icon' => 'fa-crown', 'label' => 'Subscriptions', 'color' => 'text-amber-400'],
                        ],
                        'Safety' => [
                            ['route' => 'admin.incidents.index', 'match' => 'admin.incidents.*', 'icon' => 'fa-triangle-exclamation', 'label' => 'Incidents', 'color' => 'text-red-400', 'badgeKey' => 'openIncidentCount'],
                        ],
                        'People' => [
                            ['route' => 'admin.guides.index', 'match' => 'admin.guides.*', 'icon' => 'fa-user-tie', 'label' => 'Guides', 'color' => 'text-indigo-400'],
                            ['route' => 'admin.users.index', 'match' => 'admin.users.*', 'icon' => 'fa-users', 'label' => 'Users', 'color' => 'text-indigo-400'],
                            ['route' => 'admin.audit-log.index', 'match' => 'admin.audit-log.*', 'icon' => 'fa-shield-halved', 'label' => 'Audit Log', 'color' => 'text-slate-400'],
                        ],
                    ];
                }

                $navGroups = collect($navGroups)->map(fn($items) => array_values(array_filter($items)))->all();
            @endphp

            @foreach($navGroups as $groupLabel => $items)
                <div>
                    <p class="px-3 text-[10px] font-bold uppercase tracking-widest text-slate-600 mb-1.5">{{ $groupLabel }}</p>
                    <div class="space-y-0.5">
                        @foreach($items as $item)
                            <a href="{{ route($item['route']) }}"
                               class="sidebar-link {{ request()->routeIs($item['match']) ? 'active' : 'text-slate-400' }} flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium">
                                <i class="fa-solid {{ $item['icon'] }} {{ $item['color'] }} w-4 text-center text-xs"></i>
                                {{ $item['label'] }}
                                @if(!empty($item['badgeKey']) && (${$item['badgeKey']} ?? 0) > 0)
                                    <span class="ml-auto bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full">{{ ${$item['badgeKey']} }}</span>
                                @endif
                            </a>
                        @endforeach
                    </div>
                </div>
            @endforeach
        </nav>

        <div class="shrink-0 px-3 py-4 border-t border-slate-800/60 space-y-2">
            <a href="{{ route('admin.places.create') }}" class="w-full bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-3.5 py-2 rounded-lg text-xs font-semibold shadow-md shadow-emerald-900/30 transition duration-200 flex items-center justify-center gap-1.5 glow-effect">
                <i class="fa-solid fa-plus"></i> Add Gem
            </a>
            <div class="flex items-center justify-between px-1">
                <span class="text-xs text-slate-400 flex items-center gap-1.5 min-w-0">
                    <i class="fa-solid fa-user-shield text-emerald-400 shrink-0"></i>
                    <span class="truncate">{{ auth()->user()->name }}</span>
                </span>
                <form action="{{ route('admin.logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="text-slate-500 hover:text-red-400 transition p-1.5 rounded-lg hover:bg-slate-900 shrink-0" title="Logout">
                        <i class="fa-solid fa-right-from-bracket text-sm"></i>
                    </button>
                </form>
            </div>
        </div>
    </aside>

    <!-- Main Content Area -->
    <div class="flex-1 flex flex-col ml-0 md:ml-64 min-w-0 pt-14 md:pt-0">
        <main class="flex-1 w-full max-w-[2200px] mx-auto p-6 md:p-8 animate-fadeIn">
            @if(session('success'))
                <div class="mb-6 p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-300 flex items-center gap-3 shadow-lg">
                    <i class="fa-solid fa-circle-check text-emerald-400 text-lg"></i>
                    <span class="text-sm font-medium">{{ session('success') }}</span>
                </div>
            @endif

            @if($errors->any())
                <div class="mb-6 p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-300 shadow-lg">
                    <div class="flex items-center gap-2 font-semibold mb-1">
                        <i class="fa-solid fa-triangle-exclamation text-red-400"></i> Please correct the following errors:
                    </div>
                    <ul class="list-disc list-inside text-sm text-red-200/80 space-y-1 ml-5">
                        @foreach($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            @yield('content')
        </main>

        <footer class="border-t border-slate-900 py-5 text-center text-xs text-slate-500">
            <p>&copy; {{ date('Y') }} Hidden Gems SL — Powered by Option A Monotonic Delta Sync Engine</p>
        </footer>
    </div>
</div>
@else
    {{-- Login screen: no sidebar, just the centered content --}}
    <main class="min-h-screen w-full flex items-center justify-center p-6 md:p-8 bg-slate-950">
        @yield('content')
    </main>
@endauth

@stack('scripts')
</body>
</html>
