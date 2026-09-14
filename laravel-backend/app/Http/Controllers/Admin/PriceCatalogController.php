<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PriceCatalogItem;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

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

    public function update(Request $request, PriceCatalogItem $priceCatalogItem)
    {
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
                abort(422, 'Numeric price modes require amount and ISO currency.');
            }
            if ($data['display_mode'] === 'range' && !isset($data['max_amount'])) {
                abort(422, 'Range mode requires a maximum amount.');
            }
        } else {
            $data['amount'] = $data['max_amount'] = $data['currency'] = null;
        }
        return $data;
    }
}
