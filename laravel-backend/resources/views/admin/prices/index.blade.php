@extends('admin.layout')

@section('content')
<div class="space-y-6">
  <div class="flex flex-col md:flex-row md:items-end justify-between gap-3">
    <div><h2 class="text-2xl font-bold text-white"><i class="fa-solid fa-tags text-amber-400"></i> Price Management</h2>
      <p class="text-sm text-slate-400">Choose a display mode, enter the price, and save. Missing values appear as “Price unavailable” in the app.</p></div>
    @if($items->isNotEmpty())
      <form method="POST" action="{{ route('admin.prices.initialize') }}">@csrf
        <button class="px-4 py-2 text-xs border border-amber-500/40 text-amber-300 rounded-lg hover:bg-amber-500/10"><i class="fa-solid fa-rotate mr-1"></i>Restore missing standard fields</button>
      </form>
    @endif
  </div>
  @if(session('success'))<div class="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400">{{ session('success') }}</div>@endif
  @if($errors->any())<div class="p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-300"><ul class="list-disc pl-5">@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>@endif

  <details class="glass-card rounded-2xl border border-slate-800/80" {{ $errors->any() ? 'open' : '' }}>
  <summary class="cursor-pointer p-5 text-sm font-semibold text-slate-200"><i class="fa-solid fa-plus mr-2 text-amber-400"></i>Advanced: add a custom price key</summary>
  <form method="POST" action="{{ route('admin.prices.store') }}" class="px-5 pb-5 grid grid-cols-1 md:grid-cols-4 gap-3">@csrf
    <input name="key" required pattern="[a-z0-9_.-]+" placeholder="Stable key: drinks.thambili" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="category" required placeholder="Category" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="label" required placeholder="Admin label" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <select name="display_mode" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white"><option value="unavailable">Unavailable</option><option value="contact">Contact</option><option value="free">Free</option><option value="fixed">Fixed</option><option value="from">From</option><option value="range">Range</option></select>
    <input name="amount" type="number" min="0" step="0.01" placeholder="Amount (blank unless numeric)" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="max_amount" type="number" min="0" step="0.01" placeholder="Max (range only)" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <select name="currency" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white"><option value="">Currency</option>@foreach(['LKR','USD','EUR','GBP'] as $currency)<option value="{{ $currency }}">{{ $currency }}</option>@endforeach</select>
    <input name="billing_period" placeholder="Billing period (month/year)" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="source" placeholder="Source / verification note" class="md:col-span-2 bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="effective_from" type="datetime-local" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <input name="expires_at" type="datetime-local" class="bg-slate-900 border border-slate-700 rounded-lg p-2 text-white">
    <label class="text-slate-300 flex items-center gap-2"><input type="checkbox" name="is_active" value="1" checked> Active</label>
    <button class="bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold rounded-lg p-2">Add price configuration</button>
  </form></details>

  <div class="space-y-3">
  @forelse($items as $item)
    <form method="POST" action="{{ route('admin.prices.update', $item) }}" class="glass-card p-4 rounded-xl grid grid-cols-1 md:grid-cols-6 gap-2 items-center">@csrf @method('PATCH')
      <input name="key" value="{{ $item->key }}" readonly title="Stable app key cannot be renamed" class="bg-slate-950 border border-slate-800 rounded p-2 text-slate-500 cursor-not-allowed">
      <input name="category" value="{{ $item->category }}" required class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <input name="label" value="{{ $item->label }}" required class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <select name="display_mode" class="bg-slate-900 border border-slate-700 rounded p-2 text-white">@foreach(['unavailable','contact','free','fixed','from','range'] as $mode)<option value="{{ $mode }}" @selected($item->display_mode===$mode)>{{ ucfirst($mode) }}</option>@endforeach</select>
      <input name="amount" type="number" min="0" step="0.01" value="{{ $item->amount }}" placeholder="Amount" class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <input name="max_amount" type="number" min="0" step="0.01" value="{{ $item->max_amount }}" placeholder="Max" class="bg-slate-900 border border-slate-700 rounded p-2 text-white">
      <select name="currency" class="bg-slate-900 border border-slate-700 rounded p-2 text-white"><option value="">Currency</option>@foreach(['LKR','USD','EUR','GBP'] as $currency)<option value="{{ $currency }}" @selected($item->currency===$currency)>{{ $currency }}</option>@endforeach</select>
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
  @empty
    <div class="glass-card p-10 rounded-xl text-center border border-amber-500/20">
      <i class="fa-solid fa-wand-magic-sparkles text-3xl text-amber-400 mb-3"></i>
      <h3 class="text-white font-bold text-lg">Set up the standard price fields</h3>
      <p class="text-slate-400 text-sm mt-2 mb-5">This creates editable labels only. No numeric default prices will be inserted.</p>
      <form method="POST" action="{{ route('admin.prices.initialize') }}">@csrf
        <button class="px-6 py-3 bg-amber-500 hover:bg-amber-400 text-slate-950 rounded-xl font-bold">Create standard price fields</button>
      </form>
    </div>
  @endforelse
  </div>
</div>
@endsection

@push('scripts')
<script>
document.querySelectorAll('select[name="display_mode"]').forEach(function(select) {
  const form = select.closest('form');
  if (!form) return;
  const refresh = function() {
    const numeric = ['fixed', 'from', 'range'].includes(select.value);
    const range = select.value === 'range';
    ['amount', 'currency'].forEach(function(name) {
      const input = form.querySelector('[name="' + name + '"]');
      if (input) { input.disabled = !numeric; input.classList.toggle('opacity-40', !numeric); }
    });
    const max = form.querySelector('[name="max_amount"]');
    if (max) { max.disabled = !range; max.classList.toggle('opacity-40', !range); }
  };
  select.addEventListener('change', refresh); refresh();
});
</script>
@endpush
