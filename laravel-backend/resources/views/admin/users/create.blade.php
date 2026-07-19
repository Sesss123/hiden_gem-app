@extends('admin.layout')

@section('content')
<div class="max-w-2xl mx-auto space-y-6">
    <!-- Back Header -->
    <div>
        <a href="{{ route('admin.users.index') }}" class="text-sm font-semibold text-emerald-400 hover:text-emerald-300 transition flex items-center gap-1.5 mb-2">
            <i class="fa-solid fa-arrow-left"></i> Back to Users list
        </a>
        <h2 class="text-2xl font-bold tracking-tight text-white">
            New Admin User
        </h2>
        <p class="text-sm text-slate-400">
            Create a new login for the admin panel. Use "Content Manager" for a restricted account that can only submit Places (pending your approval) and manage Events directly.
        </p>
    </div>

    <!-- Create Card -->
    <div class="glass-card p-6 md:p-8 rounded-3xl">
        <form action="{{ route('admin.users.store') }}" method="POST" class="space-y-6">
            @csrf

            <!-- Name -->
            <div class="space-y-2">
                <label for="name" class="block text-sm font-semibold text-slate-300">Name <span class="text-red-500">*</span></label>
                <input type="text" name="name" id="name" value="{{ old('name') }}" required class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
            </div>

            <!-- Email -->
            <div class="space-y-2">
                <label for="email" class="block text-sm font-semibold text-slate-300">Email Address <span class="text-red-500">*</span></label>
                <input type="email" name="email" id="email" value="{{ old('email') }}" required class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
            </div>

            <!-- Password -->
            <div class="space-y-2">
                <label for="password" class="block text-sm font-semibold text-slate-300">Password <span class="text-red-500">*</span></label>
                <input type="password" name="password" id="password" required minlength="8" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                <p class="text-xs text-slate-500">At least 8 characters, with upper &amp; lowercase letters and a number.</p>
            </div>

            <!-- Role -->
            <div class="space-y-2 border-t border-slate-800/60 pt-6">
                <label for="role" class="block text-sm font-semibold text-slate-300">Admin Role <span class="text-red-500">*</span></label>
                <p class="text-xs text-slate-500 mb-2">Content Manager: Places + Events only, places require your approval. Admin/Super Admin: full panel access.</p>

                <select name="role" id="role" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                    <option value="content_manager" {{ old('role') == 'content_manager' ? 'selected' : '' }}>Content Manager (Places + Events only)</option>
                    <option value="admin" {{ old('role') == 'admin' ? 'selected' : '' }}>Admin (Full panel access)</option>
                    <option value="super_admin" {{ old('role') == 'super_admin' ? 'selected' : '' }}>Super Admin (Full panel access)</option>
                </select>
            </div>

            <!-- Submit actions -->
            <div class="border-t border-slate-800/60 pt-6 flex items-center justify-end gap-3">
                <a href="{{ route('admin.users.index') }}" class="text-sm font-semibold text-slate-400 hover:text-slate-200 transition py-2 px-4">
                    Cancel
                </a>
                <button type="submit" class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold shadow-md shadow-emerald-950/20 transition duration-200 glow-effect">
                    Create Admin User
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
