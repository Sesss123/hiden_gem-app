# Hidden Gems SL — AI Model Server

This is a **ready-to-run FastAPI skeleton** that exposes the exact HTTP contract
the Flutter app + Laravel backend already expect. Connecting your trained model
= fill in the four `# TODO: PLUG YOUR MODEL IN HERE` blocks in `main.py`, then
point the app at this server. **No Flutter or Laravel code changes are needed.**

---

## What this server exposes

All routes live under `/api` (the app's `PYTHON_BACKEND_URL` already includes `/api`).

| Method | Route | Feature | Auth header | Returns |
|--------|-------|---------|-------------|---------|
| GET  | `/api/status` | Health check | — | `200 OK` |
| POST | `/api/test-model` | Oracle chat | `x-api-key` | `{"response": "..."}` |
| POST | `/api/ai/plan-itinerary` | Trip Planner | `X-Admin-Internal-Key` | `TripPlan` JSON |
| POST | `/api/food/scan` | Food scanner | — (gzip body) | `FoodModel` JSON |
| POST | `/api/ai/recommendations` | (optional) | `X-Admin-Internal-Key` | `{"recommendations": []}` |

The exact request/response shapes are documented in the docstrings inside
`main.py`. **The Trip Planner response is strict**: `trip_summary` (with
non-empty `from_city` + `destination_city`) and a non-empty `itinerary` list are
required, or the app rejects the response.

---

## Run it

```bash
cd ai-server
python -m venv .venv && source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env                                    # then edit the two keys
uvicorn main:app --host 0.0.0.0 --port 8000
```

Verify:
```bash
curl http://localhost:8000/api/status
# {"status":"ok","model":"self-hosted","ready":true}
```

---

## Wire your model in

Open `main.py` and replace each `# TODO: PLUG YOUR MODEL IN HERE` block:

1. **`oracle_chat`** — call your trained model with the prompt; return `{"response": text}`.
2. **`plan_itinerary`** — build a day-by-day plan. **Take exact `lat`/`lng`/`cost_lkr`
   from your place data**, and use the model only for the natural-language fields
   (`day_theme`, `notes`, `human_text`, `safety_tip`, `sinhala_phrase`). Never let
   the model invent coordinates or prices.
3. **`food_scan`** — run your vision model on `image_bytes`, return a `FoodModel` map.
4. **`recommendations`** — optional; wire only if the app starts using it.

---

## Point the app at this server

### Flutter build (`--dart-define`)
```bash
flutter build apk \
  --dart-define=PYTHON_BACKEND_URL=https://YOUR-MODEL-HOST/api \
  --dart-define=LARAVEL_BACKEND_URL=https://api.hiddengemssl.com/api/v1 \
  --dart-define=LUMEN_API_KEY=<same as this server's LUMEN_API_KEY> \
  --dart-define=HIDDEN_GEMS_API_KEY=<your Laravel client key>
```
> Flutter's `PYTHON_BACKEND_URL` **includes `/api`** (used by Oracle `/test-model`,
> `/status`, and food `/food/scan`).

### Laravel `.env` (Trip Planner path)
```env
PYTHON_BACKEND_URL=https://YOUR-MODEL-HOST      # NO /api — Laravel appends /api/ai/...
INTERNAL_BRIDGE_KEY=<same as this server's INTERNAL_BRIDGE_KEY>
```

### ⚠️ The one gotcha: the `/api` suffix
| Who calls the model | Env var | Value |
|---|---|---|
| Flutter → model (Oracle, food) | Flutter `PYTHON_BACKEND_URL` | **with** `/api` → `https://host/api` |
| Laravel → model (Trip Planner) | Laravel `.env PYTHON_BACKEND_URL` | **without** `/api` → `https://host` |

Both must resolve to the **same** model server root.

---

## Auth keys — must match on both sides

| Key | Set on the server (`.env`) | Must equal |
|---|---|---|
| `LUMEN_API_KEY` | this server | Flutter `--dart-define=LUMEN_API_KEY` |
| `INTERNAL_BRIDGE_KEY` | this server | Laravel `.env INTERNAL_BRIDGE_KEY` |

---

## Deploy

Any host that can run Python works — a small VPS for CPU inference, or a GPU
instance if your model needs it. Put it behind HTTPS (nginx/Caddy) at the domain
you set in `PYTHON_BACKEND_URL`. This is the "AI host" line in the cost report;
it's a **fixed** cost (by concurrency), not per-token — $0 until you deploy.
