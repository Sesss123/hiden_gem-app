@extends('admin.layout')

@section('content')
<div class="min-h-[80vh] flex items-center justify-center">
    <div class="max-w-md w-full glass-card p-8 rounded-2xl shadow-2xl relative overflow-hidden">
        <!-- Decorative background blur -->
        <div class="absolute -top-12 -right-12 w-40 h-40 bg-emerald-500/20 rounded-full blur-3xl pointer-events-none"></div>
        <div class="absolute -bottom-12 -left-12 w-40 h-40 bg-teal-500/20 rounded-full blur-3xl pointer-events-none"></div>

        <div class="text-center mb-8 relative z-10">
            <div class="w-16 h-16 bg-gradient-to-tr from-emerald-600 to-teal-400 rounded-2xl mx-auto flex items-center justify-center shadow-lg shadow-emerald-900/50 mb-4">
                <i class="fa-solid fa-gem text-3xl text-white"></i>
            </div>
            <h2 class="text-2xl font-bold tracking-tight text-white">Genesis Admin Login</h2>
            <p class="text-sm text-slate-400 mt-1">Access the offline-first sync control center</p>
        </div>

        <form action="{{ route('admin.login') }}" method="POST" class="space-y-5 relative z-10">
            @csrf
            <div>
                <label class="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">Email Address</label>
                <div class="relative">
                    <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                        <i class="fa-solid fa-envelope"></i>
                    </span>
                    <input type="email" name="email" value="{{ old('email') }}" required autofocus
                        class="w-full pl-10 pr-4 py-3 bg-slate-900/80 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 transition text-sm"
                        placeholder="admin@hiddengemssl.com">
                </div>
            </div>

            <div>
                <label class="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">Password</label>
                <div class="relative">
                    <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                        <i class="fa-solid fa-lock"></i>
                    </span>
                    <input type="password" name="password" required
                        class="w-full pl-10 pr-4 py-3 bg-slate-900/80 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 transition text-sm"
                        placeholder="••••••••">
                </div>
            </div>

            <button type="submit" class="w-full py-3 px-4 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-semibold rounded-xl shadow-lg shadow-emerald-900/40 hover:shadow-emerald-900/60 transition duration-200 glow-effect">
                <i class="fa-solid fa-arrow-right-to-bracket mr-2"></i> Sign In to Genesis
            </button>
        </form>
    </div>
</div>
@endsection
