# 🏛️ Hidden Gems SL — System Architecture & Implementation Plan
**Version:** 3.2 (Production-Hardened Option A: Zero-Bundle Server-Driven Architecture)  
**Last Updated:** July 2026  
**Core Philosophy:** *100% Server-Controlled MySQL Source of Truth, Zero APK Bloat, Monotonic Atomic Versioning, & Dual-Tier LRU Caching.*

---

## 🌟 1. Executive Summary & Design Principles

The **Hidden Gems SL** architecture is engineered for a high-performance, offline-first mobile experience backed by a **Laravel API (PHP 8+) running on a VPS with a MySQL 8.0+ relational database**.

To eliminate APK bloat and ensure 100% server-driven data control without requiring Google Play Store app updates for baseline content, this architecture adopts **Option A: Zero-Bundle, First-Launch Paginated Full Sync**.

### Key Architectural Pillars:
1. 🗄️ **Option A: Zero-Bundle Server-Driven Source of Truth:** The app ships with a clean, empty SQLite database without any bundled JSON destination assets. Upon first launch (Internet required), the app performs a paginated chunked sync (`since_version=0&limit=100`) from the Laravel MySQL server to construct its offline SQLite database.
2. ⚡ **Atomic Monotonic Integer Versioning (`sync_counter` Table):** Versioning is completely independent of `TIMESTAMP` or `updated_at` columns. A dedicated atomic sequence table (`sync_counter`) increments by +1 on every single `INSERT`, `UPDATE`, soft `DELETE`, or gallery modification.
3. 📶 **100% Offline-First & Estimated <50ms UI Latency:** Once initial hydration is complete, searching, category filtering, and GPS calculations execute directly against SQLite and RAM cache (`_memCache`), delivering estimated UI response times under 50ms.
4. 🛡️ **Parent Version Touching for Media Gallery:** Modifying a place's image gallery in `place_images` automatically touches and increments the parent place's `sync_version`. Image update is treated as a Place update.

---

## 📐 2. Core Architectural Flow Diagram

```
┌────────────────────────────────────────────────────────┐       Lightweight Version Check       ┌────────────────────────────────────────────────────────┐
│                                                        │ ────────────────────────────────────▶ │                                                        │
│                  📱 FLUTTER CLIENT                     │                                       │                 ☁️ BACKEND SERVER                     │
│                                                        │ ◀──────────────────────────────────── │                                                        │
│  ┌──────────────────────────────────────────────────┐  │       Paginated Delta JSON (Chunked)  │  ┌──────────────────────────────────────────────────┐  │
│  │ 💾 Local Storage Engine (Option A)               │  │                                       │  │ ⚡ Laravel API (PHP 8+) / VPS                      │  
│  │  • Ships with Empty SQLite Database              │  │                                       │  │  • GET /api/v1/places/check-version              │  │
│  │  • 1st Launch: Full Sync via Chunked Pagination  │  │                                       │  │  • GET /api/v1/places/delta (Cursor Paginated)   │  │
│  │  • In-Memory RAM Cache (_memCache)               │  │                                       │  │  • MySQL 8.0+ Database (Atomic sync_counter)     │  │
│  └──────────────────────────────────────────────────┘  │                                       │  └──────────────────────────────────────────────────┘  │
└───────────────────────────┬────────────────────────────┘                                       └───────────────────────────┬────────────────────────────┘
                            │                                                                                                │
                            │ On-Demand Lazy Image Load                                                                      │ Static Image Edge Hosting
                            ▼                                                                                                ▼
┌────────────────────────────────────────────────────────┐                                       ┌────────────────────────────────────────────────────────┐
│ 🖼️ DUAL-TIER LRU IMAGE CACHE (2 Dedicated Managers)  │ ◀──────────────────────────────────── │ 🌐 CLOUD STORAGE / CDN / NGINX                          │
│                                                        │         HTTP GET (Only When Missing)  │                                                        │
│  • ThumbCacheManager (500 Thumbs / 60-Day TTL)         │                                       │  • /storage/places/thumbs/*.webp (Lightweight)         │
│  • FullCacheManager (150 Photos / 14-Day TTL)          │                                       │  • /storage/places/full/*.webp (High-Resolution)       │
│  • Strict Segregation prevents Gallery eviction        │                                       │  • Zero Database Blob Serving                          │
└────────────────────────────────────────────────────────┘                                       └────────────────────────────────────────────────────────┘
```

---

## 🏗️ 3. Layer-by-Layer Technical Breakdown

### Layer 1: Monotonic Atomic Versioning & Delta-Sync Protocol
To guarantee race-free sequential versioning across bulk updates:
* **Rule 1 (Atomic Monotonic Counter):** *The `sync_version` is NOT derived from `updated_at` or timestamps. It is an atomic, monotonically incrementing integer retrieved from the dedicated `sync_counter` table. Every `INSERT`, `UPDATE`, or soft `DELETE` increments this global counter by +1.*
* **Rule 2 (Image Update Mapping):** *When an image in the `place_images` table is modified, added, or deleted, the parent place's `sync_version` is automatically touched and updated to the latest atomic counter value. Modifying a gallery image is treated identically to modifying the place metadata.*
* **Rule 3 (First-Sync Bandwidth Optimization):** *When a client requests `/delta?since_version=0` (first-boot full sync), the server automatically omits or empties the `deleted_ids` and `deleted_image_ids` arrays from the payload. Since the client database is initially empty, transmitting tombstone IDs is redundant and wastes bandwidth.*

When online, the app calls `/api/v1/places/delta?since_version=100&limit=100`. The API returns a paginated payload with strict field type consistency (`ticket_price: 1000` as integer, plus cursor flags):

```json
{
  "sync_version": 145,
  "has_more": true,
  "next_cursor": 105,
  "upsert_places": [
    {
      "id": "pl_502",
      "name": "Duwili Ella (Updated)",
      "ticket_price": 1000,
      "family_friendly": 1,
      "sync_version": 144
    }
  ],
  "deleted_ids": ["pl_099"],
  "upsert_images": [
    { "id": 501, "place_id": "pl_502", "thumb_path": "places/pl_502/thumb/2.webp", "is_cover": 1 }
  ],
  "deleted_image_ids": [402]
}
```

### Layer 2: Dual-Tier LRU Media Caching Engine (`ThumbCacheManager` & `FullCacheManager`)
To prevent gallery photos from evicting list view thumbnails, the app defines two independent Flutter `CacheManager` singletons with distinct memory caps and TTL policies:

```dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Thumbnail Cache Manager — For List/Grid Cards (High Persistence)
class ThumbCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'heritage_thumbs';
  static final _instance = ThumbCacheManager._();
  factory ThumbCacheManager() => _instance;
  ThumbCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 60),
    maxNrOfCacheObjects: 500,
  ));
}

// Full Image Cache Manager — For PlaceDetailsScreen Galleries (Fast LRU Eviction)
class FullCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'heritage_full';
  static final _instance = FullCacheManager._();
  factory FullCacheManager() => _instance;
  FullCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 14),
    maxNrOfCacheObjects: 150,
  ));
}
```

---

## 🚀 4. Step-by-Step Implementation Roadmap

### Phase 0: Bundling Strategy Decision (Selected Option A)
- [x] **Decision:** Option A (Zero-bundle, first-launch paginated full sync). App ships with empty SQLite DB.
- [ ] Delete old legacy `places.json` (21 items) completely from the codebase.
- [ ] Remove all static asset references to `tripme_database_complete_*.json` in asset bundlers.
- [ ] Verify category IDs and ensure single `id` namespace (`pl_xxxxx`) across all backend records.

### Phase 1: SQLite Storage Engine & First-Boot Seeder
- [ ] Build local SQLite schema matching MySQL DDL using `sqflite` or `drift`.
- [ ] Implement `FirstBootSyncService`: on first launch, execute paginated loop (`since_version=0&limit=100`) until `has_more == false`.
- [ ] Hydrate SQLite records into memory (`_memCache`) for estimated <50ms UI response times.

### Phase 2: Dual-Tier Cache Manager & UI Integration
- [ ] Register `ThumbCacheManager` and `FullCacheManager` in `lib/core/services/cache_service.dart`.
- [ ] Update `CachedImage` widget to route thumbnails to `ThumbCacheManager()` and hero photos to `FullCacheManager()`.
- [ ] Add manual "Clear Cache" buttons in `ProfileScreen` with separate footprint indicators for thumbs vs full images.

### Phase 3: Laravel API & Monotonic Versioning Setup
- [ ] **Manual phpMyAdmin DB Setup:** Execute the Section 5 DDL SQL queries directly inside phpMyAdmin on the hosting VPS to manually create the `sync_counter`, `places`, and `place_images` tables.
- [ ] Implement Laravel observers to increment `sync_counter` and touch parent place `sync_version` on image updates.
- [ ] Build `/api/v1/places/delta` controller returning `has_more`, `next_cursor`, and consistent integer field types.

### Phase 3.5: Pagination & Rate Limiting
- [ ] Add `limit` and `cursor` parameters to `/api/v1/places/delta` endpoint.
- [ ] Apply Laravel `throttle:60,1` middleware to all `/api/v1/places/*` routes to prevent database scraping.

### Phase 4: Splash Screen Boot Lifecycle Integration
- [ ] Hook synchronization check into `performInitialization()` with an estimated **2.5-second timeout** for rural 2G/3G networks.
- [ ] Ensure offline mode activates instantly if network ping fails after initial DB seeding.

---

## 🗄️ 5. Relational Database Schema (MySQL 8.0+ Specification)

> [!TIP]
> **💡 Manual Setup via phpMyAdmin:** You do not need command-line migration scripts to initialize the database. You can manually create the database by simply copying the SQL DDL blocks below (`sync_counter`, `places`, and `place_images`) and pasting them directly into the **SQL Query Tab** inside **phpMyAdmin** on your VPS / hosting control panel.

The SQL schema incorporates the dedicated `sync_counter` table and indexes `sync_version` across all domain tables.

### `sync_counter` — Global Atomic Version Tracker:
```sql
CREATE TABLE sync_counter (
    id INT PRIMARY KEY DEFAULT 1,
    current_version BIGINT DEFAULT 0
);
```

### `places` Table — Primary Domain Specification:
```sql
CREATE TABLE places (
    id              VARCHAR(20) PRIMARY KEY,        -- e.g., pl_cd8adfb1
    name            VARCHAR(150) NOT NULL,
    description     TEXT,
    district_id     VARCHAR(50),
    province_id     VARCHAR(50),
    category_id     VARCHAR(50),
    lat             DECIMAL(10, 7),
    lng             DECIMAL(10, 7),
    opening_hours   VARCHAR(50),
    mobile_signal   VARCHAR(20),
    road_condition  VARCHAR(30),
    activities      VARCHAR(255),
    tourist_popularity VARCHAR(20),
    family_friendly TINYINT(1) DEFAULT 0,
    budget_category VARCHAR(20),
    ticket_price    INT DEFAULT 0,                  -- Exact integer match to JSON API
    parking_avail   TINYINT(1) DEFAULT 0,
    toilets         TINYINT(1) DEFAULT 0,
    food_nearby     TINYINT(1) DEFAULT 0,
    wheelchair_access TINYINT(1) DEFAULT 0,
    camping_allowed TINYINT(1) DEFAULT 0,
    safety_level    VARCHAR(20),
    wildlife_hazard VARCHAR(50),
    guide_required  TINYINT(1) DEFAULT 0,
    rain_sensitivity VARCHAR(30),
    monsoon_note    VARCHAR(100),
    best_time_to_visit VARCHAR(50),
    height_m        DECIMAL(6,2) DEFAULT 0,
    length_km       DECIMAL(6,2) DEFAULT 0,
    surfing         TINYINT(1) DEFAULT 0,

    -- SYNC & VERSIONING CONTROL COLUMNS --
    is_deleted      TINYINT(1) DEFAULT 0,           -- Soft delete flag for client cache purging
    sync_version    BIGINT NOT NULL,                -- Global atomic counter value from sync_counter
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE INDEX idx_sync_version_unique (sync_version), -- Enforce DB-level uniqueness & fast B-Tree queries
    INDEX idx_is_deleted (is_deleted)
);
```

### `place_images` Table — Media Gallery Specification:
When any image row is modified or added, the Laravel observer increments `sync_counter` and updates the parent place's `sync_version`.

```sql
CREATE TABLE place_images (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    place_id    VARCHAR(20) NOT NULL,
    image_path  VARCHAR(255) NOT NULL,   -- High-res image (e.g., places/pl_cd8adfb1/full/1.webp)
    thumb_path  VARCHAR(255) NOT NULL,   -- Lightweight thumbnail (e.g., places/pl_cd8adfb1/thumb/1.webp)
    is_cover    TINYINT(1) DEFAULT 0,    -- Hero card image flag
    sort_order  INT DEFAULT 0,           -- Gallery display order
    sync_version BIGINT NOT NULL,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    INDEX idx_place_id (place_id),
    UNIQUE INDEX idx_sync_version_unique (sync_version)
);
```

### 🛡️ Atomic Increment & Soft Delete Protocol (Transactional Row Lock):
To prevent race conditions where concurrent admin edits generate duplicate `sync_version` numbers and disrupt pagination boundaries, counter increments MUST execute within an atomic transaction with a row lock (`FOR UPDATE`).

```sql
-- ✅ CORRECT (Transactional Row Lock + Atomic Assignment):
START TRANSACTION;
SELECT current_version FROM sync_counter WHERE id = 1 FOR UPDATE;
UPDATE sync_counter SET current_version = current_version + 1 WHERE id = 1;
-- Assign the locked incremented current_version to the target place row:
UPDATE places SET is_deleted = 1, sync_version = @new_counter_value, updated_at = NOW() WHERE id = 'pl_cd8adfb1';
COMMIT;
```
## ⚡ 6. Splash Screen Boot Lifecycle & Delta-Sync Integration

To deliver a seamless startup experience while executing paginated synchronization in the background, the boot engine is integrated into `SplashScreen` (via `appInitializationProvider`).

### Boot Sequence Timeline
```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 📱 APP LAUNCH (main.dart)                                                                       │
└───────────────────────────────────────────────┬─────────────────────────────────────────────────┘
                                                ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 🎬 RENDER SPLASH SCREEN (isReady: false) — Immersive 60fps Animation Without Freezing           │
└───────────────────────────────────────────────┬─────────────────────────────────────────────────┘
                                                ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 🔄 ASYNCHRONOUS BOOT ENGINE (Strict 2.5-Second Timeout for Rural 2G/3G Networks)                │
│  ├── Step 1: SQLite Mount ──────▶ Mount local SQLite DB (Ships 100% empty on 1st install).       │
│  ├── Step 2: Version Check ─────▶ GET /check-version (With X-API-KEY / Sanctum token header).    │
│  ├── Step 3: Paginated Sync ────▶ If 1st boot or server > local: fetch /delta?limit=100 chunks.  │
│  └── Step 4: RAM Hydration ─────▶ Hydrate SQLite records into memory (_memCache) for instant UI. │
└───────────────────────────────────────────────┬─────────────────────────────────────────────────┘
                                                ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│ ✅ TRANSITION TO HOME SCREEN (isReady: true) — Estimated <50ms UI Search & Filtering Response   │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Technical Implementation Workflow:
1. **Unblocked UI Mounting:** When the app opens, `HiddenGemsApp` immediately mounts `SplashScreen(isReady: false)`. Background tasks run asynchronously in a dedicated isolate.
2. **Option A Zero-Bundle Hydration:** On first installation, the app starts with an empty SQLite database. Upon detecting internet connectivity, it initiates a paginated loop (`since_version=0&limit=100`) to fetch all active records from MySQL in digestible chunks, populating SQLite sequentially without memory bloat. On subsequent launches, it only fetches incremental deltas where `sync_version > local_sync_version`.
3. **Rural Network Grace Period (2.5s Timeout):** To prevent startup delays in low-signal areas during routine updates, network delta checks enforce an estimated **2.5-second timeout**. If the network check times out, the app immediately transitions to offline mode using existing SQLite data.
4. **Cinematic Hand-Off:** Once SQLite is mounted and RAM cache (`_memCache`) is ready, `appInitializationProvider` resolves to `data`, switching the splash screen to `isReady: true` and smoothly navigating to `HomeScreen`.
