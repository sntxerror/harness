# GCP Account Audit — findings & current state

Account: `forhotchpotch@gmail.com` · Last verified: 2026-07-18

## Live projects (3)

| Project ID | Name | Billing | Purpose |
|---|---|---|---|
| `gen-lang-client-0054709975` | Pi Agent | **Paid** (`cloud-and-ai`) | Gemini API — key `pi-web-search-gemini`. Active, current usage (~112 req/7d). Paid tier means every call is billed per-token, no free allowance. |
| `gen-lang-client-0681365425` | gemini-unbilled | **None** — confirmed free tier | Gemini API — key "Gemini API Unbilled". Created for guaranteed zero-cost development. Verified working via live `generateContent` call. |
| `o2pets-mw` | o2pets-mw | **Paid** (`cloud-and-ai`) | Real deployed app: Cloud Run service `shopify-bitrix-middleware` + Artifact Registry repo `shopify-bitrix`. Excluded from quota CSVs by request but project itself untouched. |

## Deleted projects (5) — recoverable 30 days from deletion via `gcloud projects undelete <id>`

| Project ID | Was | Why removed |
|---|---|---|
| `gen-lang-client-0584962304` | Gemini Project Test | Zero real usage, empty shell |
| `gen-lang-client-0863237222` | Pi Agent #2 | Zero API calls ever, despite billing enabled |
| `gen-lang-client-0972429569` | Default Gemini Project | Zero real usage |
| `ndzn-456922` | ndzn | BigQuery/Storage/Dataplex enabled but 0 buckets, 0 datasets — dormant since Apr 2025 |
| `gen-lang-client-0846987250` | Gemini API | Misleading name — 0 Gemini calls in 30d. The 273K-request burst (Jun 29–30) was **rclone OneDrive→Google Drive migration**, not LLM usage. Migration confirmed done, user requested removal. |

## Billing accounts

| Account | Currency | Status | Linked projects |
|---|---|---|---|
| `cloud-and-ai` (`01C3A1-E1DE92-B5351C`) | USD | **Open** | `gen-lang-client-0054709975`, `o2pets-mw` |
| `My Billing Account` (`016D71-5EC8FA-67FBD8`) | ILS | Closed | none (harmless legacy, zero risk) |

- Sole billing admin: `forhotchpotch@gmail.com`. No excess/stray payment setups.
- **No budget alerts configured** on `cloud-and-ai` — no automated spend warning exists today.
- ~$10 was topped up onto `cloud-and-ai`. It's tied to the *billing account*, not any project — unlinking a project from billing doesn't forfeit it; it just sits in reserve.

## Key mechanic: Gemini API free vs. paid tier

Not "free quota first, then billed" — it's **either/or per project**:
- **No billing account on the project** → free tier: hard-capped rate limits, literally cannot be charged.
- **Billing account linked** → paid tier: free-tier quota rows go inactive (`NULL`), every request is billed per-token from request #1, in exchange for much higher throughput.

Confirmed directly from each project's own Cloud Quotas data (`quota_increase_ineligibility_reason = NO_VALID_BILLING_ACCOUNT` on all rows = free; absent = paid).

A generic key created via `gcloud services api-keys create` returned `API_KEY_INVALID` against the real Gemini endpoint even when unrestricted — Google gates actual key activation behind something beyond plain API-key creation (likely a one-time account-level verification, already satisfied). Keys minted through the **AI Studio UI** on an unbilled project work fine and are genuinely free — this is how `gemini-unbilled` was created and verified.

## Free-tier capability map (from `gen-lang-client-0681365425`, genuinely unbilled)

| Capability | Free? | Limits |
|---|---|---|
| `gemini-2.5-flash` | ✅ | 5 req/min, **20 req/day**, 250K input tokens/min |
| `gemini-2.5-flash-lite` | ✅ | 10 req/min, 20 req/day, 250K tokens/min |
| `gemini-2.5-pro` | ❌ | **Not available free at all** — every limit is `NULL`, billing required to use it |
| Embeddings (`gemini-embedding-1.0`) | ✅ | 100 req/min, 1000 req/day, 30K tokens/min |
| Imagen 3.0 | ✅ | 5 images/day, 25 predict req/day |
| Imagen 4.0 (incl. fast/ultra) | ❌ | Paid only |
| Voice/TTS (Create Voice API) | ✅ | 5 req/min, 10 req/day |
| File storage / File Search | ✅ | 20 GiB, 3000 req/min |
| Batch API | ❌ | Paid only, no free rows exist |
| Context caching | ⚠️ | Token cap unlimited but storage/creation rides on paid billing |

**Bottleneck to know:** 20 req/day on `gemini-2.5-flash` is the real free ceiling — tight for active daily development.

## Actual spend so far (paid-tier project)

Computed from real per-model output-token usage (Cloud Monitoring metric `generativelanguage.googleapis.com/generate_content_usage_output_token_count`) × live pricing fetched from `ai.google.dev/gemini-api/docs/pricing` on 2026-07-18 — not from memory, since some models postdate this assistant's training data.

| Model | Output tokens (30d) | Price/1M output | Cost |
|---|---:|---:|---:|
| `gemini-2.5-flash-lite` | 3,876 | $0.40 | $0.0016 |
| `gemini-2.5-flash` | 429 | $2.50 | $0.0011 |
| `gemini-3.1-flash-lite` | 7,512 | $1.50 | $0.0113 |
| `gemini-3.5-flash` | 60,433 | **$9.00** | **$0.5439** |
| **Total (output tokens only)** | 72,250 | — | **≈ $0.56** |

- Input-token cost isn't included (no input-token usage metric is exposed via Monitoring for this API) but looks minor — the one live test call was 8 input vs 11 output + 380 thinking tokens.
- `gemini-3.5-flash` is responsible for ~97% of the spend — at $9/M output tokens it's ~4x `gemini-2.5-flash` and ~22x `gemini-2.5-flash-lite`. Primary lever if cost matters.
- This is a metrics-based estimate, not the literal invoice. No `gcloud billing` subcommand exposes exact charged $ (confirmed — no cost/report/invoice command exists anywhere in `gcloud billing`); the penny-exact figure only lives in Console → Billing → Reports.
- Of the $10 topped up, roughly $0.56 consumed in the last 30 days — comfortable headroom.

## Free-tier quota reference, beyond text chat

Pulled from `gen-lang-client-0681365425` (confirmed unbilled). All models below are the **public, documented** ones — the raw quota data also lists ~15 internal/eval codenames (`chat-bard`, `xyz-100x`, random hashes like `gqi-cst-h34jgm`, `med-gemini`, etc.) with huge free allowances (some over 1M req/day) that are **not real public API model names** — they're Google-internal test/eval slots, included here for completeness but not callable by a normal key.

**Standout finding — Gemma has a far more generous free tier than Gemini:**

| Model family | Free RPM | Free RPD |
|---|---:|---:|
| **Gemma 3 / Gemma 4 (all sizes, 1B–31B)** | 30 | **14,400** |
| `learnlm-2.0-flash-experimental` (education-tuned) | 15 | 1,500 |
| `gemini-2.5-flash` / `gemini-3.5-flash` / `gemini-3-flash` | 5 | 20 |
| `gemini-2.5-flash-lite` | 10 | 20 |
| `gemini-robotics-er-1.5/1.6-preview` | 5–10 | 20 |
| `gemini-2.5-pro` and all `*-live`/native-audio models | 0 (no free tier) / unmetered-by-count | — |

**If daily request volume matters more than model quality, Gemma's 14,400/day free vs. Gemini Flash's 20/day is a 720x difference** — worth building against Gemma for anything high-volume and free.

**Other capabilities:**
| Capability | Free tier | Limits |
|---|---|---|
| Search grounding (Google Search tool) | ✅ | **1,500 requests/day** — generous |
| Map grounding | ✅ | 500 requests/day |
| FileSearchStore (RAG file search) | ✅, flat (not tier-gated) | 3,000 req/min create/read/write, 60 req/min store-create |
| Semantic Retriever (legacy RAG API) | ✅, flat | 6 req/min corpus mgmt, 42 req/min retrieval |
| Veo (video generation) | ❌ mostly paid-only | Only a deprecated preview model (`veo-001-preview-0815`) has a free row; `veo-2.0`/`veo-3.0` public models are paid-only |
| Code execution tool | Not tracked | No quota rows found under Cloud Quotas for this — not gated the same way |
| Fine-tuning (`tunedModels`) | Not tracked | No quota rows found — not gated the same way |

## Open items / not yet decided

- [ ] `gen-lang-client-0054709975` still has billing linked and is paid-tier — offered to unlink (`gcloud billing projects unlink gen-lang-client-0054709975`), not yet actioned.
- [ ] No budget alert on `cloud-and-ai` — recommended, not yet created.
- [ ] Local file `#RD/key` contains a raw Gemini API key in plaintext (the unbilled one — low risk since it can't incur charges, but avoid committing/sharing it).

## Data files (this directory)

- `gcp_quotas.csv` — full quota data for both Gemini projects (2,838 rows): `project_id, service, quota_id, metric, metric_display_name, metric_unit, dimensions (e.g. model=...), quota_value, refresh_interval, quota_increase_eligible/ineligibility_reason, ...`
- `gcp_quotas_ai_studio.csv` — deduped free-tier-only reference (1,412 rows), sourced from the confirmed-unbilled project.
- Query either with **DuckDB** (installed via `curl https://install.duckdb.org | sh`): `duckdb -c "SELECT ... FROM 'gcp_quotas.csv' WHERE ..."` — keeps large lookups out of chat context.
