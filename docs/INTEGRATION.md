# Integration reference

Verified external reference material for the two backends this app will talk to. Everything
here was checked against the primary sources; nothing in this file is inferred from memory. If
you find something that contradicts it, the source wins — fix this file in the same commit.

---

## 1. Open Food Facts

### 1.1 Base URLs

| Purpose                  | URL                                                |
|--------------------------|----------------------------------------------------|
| Production (world)       | `https://world.openfoodfacts.org/`                  |
| Test / staging           | `https://world.openfoodfacts.net/`                  |
| Robotoff (AI predictions)| `https://robotoff.openfoodfacts.org/`               |

The app uses the world instance. `OpenFoodFactsService` paths are relative
(`api/v2/product/...`), and the base URL comes from
`BuildConfig.OPEN_FOOD_FACTS_BASE_URL`, so switching environments is a one-field change.

### 1.2 Single product — v2

```
GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json
```

**The `User-Agent` header is mandatory.** A request without a proper `User-Agent` is treated as
bot traffic and blocked. Required format:

```
AppName/Version (contact)
```

For example:

```
RacionTuDiarioDeMercado/1.0 (contact@example.com)
```

The value is built into `BuildConfig.OPEN_FOOD_FACTS_USER_AGENT` in `app/build.gradle.kts` and
attached by the OkHttp interceptor in `di/AppContainer.kt`. The contact is meant to be a real,
monitored address — the API terms ask for a way to reach you, and a `contact@example.com`
placeholder must be replaced before release.

Passing `?fields=` trims the response to just the keys you read. The full product object has
dozens of keys; the app requests:

```
code,product_name,brands,quantity,serving_quantity,serving_size,categories,
ingredients_text,nutrition_grades,image_front_url,nutriments
```

### 1.3 Response envelope — found vs not found

This is the single most important OFF detail, and it is a trap:

**Product found → HTTP 200**
```json
{
  "code": "3017620422003",
  "status": 1,
  "status_verbose": "product found",
  "product": { "product_name": "...", "nutriments": { ... } }
}
```

**Product NOT found → also HTTP 200**
```json
{
  "code": "0000000000000",
  "status": 0,
  "status_verbose": "product not found",
  "product": null
}
```

There is no 404. `status` is `1` for a hit and `0` for a miss, and `product` is `null` on a
miss. Any code that checks only the HTTP status and then dereferences
`body.product!!` crashes on the most common real-world case, which is a barcode that simply is
not in the database. Check the **body**.

### 1.4 `nutriments` field names

All values are **per 100 g**. The naming is not consistent, and that is not a typo:

| Domain field  | JSON key                  | Notes                            |
|---------------|---------------------------|----------------------------------|
| energy        | `energy-kcal_100g`        | **hyphen** before `kcal`         |
| carbohydrates | `carbohydrates_100g`      | **plural**                       |
| protein       | `proteins_100g`           | **plural**                       |
| fat           | `fat_100g`                | singular — the odd one out       |
| sugars        | `sugars_100g`             |                                  |
| fiber         | `fiber_100g`              | US spelling                      |
| sodium        | `sodium_100g`             | **grams**, not milligrams        |

Sodium in particular is easy to get wrong by three orders of magnitude: `sodium_100g` is in
grams. The 100 g values are often present while `sugars_100g`, `fiber_100g` and `sodium_100g`
are `null` for older crowd-sourced products, which is why every DTO field is nullable.

### 1.5 Free-text search — v2 does not support it

**Open Food Facts v2 has no free-text search.** The v2 search endpoints only do faceted/tag
filtering. Free text exists exclusively on the legacy CGI endpoint:

```
GET https://world.openfoodfacts.org/cgi/search.pl
    ?search_terms=arepa
    &search_simple=1
    &action=process
    &json=1
    &page=1
    &page_size=20
```

Response shape:

```json
{
  "count": 42,
  "page": 1,
  "page_size": 20,
  "products": [ { "code": "...", "product_name": "..." } ]
}
```

That is why `OpenFoodFactsService` talks to two different API generations: v2 for the product
read, v1 for the search. It is not an oversight, and it is not fixable by a v2 flag.

`search_simple=1` disables the spellcheck-and-rerank step — faster and more predictable for a
debounced type-ahead.

### 1.6 Rate limits

| Endpoint            | Limit              |
|---------------------|--------------------|
| Product read (v2)   | **15 requests/min** |
| Search              | **10 requests/min** |

Breaching the limit returns **HTTP 503**. The app must map that to `AppError.RateLimited` and
surface a "wait a moment" state, not a generic server error.

Two consequences that are easy to get wrong:

- **Search-as-you-type is explicitly forbidden.** The search budget is ~10 requests per minute —
  roughly three searches. Firing one request per keystroke exhausts it in under a second, gets
  the IP rate-limited, and can get the app blocked. Debounce and require an explicit submit.
- Product reads and searches have **separate** budgets, so a scan loop that reads a barcode per
  frame is the other way to get blocked fast. Scan once, then stop.

### 1.7 Images

The front-of-pack image is `image_front_url`, a direct HTTPS URL to a static image host
(`images.openfoodfacts.org` and mirrors). There is no image resizing parameter — the URL serves
one size, so client-side downscaling is the app's job (Coil does this).

Image URLs are frequently `null` for incomplete products. `FoodProduct.emoji` exists precisely so
a row always has a visual, without the domain depending on the network.

### 1.8 Licensing and attribution

| Asset | License | Obligation |
|-------|---------|------------|
| Product data (name, brands, categories, nutriments) | **ODbL** (Open Database License) | Share-alike + attribution if you redistribute |
| Product images | **CC-BY-SA** | Attribution + share-alike |
| The database as a whole | ODbL | Attribution to Open Food Facts is **required** |

Practical obligations before shipping:

1. **Attribution is required.** "Data from Open Food Facts" with a link to
   `https://world.openfoodfacts.org` must be visible wherever product data is shown. The app
   already links to a data-sources policy from the onboarding screen — that is the natural home
   for it.
2. **Share-alike is real.** ODbL and CC-BY-SA both require that derived, publicly-distributed
   databases be released under the same terms. This is the strongest argument against caching
   OFF responses into your own Firestore and then exposing that as a proprietary dataset.
3. **The API usage form must be filled in.** OFF asks apps to register their usage so they can
   get in touch about rate limits or breaking changes. Do this before publishing.
4. **Product data is crowd-sourced and wrong sometimes.** Treat any single value as a
   user-supplied claim, not a fact. That is a UI problem as much as a data problem.

---

## 2. Firebase Cloud Firestore

**Role in the architecture (since Phase 2 of the roadmap):** Firestore is the *remote projection /
sync layer*. The source of truth on device is ROOM (offline-first, delivery requirement). Every
fact below is still true of Firestore itself; the difference is who is authoritative. See §2.8.

### 2.1 Collection layout used by this app

```
users/{uid}
  ├─ profile                 -> UserProfile fields
  ├─ goals                   -> NutritionGoals fields
  ├─ onboarding/completed    -> { completed: bool }
  └─ days/{yyyy-MM-dd}       -> { kcal, carbsG, proteinG, fatG, updatedAt }   <- running totals
     └─ entries/{entryId}    -> individual DiaryEntry
```

- The `uid` is the Firestore Auth uid. With anonymous auth it is a random id that survives app
  restarts but **not** "clear app data" or a reinstall.
- The `yyyy-MM-dd` key is a lexical `LocalDate.toString()`, so `days/` is already in
  chronological order and a week is a simple range query.
- The `profile` / `goals` split is deliberate. Firestore's last-write-wins is per **document**,
  not per field, so sharing one document would let a "save goals" write silently overwrite a
  weight the user just typed.
- The onboarding flag is a **subdocument** because consent has to be writable on its own. A
  user who accepts the disclaimer and then fails to save their profile must still be recorded
  as consented.

### 2.2 Security rules — deny by default

Nothing is public. Every rule must verify ownership:

```
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;

  match /days/{dayId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
    match /entries/{entryId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

The default deny is what makes a missing rule safe. A rule you did not write blocks, it does not
allow.

### 2.3 `PersistentCacheSettings` vs the deprecated `setPersistenceEnabled`

Offline persistence is **on by default**. Modern Firestore configures it through
`PersistentCacheSettings`:

```kotlin
val settings = firestoreSettings {
    setLocalCacheSettings(PersistentCacheSettings.newBuilder().build())
}
firestore.setFirestoreSettings(settings)
```

The older `setPersistenceEnabled(true)` is **deprecated** and is a no-op on recent Android SDK
versions. Do not call it — the "fix" that looks like it is doing something is doing nothing.

### 2.4 The trap: settings must be set before any other call

`setFirestoreSettings()` **must run before any other call on that Firestore instance** —
including a snapshot listener, a `get()`, or a simple read. Calling it afterwards throws:

```
java.lang.IllegalStateException: Firestore has already been started.
```

This is a **runtime** failure, not a compile-time one, so the compiler will not help. That is
why it belongs in `RacionApplication.onCreate()`, not lazily inside a repository: a repository
may be constructed after some other code has already touched Firestore, and by then it is too
late. Configure once, at startup, in one place.

### 2.5 Write throughput: ~1 write/sec per document

Firestore allows roughly **one write per second per document**. A hot counter is the classic
way to hit that ceiling and start seeing `ABORTED` / contention errors.

This is why the design keeps a **running total per day** and never rewrites a single shared
"totals" document. Writing an entry:

1. `set` the entry subdocument — a *new* document, so no per-document rate limit applies.
2. `FieldValue.increment(...)` the four totals on `days/{date}`, plus
   `FieldValue.serverTimestamp()`.

`increment` is applied **server-side**, so two entries logged at the same instant from two
devices merge correctly. A read-modify-write of the total would lose one of them.

### 2.6 Transactions fail offline

A `runTransaction { ... }` that reads and then writes needs the **server** to arbitrate. With
no connectivity it throws instead of queueing. This app is used in a market with intermittent
signal, so a transaction that holds the day total is not an option. Individual `set` and
`increment` calls queue locally and flush when the connection returns, which is the behaviour
the diary actually wants.

### 2.7 Aggregate queries are server-side only

Firestore's `AggregateField.sum` **cannot run against the local cache**. This is the fact that
forces the whole daily-aggregate design:

| Approach                                   | Why it does not work here                                     |
|--------------------------------------------|---------------------------------------------------------------|
| Client-side `sum` over the week's entries  | Downloads every entry of the week on every screen open        |
| `AggregateField.sum`                        | Server-side only; useless offline, one round trip, no cache   |
| Client transaction that keeps a total       | Fails offline (§2.6) and hits ~1 write/sec per doc (§2.5)      |
| **Running total per day document**          | One read of 7 small documents, `increment` merges concurrently |

The trade-off accepted by the last row: deleting an entry needs a **compensating decrement**,
and the day document is a denormalised cache that a repair job must be able to rebuild from the
entries subcollection. Write that rebuild job before the first user, not after the first bug
report.

### 2.8 Offline-first sync with ROOM

ROOM is the source of truth on device; Firestore is the sync/backup projection. This is both a
delivery requirement (local DB + online service) and the right shape for a market app with
intermittent signal.

- Local day totals are computed with `SUM` in ROOM (roadmap `DB-4`). The remote `days/{date}`
  document keeps `FieldValue.increment` semantics so two devices syncing the same day merge
  correctly.
- Sync is idempotent on the entry id: push local writes (entry + increments) when connectivity
  returns, then pull remote changes. A pull **must never delete local rows that have not been
  pushed yet** — that is the one sync bug that silently destroys data.
- Conflict policy: last-write-wins per entry with server timestamps. No intra-entry merging.
- The `days/{date}` totals remain a denormalised cache repairable from `entries` — the repair job
  still exists and also runs locally from ROOM.

---

## 3. Quick links

- Open Food Facts API docs: <https://openfoodfacts.github.io/openfoodfacts-server/api/>
- Open Food Facts data licensing: <https://world.openfoodfacts.org/data>
- Open Food Facts rate limits / terms: <https://world.openfoodfacts.org/terms-of-use>
- Firestore data model: <https://firebase.google.com/docs/firestore/data-model>
- Firestore offline persistence: <https://firebase.google.com/docs/firestore/manage-data/enable-offline>
- Firestore queries and aggregation: <https://firebase.google.com/docs/firestore/query-data/aggregation-queries>
- Firestore security rules: <https://firebase.google.com/docs/firestore/security/rules-structure>
