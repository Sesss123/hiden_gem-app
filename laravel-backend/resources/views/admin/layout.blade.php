<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hidden Gems SL — Genesis Dashboard</title>
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
    </style>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen flex flex-col selection:bg-emerald-500 selection:text-white">

    <!-- Top Navigation Bar -->
    @auth
    <header class="glass-header sticky top-0 z-50 px-6 py-4 flex items-center justify-between">
        <div class="flex items-center space-x-3">
            <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-400 flex items-center justify-center shadow-lg shadow-emerald-900/40">
                <i class="fa-solid fa-gem text-white text-xl"></i>
            </div>
            <div>
                <h1 class="font-bold text-lg tracking-tight bg-gradient-to-r from-emerald-400 to-teal-200 bg-clip-text text-transparent">Hidden Gems SL</h1>
                <p class="text-xs text-slate-400 font-medium">Genesis Admin Engine</p>
            </div>
        </div>

        <nav class="flex items-center space-x-6">
            <a href="{{ route('admin.dashboard') }}" class="text-sm font-semibold text-emerald-400 hover:text-emerald-300 transition flex items-center gap-2">
                <i class="fa-solid fa-gauge-high"></i> Dashboard
            </a>
            <a href="{{ route('admin.places.index') }}" class="text-sm font-medium hover:text-emerald-400 transition flex items-center gap-2">
                <i class="fa-solid fa-map-location-dot"></i> Places
            </a>
            <a href="{{ route('admin.places.create') }}" class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-4 py-2 rounded-lg text-sm font-semibold shadow-md shadow-emerald-900/30 transition duration-200 flex items-center gap-2 glow-effect">
                <i class="fa-solid fa-plus"></i> Add New Gem
            </a>
            <div class="h-5 w-px bg-slate-800"></div>
            <div class="flex items-center gap-3">
                <span class="text-xs text-slate-400 bg-slate-900 px-3 py-1 rounded-full border border-slate-800">
                    <i class="fa-solid fa-user-shield text-emerald-400 mr-1"></i> {{ auth()->user()->name }}
                </span>
                <form action="{{ route('admin.logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="text-slate-400 hover:text-red-400 transition p-2 rounded-lg hover:bg-slate-900" title="Logout">
                        <i class="fa-solid fa-right-from-bracket"></i>
                    </button>
                </form>
            </div>
        </nav>
    </header>
    @endauth

    <!-- Main Content Area -->
    <main class="flex-1 max-w-7xl w-full mx-auto p-6 md:p-8 animate-fadeIn">
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

    <!-- Footer -->
    <footer class="border-t border-slate-900 py-6 text-center text-xs text-slate-500">
        <p>&copy; {{ date('Y') }} Hidden Gems SL — Powered by Option A Monotonic Delta Sync Engine</p>
    </footer>

</body>
</html>
