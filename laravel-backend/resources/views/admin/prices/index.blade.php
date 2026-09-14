@extends('admin.layout')

@section('content')
<div class="space-y-6">
  <div><h2 class="text-2xl font-bold text-white"><i class="fa-solid fa-tags text-amber-400"></i> Price Management</h2>
    <p class="text-sm text-slate-400">Single source of truth for app catalog prices. Empty/missing entries appear as “Price unavailable”; the app has no numeric fallback.</p></div>
  @if(session('success'))<div class="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400">{{ session('success') }}</div>@endif
  @if($errors->any())<div class="p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-300"><ul class="list-disc pl-5">@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>@endif

  <form method="POST" action="{{ route('admin.prices.store') }}" class="glass-card p-5 rounded-2xl grid grid-cols-1 md:grid-cols-4 gap-3">@csrf
    <input name="key" required pattern="[a-z0-9_.-]+" placeholder="Stable key: drinks.thambili" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="category" required placeholder="Category" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="label" required placeholder="Admin label" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <select name="display_mode" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white"><option value="unavailable">Unavailable</option><option value="contact">Contact</option><option value="free">Free</option><option value="fixed">Fixed</option><option value="from">From</option><option value="range">Range</option></select>
    <input name="amount" type="number" min="0" step="0.01" placeholder="Amount (blank unless numeric)" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="max_amount" type="number" min="0" step="0.01" placeholder="Max (range only)" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="currency" maxlength="3" pattern="[A-Z]{3}" placeholder="Currency: LKR" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white uppercase">
    <input name="billing_period" placeholder="Billing period (month/year)" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="source" placeholder="Source / verification note" class="md:col-span-2 bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="effective_from" type="datetime-local" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="expires_at" type="datetime-local" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <label class="text-slate-300 flex items-center gap-2"><input type="checkbox" name="is_active" value="1" checked> Active</label>
    <button class="bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold rounded-lg p-2">Add price configuration</button>
  </form>

  <div class="space-y-3">
  @forelse($items as $item)
    <form method="POST" action="{{ route('admin.prices.update', $item) }}" class="glass-card p-4 rounded-xl grid grid-cols-1 md:grid-cols-6 gap-2 items-center">@csrf @method('PATCH')
      <input name="key" value="{{ $item->key }}" required class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <input name="category" value="{{ $item->category }}" required class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <input name="label" value="{{ $item->label }}" required class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <select name="display_mode" class="bg-slate-900 border border-slate-700 rounded p-2 text-white">@foreach(['unavailable','contact','free','fixed','from','range'] as $mode)<option value="{{ $mode }}" @selected($item->display_mode===$mode)>{{ ucfirst($mode) }}</option>@endforeach</select>
      <input name="amount" type="number" min="0" step="0.01" value="{{ $item->amount }}" placeholder="Amount" class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <input name="max_amount" type="number" min="0" step="0.01" value="{{ $item->max_amount }}" placeholder="Max" class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <input name="currency" maxlength="3" value="{{ $item->currency }}" placeholder="ISO currency" class="bg-slate-900 border border-slate-700 rounded p-2 text-white uppercase">
      <input name="billing_period" value="{{ $item->billing_period }}" placeholder="Period" class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <input name="source" value="{{ $item->source }}" placeholder="Source" class="md:col-span-2 bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <input name="effective_from" type="datetime-local" value="{{ $item->effective_from?->format('Y-m-d\TH:i') }}" class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <input name="expires_at" type="datetime-local" value="{{ $item->expires_at?->format('Y-m-d\TH:i') }}" class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <label class="text-slate-300"><input type="checkbox" name="is_active" value="1" @checked($item->is_active)> Active</label>
      <button class="bg-sky-600 text-white rounded p-2">Save</button>
      <button form="delete-price-{{ $item->id }}" class="bg-red-500/20 text-red-300 rounded p-2" onclick="return confirm('Delete this price configuration?')">Delete</button>
      <p class="md:col-span-6 text-xs text-slate-500">Updated {{ $item->updated_at->diffForHumans() }} by {{ $item->updater?->name ?? 'system' }}</p>
    </form>
    <form id="delete-price-{{ $item->id }}" method="POST" action="{{ route('admin.prices.destroy', $item) }}">@csrf @method('DELETE')</form>
  @empty <div class="glass-card p-8 rounded-xl text-center text-slate-400">No prices configured. This is safe: the app displays price unavailable.</div> @endforelse
  </div>
</div>
@endsection
