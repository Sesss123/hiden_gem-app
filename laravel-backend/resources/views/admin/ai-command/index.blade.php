@extends('admin.layout')

@section('title', 'AI Command Center - Hidden Gems SL')
@section('header', 'AI Neural Command Center & Pipelines')

@section('content')
<div class="space-y-6">
    <!-- Status Banner -->
    <div class="glass-card p-6 rounded-2xl border border-slate-800 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-2xl {{ $pythonOnline ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' : 'bg-rose-500/20 text-rose-400 border border-rose-500/30' }} flex items-center justify-center text-2xl font-bold shadow-lg">
                {{ $pythonOnline ? '🤖' : '⚠️' }}
            </div>
            <div>
                <div class="flex items-center gap-2">
                    <h2 class="text-xl font-bold text-white">Python AI Subsystem Status</h2>
                    <span class="px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider {{ $pythonOnline ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30' : 'bg-rose-500/20 text-rose-300 border border-rose-500/30' }}">
                        {{ $stats['status'] }}
                    </span>
                </div>
                <p class="text-sm text-slate-400 mt-0.5">
                    Bridging Laravel 11 with FastAPI Neural Engine (Version: <span class="text-indigo-400 font-mono">{{ $stats['version'] }}</span>)
                </p>
            </div>
        </div>
        <div class="flex items-center gap-2">
            <span class="text-xs font-semibold text-slate-400">Active Models:</span>
            @foreach($stats['active_models'] as $model)
                <span class="px-2.5 py-1 bg-slate-800/80 border border-slate-700 rounded-lg text-xs font-medium text-slate-300">{{ $model }}</span>
            @endforeach
        </div>
    </div>

    <!-- Alert Messages -->
    @if(session('success'))
        <div class="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center gap-3">
            <span>✅</span>
            <span class="text-sm font-medium">{{ session('success') }}</span>
        </div>
    @endif
    @if(session('error'))
        <div class="p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 flex items-center gap-3">
            <span>⚠️</span>
            <span class="text-sm font-medium">{{ session('error') }}</span>
        </div>
    @endif

    <!-- AI Pipeline Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Neural Discovery Generator -->
        <div class="glass-card p-6 rounded-2xl border border-slate-800 flex flex-col justify-between">
            <div class="space-y-4">
                <div class="flex items-center justify-between border-b border-slate-800 pb-3">
                    <h3 class="font-bold text-lg text-white flex items-center gap-2">
                        <span class="p-1.5 bg-indigo-500/20 text-indigo-400 rounded-lg text-sm">🌌</span>
                        Neural AI Place Discovery
                    </h3>
                    <span class="text-[10px] bg-indigo-500/20 text-indigo-300 px-2 py-0.5 rounded font-black uppercase">LLM Powered</span>
                </div>
                <p class="text-sm text-slate-400 leading-relaxed">
                    Trigger our Gemini-powered neural crawler to automatically discover, structure, and curate new hidden gems across Sri Lanka based on your natural language prompt.
                </p>
                
                <form action="{{ route('admin.ai.discover') }}" method="POST" class="space-y-4 pt-2">
                    @csrf
                    <div>
                        <label class="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1.5">Discovery Prompt</label>
                        <textarea name="prompt" rows="3" required placeholder="e.g. Find 5 untouched secret waterfalls in Badulla and Knuckles range suitable for eco-camping..." class="w-full bg-slate-950/80 border border-slate-800 rounded-xl p-3.5 text-sm text-white focus:outline-none focus:border-indigo-500 placeholder-slate-600 shadow-inner"></textarea>
                    </div>
                    <button type="submit" {{ !$pythonOnline ? 'disabled' : '' }} class="w-full py-3 bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white rounded-xl font-semibold text-sm transition shadow-lg shadow-indigo-900/30 flex items-center justify-center gap-2 {{ !$pythonOnline ? 'opacity-50 cursor-not-allowed' : '' }}">
                        <span>🚀</span> Launch Discovery Pipeline
                    </button>
                </form>
            </div>
        </div>

        <!-- Smart URL Intake Harvester -->
        <div class="glass-card p-6 rounded-2xl border border-slate-800 flex flex-col justify-between">
            <div class="space-y-4">
                <div class="flex items-center justify-between border-b border-slate-800 pb-3">
                    <h3 class="font-bold text-lg text-white flex items-center gap-2">
                        <span class="p-1.5 bg-purple-500/20 text-purple-400 rounded-lg text-sm">🔗</span>
                        Smart URL Intake Harvester
                    </h3>
                    <span class="text-[10px] bg-purple-500/20 text-purple-300 px-2 py-0.5 rounded font-black uppercase">Web Scraper</span>
                </div>
                <p class="text-sm text-slate-400 leading-relaxed">
                    Paste any travel blog, Wikipedia article, or TripAdvisor review URL. Our neural intake engine will extract coordinates, history, facilities, and generate a draft place.
                </p>
                
                <form action="{{ route('admin.ai.intake') }}" method="POST" class="space-y-4 pt-2">
                    @csrf
                    <div>
                        <label class="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1.5">Article / Blog URL</label>
                        <input type="url" name="url" required placeholder="https://en.wikipedia.org/wiki/Ravana_Falls" class="w-full bg-slate-950/80 border border-slate-800 rounded-xl p-3.5 text-sm text-white focus:outline-none focus:border-purple-500 placeholder-slate-600 shadow-inner">
                    </div>
                    <div class="pt-6">
                        <button type="submit" {{ !$pythonOnline ? 'disabled' : '' }} class="w-full py-3 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-500 hover:to-pink-500 text-white rounded-xl font-semibold text-sm transition shadow-lg shadow-purple-900/30 flex items-center justify-center gap-2 {{ !$pythonOnline ? 'opacity-50 cursor-not-allowed' : '' }}">
                            <span>⚡</span> Extract & Harvest Place Data
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Neural Vision & 3D AR Validator Lab info -->
    <div class="glass-card p-6 rounded-2xl border border-slate-800 flex items-center justify-between">
        <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-2xl bg-amber-500/20 border border-amber-500/30 flex items-center justify-center text-amber-400 text-2xl">
                🥽
            </div>
            <div>
                <h4 class="text-lg font-bold text-white">3D AR Model (.glb) & Vision AI Validation Lab</h4>
                <p class="text-sm text-slate-400">
                    All AR assets uploaded via the Places Registry are automatically validated for polygon count, scale (`0.0100`), and mobile rendering compatibility.
                </p>
            </div>
        </div>
        <a href="{{ route('admin.places.index') }}" class="px-4 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl text-sm font-semibold border border-slate-700 transition flex items-center gap-2">
            <span>📍</span> Go to Places Registry
        </a>
    </div>
</div>
@endsection
