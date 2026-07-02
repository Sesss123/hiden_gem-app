@extends('admin.layout')

@section('content')
<div class="max-w-2xl mx-auto space-y-6">
    <!-- Back Header -->
    <div>
        <a href="{{ route('admin.users.index') }}" class="text-sm font-semibold text-emerald-400 hover:text-emerald-300 transition flex items-center gap-1.5 mb-2">
            <i class="fa-solid fa-arrow-left"></i> Back to Users list
        </a>
        <h2 class="text-2xl font-bold tracking-tight text-white">
            Modify Profile Permissions: {{ $user->name }}
        </h2>
        <p class="text-sm text-slate-400">
            Elevate subscription status levels, configure role assignments, or suspend user access credentials.
        </p>
    </div>

    <!-- Edit Card -->
    <div class="glass-card p-6 md:p-8 rounded-3xl">
        <form action="{{ route('admin.users.update', $user->id) }}" method="POST" class="space-y-6">
            @csrf
            @method('PUT')

            <!-- Name -->
            <div class="space-y-2">
                <label for="name" class="block text-sm font-semibold text-slate-300">Name <span class="text-red-500">*</span></label>
                <input type="text" name="name" id="name" value="{{ old('name', $user->name) }}" required class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
            </div>

            <!-- Email Display (Immutable) -->
            <div class="space-y-2">
                <label class="block text-sm font-semibold text-slate-500">Email Address (Read-only)</label>
                <input type="email" value="{{ $user->email }}" disabled class="w-full bg-slate-950 border border-slate-900 rounded-xl py-3 px-4 text-slate-550 cursor-not-allowed">
            </div>

            <!-- Subscription Tiers Selection -->
            <div class="space-y-2 border-t border-slate-800/60 pt-6">
                <label for="subscription_tier" class="block text-sm font-semibold text-slate-300">Subscription Tier <span class="text-red-500">*</span></label>
                <p class="text-xs text-slate-500 mb-2">Configure membership capabilities. VIP & PRO unlock private offline mapping features.</p>
                
                <select name="subscription_tier" id="subscription_tier" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                    <option value="Free" {{ old('subscription_tier', $user->subscription_tier) == 'Free' ? 'selected' : '' }}>Free Tier (Standard Access)</option>
                    <option value="PRO" {{ old('subscription_tier', $user->subscription_tier) == 'PRO' ? 'selected' : '' }}>PRO Membership (Extended Offline Sync)</option>
                    <option value="VIP" {{ old('subscription_tier', $user->subscription_tier) == 'VIP' ? 'selected' : '' }}>VIP Membership (Unlimited Assets Access)</option>
                </select>
            </div>

            <!-- Role Configuration (Hidden for self) -->
            @if(auth()->id() !== $user->id)
                <div class="space-y-2 border-t border-slate-800/60 pt-6">
                    <label for="role" class="block text-sm font-semibold text-slate-300">User Role / Account State <span class="text-red-500">*</span></label>
                    <p class="text-xs text-slate-500 mb-2">Changing user state alters their mobile permissions. Setting to "Banned" denies login immediately.</p>
                    
                    <select name="role" id="role" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                        <option value="tourist" {{ old('role', $user->role) == 'tourist' ? 'selected' : '' }}>Tourist (Standard Account)</option>
                        <option value="guide_approved" {{ old('role', $user->role) == 'guide_approved' ? 'selected' : '' }}>Approved Guide (Live Broadcast Active)</option>
                        <option value="admin" {{ old('role', $user->role) == 'admin' ? 'selected' : '' }}>Administrator (Portal Access)</option>
                        <option value="banned" {{ old('role', $user->role) == 'banned' ? 'selected' : '' }}>Banned / Suspended (Account Locked)</option>
                    </select>
                </div>
            @else
                <!-- Implicit fallback when you view yourself -->
                <input type="hidden" name="role" value="{{ $user->role }}">
            @endif

            <!-- Submit actions -->
            <div class="border-t border-slate-800/60 pt-6 flex items-center justify-end gap-3">
                <a href="{{ route('admin.users.index') }}" class="text-sm font-semibold text-slate-400 hover:text-slate-200 transition py-2 px-4">
                    Cancel
                </a>
                <button type="submit" class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold shadow-md shadow-emerald-950/20 transition duration-200 glow-effect">
                    Save Account Changes
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
