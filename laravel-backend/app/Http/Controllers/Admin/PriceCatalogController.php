<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PriceCatalogItem;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class PriceCatalogController extends Controller
{
    use LogsAdminActivity;

    public function index()
    {
        $items = PriceCatalogItem::with('updater')->orderBy('category')->orderBy('label')->get();
        return view('admin.prices.index', compact('items'));
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $item = DB::transaction(function () use ($data) {
            $item = PriceCatalogItem::create($data + ['updated_by' => auth()->id()]);
            $this->logAdminAction('create_price_catalog_item', 'price_catalog', $item->id, ['after' => $item->toArray()]);
            return $item;
        });
        return back()->with('success', "Price configuration {$item->key} created.");
    }

    /** Create the known app keys without inventing numeric prices. */
    public function initialize()
    {
        $templates = [
            ['key' => 'drinks.thambili', 'category' => 'Local drinks', 'label' => 'King Coconut (Thambili)'],
            ['key' => 'drinks.palmyrah', 'category' => 'Local drinks', 'label' => 'Palmyrah drink'],
            ['key' => 'drinks.herbal_tea', 'category' => 'Local drinks', 'label' => 'Belimal / Ranawara herbal tea'],
            ['key' => 'subscriptions.smart_traveler.monthly', 'category' => 'Subscriptions', 'label' => 'Smart Traveler monthly'],
            ['key' => 'subscriptions.heritage.monthly', 'category' => 'Subscriptions', 'label' => 'Heritage Premium monthly'],
            ['key' => 'subscriptions.heritage.annual', 'category' => 'Subscriptions', 'label' => 'Heritage Premium annual'],
        ];
        $created = DB::transaction(function () use ($templates) {
            $created = 0;
            foreach ($templates as $template) {
                $item = PriceCatalogItem::firstOrCreate(['key' => $template['key']], $template + [
                    'display_mode' => 'unavailable', 'is_active' => true, 'updated_by' => auth()->id(),
                    'source' => 'Awaiting administrator configuration',
                ]);
                if ($item->wasRecentlyCreated) $created++;
            }
            $this->logAdminAction('initialize_price_catalog', 'price_catalog', null,
                ['created_count' => $created, 'template_count' => count($templates)]);
            return $created;
        });
        return back()->with('success', $created
            ? "Created {$created} safe price templates. Enter values and save each item."
            : 'All standard price templates already exist.');
    }

    public function update(Request $request, PriceCatalogItem $priceCatalogItem)
    {
        if ($request->input('key') !== $priceCatalogItem->key) {
            throw ValidationException::withMessages([
                'key' => 'Stable app keys cannot be renamed. Create a new custom key instead.',
            ]);
        }
        $before = $priceCatalogItem->toArray();
        $data = $this->validated($request, $priceCatalogItem->id);
        DB::transaction(function () use ($priceCatalogItem, $data, $before) {
            $priceCatalogItem->update($data + ['updated_by' => auth()->id()]);
            $this->logAdminAction('update_price_catalog_item', 'price_catalog', $priceCatalogItem->id,
                ['before' => $before, 'after' => $priceCatalogItem->fresh()->toArray()]);
        });
        return back()->with('success', "Price configuration {$priceCatalogItem->key} updated.");
    }

    public function destroy(PriceCatalogItem $priceCatalogItem)
    {
        DB::transaction(function () use ($priceCatalogItem) {
            $before = $priceCatalogItem->toArray();
            $id = $priceCatalogItem->id;
            $priceCatalogItem->delete();
            $this->logAdminAction('delete_price_catalog_item', 'price_catalog', $id, ['before' => $before]);
        });
        return back()->with('success', 'Price configuration removed. Clients will show price unavailable.');
    }

    private function validated(Request $request, ?int $ignoreId = null): array
    {
        $data = $request->validate([
            'key' => ['required', 'regex:/^[a-z0-9_.-]+$/', 'max:96', Rule::unique('price_catalog', 'key')->ignore($ignoreId)],
            'category' => ['required', 'string', 'max:48'], 'label' => ['required', 'string', 'max:160'],
            'display_mode' => ['required', Rule::in(['unavailable', 'contact', 'free', 'fixed', 'from', 'range'])],
            'amount' => ['nullable', 'numeric', 'min:0', 'max:999999999999.99'],
            'max_amount' => ['nullable', 'numeric', 'gte:amount', 'max:999999999999.99'],
            'currency' => ['nullable', 'regex:/^[A-Z]{3}$/'], 'billing_period' => ['nullable', 'string', 'max:32'],
            'source' => ['nullable', 'string', 'max:255'], 'effective_from' => ['nullable', 'date'],
            'expires_at' => ['nullable', 'date', 'after:effective_from'], 'is_active' => ['nullable', 'boolean'],
        ]);
        $data['is_active'] = $request->boolean('is_active');
        if (in_array($data['display_mode'], ['fixed', 'from', 'range'], true)) {
            if (!isset($data['amount']) || empty($data['currency'])) {
                throw ValidationException::withMessages([
                    'amount' => 'Fixed, From and Range modes require an amount.',
                    'currency' => 'Choose a 3-letter currency for numeric prices.',
                ]);
            }
            if ($data['display_mode'] === 'range' && !isset($data['max_amount'])) {
                throw ValidationException::withMessages(['max_amount' => 'Range mode requires a maximum amount.']);
            }
        } else {
            $data['amount'] = $data['max_amount'] = $data['currency'] = null;
        }
        return $data;
    }
}
