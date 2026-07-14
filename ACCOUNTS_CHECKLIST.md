# Hidden Gems SL — Accounts Checklist

App eka production-ta yanna one accounts ekathu tika, mokada, kohomada hadanne,
saha exact key eka kohede danna one kiyala. Tick karagena yanna.

Real values danna one 2 places:
- **Flutter app** → `dart_defines.json` (mulinma `cp dart_defines.example.json dart_defines.json`)
- **Laravel backend** → `laravel-backend/.env` (mulinma `cp .env.example .env`)

Deka-ma `.gitignore` eke thiyenawa — git ekata push wenne nathi, safe.

---

## 🔴 Priority 1 — App eka wada karanna one (essential)

### [ ] 1. Firebase project
**Mokada:** Auth, Firestore, Cloud Functions, Storage — app ekema backbone eka.
**Kohomada:** console.firebase.google.com → project ekak hadanna (dan thiyena `tripme-89742` eka use karanawada, aluth ekakda decide karanna).
**Danna:** `lib/firebase_options.dart` (FlutterFire CLI eken auto-generate wenawa).

### [ ] 2. Google Play Console
**Mokada:** Android ekata app eka publish karanna + subscriptions hadanna one place eka.
**Kohomada:** play.google.com/console — $25 one-time fee. Package name: `com.hidden.gems.hidden_gems_sl` (code eke thiyena eka match wenna one).
**Danna:** —  (console eke-ma configure wenawa, code ekata direct-ma danna dēyak nathi)

---

## 🟠 Priority 2 — Revenue (income enna)

### [ ] 3. RevenueCat
**Mokada:** Subscriptions (premium + guide plans) manage karanawa, Play Store/App Store dekatama connect karanawa.
**Kohomada:** revenuecat.com → project → Android/iOS app link karanna (Play Console eketama).
**Products hadanna one names** (code eke already hardcoded, exact match one):
- `hgems_explorer_monthly` — Rs. 499
- `hgems_premium_monthly` — Rs. 999
- `hgems_premium_annual` — Rs. 9,999
- `guide_pro_monthly` — $29
- `guide_elite_monthly` — $89
- Entitlement name: `premium_access` (okkoma premium products walata attach karanna)
**Danna:**
```
dart_defines.json:
  REVENUECAT_API_KEY_ANDROID=...
  REVENUECAT_API_KEY_IOS=...
```
**Note:** Products actual-ma **Play Console eke-ma** hadanna one (RevenueCat eka witharak hadanna beri).

### [ ] 4. AdMob
**Mokada:** Banner/native/interstitial/rewarded ads walin income.
**Kohomada:** admob.google.com → app add karanna → ad units 4ක් hadanna (Banner, Interstitial, Rewarded, Native).
**Danna:**
```
dart_defines.json:
  ADMOB_BANNER_ID=...
  ADMOB_INTERSTITIAL_ID=...
  ADMOB_REWARDED_ID=...
  ADMOB_NATIVE_ID=...
```
**Optional (ithuru income):** Mediation → Meta Audience Network + Unity Ads AdMob console eke add karanna.

### [ ] 5. PayHere — **DAN SKIP KARALA THIYENAWA** ⚠️
**Mokada:** Booking commission (10%) collect karana payment gateway eka.
**Status:** Backend code eka (PayHereController, webhook) **hadala thiyenawa, habai UI eken unwire kara** — dan bookings off-platform-ma (tourist-guide direct) settle wenawa.
**Passe hadanna one nam:** payhere.lk → merchant account (business reg + bank one). Danna: `laravel-backend/.env` eke `PAYHERE_MERCHANT_ID`/`PAYHERE_MERCHANT_SECRET`. Ithin `my_bookings_screen.dart` eke "Pay Now" button eka ayemath enable karanna kiyanna (5 min wada).

---

## 🟡 Priority 3 — Security (recommended, urgent nemei)

### [ ] 6. Firebase App Check enforce
**Mokada:** Real anti-clone/anti-bot control eka — client code eka already wired.
**Kohomada:** Firebase Console → App Check → Play Integrity (Android) register karanna → 24-48h monitor karala → "Enforce" press karanna.
**Danna:** — (console toggle eka witharai)

### [ ] 7. HMAC_SECRET (Zenith request signing activate karanna)
**Mokada:** Request tampering/replay protect karana middleware eka — code eka wired, secret eka witharai one.
**Kohomada:** Random 32-char string ekak generate karanna (`openssl rand -hex 16` wage command ekakin).
**Danna (deka-tama ekama value eka one):**
```
laravel-backend/.env:  HMAC_SECRET=...
dart_defines.json:     HMAC_SECRET=...
```

---

## 🟢 Priority 4 — Other (rendered/nice-to-have)

### [ ] 8. Weather API
**Mokada:** Monsoon alerts / weather widget.
**Kohomada:** weatherapi.com (free tier) → API key.
**Danna:** `dart_defines.json: WEATHER_API_KEY=...`

### [ ] 9. Apple App Store (iOS build karanawada nam witharai)
**Mokada:** iOS ekata publish karanna, App Store ID eka.
**Kohomada:** developer.apple.com → $99/yr.
**Danna:** `dart_defines.json: APP_STORE_ID=...`

### [ ] 10. Self-hosted AI model server
**Mokada:** Oracle chat + Trip Planner + food scan — oyage own trained model eka host karana VPS eka.
**Kohomada:** `ai-server/README.md` file eka balanna (session eke hadala thiyena FastAPI scaffold eka) — model eka train karala ivara unama, VPS ekakata deploy karanna.
**Danna:** `dart_defines.json: PYTHON_BACKEND_URL=...` + `laravel-backend/.env: PYTHON_BACKEND_URL=...` (⚠️ `/api` suffix eka dekakatama wenas — README eke pahadili karala thiyenawa).

---

## Quick reference — file 2ma location

```
c:\Users\sehas\.gemini\antigravity\scratch\hidden_gems_sl\
  dart_defines.example.json   ← copy karala dart_defines.json widiyata
  laravel-backend\.env.example ← copy karala .env widiyata
```

Build karana kota:
```powershell
./scripts/build_release.ps1
```
(Meka automatic-ma `dart_defines.json` eken keys load karanawa + obfuscation enforce karanawa.)
