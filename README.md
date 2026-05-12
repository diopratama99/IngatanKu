# IngatanKu

> **Otak kedua tech-mu.** Simpan konten teknis dari mana saja, lalu tanyakan kembali ke AI yang tahu isi catatanmu.

IngatanKu adalah aplikasi Flutter + Supabase untuk para tech enthusiast yang ingin mengubah Reels, Shorts, TikTok, X, dan artikel jadi pengetahuan yang bisa dicari dan ditanyakan. Dibangun dengan **Retrieval-Augmented Generation** (pgvector + LLM) sehingga AI hanya menjawab berdasarkan catatan kamu sendiri — bukan halusinasi internet.

UI-nya editorial: tipografi besar, hierarki tegas, satu warna aksen — bahasa visual ala majalah teknologi modern, bukan dashboard penuh neon.

---

## Daftar Isi

- [Fitur](#fitur)
- [Stack](#stack)
- [Arsitektur](#arsitektur)
- [Persiapan Lokal](#persiapan-lokal)
- [Deploy Backend](#deploy-backend)
- [Menjalankan Aplikasi](#menjalankan-aplikasi)
- [Lencana Bawaan](#lencana-bawaan)
- [Keamanan](#keamanan)
- [Skrip Berguna](#skrip-berguna)
- [Roadmap](#roadmap)
- [Lisensi](#lisensi)

---

## Fitur

| Fitur | Deskripsi |
|---|---|
| **Brankas Catatan** | Simpan URL + catatan markdown + tag. Auto-deteksi sumber (YouTube, TikTok, IG, X, artikel). |
| **Auto URL Preview** | Tempel link, Edge Function `fetch-meta` ambil judul, deskripsi, dan thumbnail otomatis. |
| **Auto-Fill ✨** | Tap ikon sparkle di toolbar → LLM streaming generate catatan markdown dari transcript YouTube, isi artikel, atau OG metadata. Locale toggle ID/EN. |
| **Voice-to-Note** | Tap mikrofon di halaman Tambah Catatan, dikte langsung jadi teks (on-device speech-to-text). |
| **Tanya Otak Kedua** | RAG chat di atas catatanmu sendiri. Streaming jawaban via Server-Sent Events. |
| **Download Video/Foto** | Simpan video YouTube/TikTok/IG/X ke perangkat untuk akses offline. Backed by self-hosted [Cobalt](https://github.com/imputnet/cobalt) v10 dengan fallback OG-image scraper. |
| **Quiz Mingguan** | 5 pertanyaan multiple choice di-generate LLM dari catatan 7 hari terakhir. Skor + XP reward + badge `WEEKLY_REVIEWER`. Idempoten per minggu (Senin anchor). |
| **Berbagi Publik** | Generate tautan baca-saja (`/share/:token`) untuk catatan yang ingin kamu bagikan. |
| **Share Intent** | Klik tombol Bagikan dari aplikasi lain (browser, IG, dll) langsung masuk ke alur Tambah Catatan. |
| **Onboarding 4 Slide** | Welcome flow editorial untuk pengguna baru pasca-OTP — brand mark, capture, ask, streak. Existing user di-skip langsung ke `/dashboard`. |
| **Manajemen Tag** | Halaman dedicated untuk rename / hapus tag massal — semua catatan ber-tag tersebut otomatis ter-update. |
| **Knowledge Map** | Visualisasi editorial distribusi tag (bar chart tipografi, bukan bubble cloud) — top topik, share dominan, ranking 1..N. |
| **Notes Stats** | Breakdown analitik atas brankas: per sumber, per periode (minggu / bulan / lampau), per tag. |
| **Badges Stats** | Halaman detail progress lencana — dipasangkan ke setiap badge dengan progress bar tipis. |
| **Streak & Reminder** | XP, level, dan notifikasi lokal harian agar konsistensi belajar terjaga. |
| **8 Lencana Bawaan** | Diberikan otomatis berdasarkan pola perilaku (lihat tabel di bawah). |
| **Android Home Widget** | Widget homescreen yang menampilkan 3 catatan terakhir + pintasan `Catat baru`. RemoteViews-safe layout, di-update lewat `home_widget` plugin. |
| **Halaman Privacy & About** | Static pages editorial — kebijakan data + ringkasan stack, dipasang di Profile. |
| **Brand Mark** | Logo IK monogram (indigo gradient + white serif-grotesque K) — sama persis di onboarding slide pertama, app icon (iOS rounded square + Android adaptive), dan splash. |
| **UI Editorial** | Latar netral `#0F172A`, tipografi Space Grotesk + Inter, satu warna aksen indigo, hairline divider, dialog confirm pakai SpaceGrotesk title + danger/primary CTA. |

---

## Stack

| Lapisan | Teknologi |
|---|---|
| **Frontend** | Flutter 3.19+, Clean Architecture, BLoC, GoRouter, GetIt, Dartz |
| **Backend** | Supabase (Postgres + Auth + Storage + Realtime) |
| **Vector Search** | `pgvector` extension + `match_notes` RPC |
| **AI Provider** | OpenAI-compatible API (OpenAI, GitHub Models, OpenRouter — bebas pilih lewat `OPENAI_BASE_URL`) |
| **Logic Server** | Supabase Edge Functions (Deno + TypeScript) |
| **Tipografi** | Inter (body) + Space Grotesk (display) + JetBrains Mono (code) via `google_fonts` |

### Edge Functions

| Fungsi | Tugas | Trigger |
|---|---|---|
| `fetch-meta` | Ambil OG-tags dari URL eksternal | Dipanggil dari client saat tempel link |
| `embed-note` | Generate embedding vector untuk catatan baru | Database webhook `INSERT` di `content_vault` |
| `ask-brain` | RAG: cari catatan relevan + stream jawaban LLM | Dipanggil dari halaman Chat |
| `auto-summarize` | Fetch konten URL (transcript YouTube / artikel / OG meta) lalu stream catatan markdown via SSE | Tap ✨ di toolbar Tambah Catatan |
| `resolve-media` | Wrap Cobalt API untuk resolve URL ke direct download link, fallback OG-image | Tap Download di card SIMPAN OFFLINE |
| `generate-weekly-quiz` | Bangun 5 pertanyaan MC via LLM dari catatan 7 hari terakhir, persist ke `weekly_quizzes` | Buka section Quiz Mingguan di dashboard |

---

## Arsitektur

Feature-first Clean Architecture. Setiap fitur punya tiga lapis: `data/`, `domain/`, `presentation/`.

```
lib/
├── core/
│   ├── config/        # Env (compile-time)
│   ├── constants/     # Nama tabel, RPC, edge function
│   ├── di/            # GetIt service locator
│   ├── errors/        # Failure & Exception
│   ├── network/       # SupabaseService wrapper
│   ├── notifications/ # Local notification scheduler
│   ├── router/        # GoRouter + ShellRoute
│   ├── share_intent/  # Receive shared text/URL
│   ├── theme/         # AppColors, AppTheme
│   └── utils/         # Extensions
├── shared/
│   └── widgets/       # editorial.dart (SectionHeader, EditorialButton, dll)
├── features/
│   ├── auth/          # login, signup, OTP verification, forgot password
│   ├── onboarding/    # 4-slide welcome flow (post-OTP, fresh users only)
│   ├── vault/         # CRUD catatan, tag mgmt, share, knowledge map, stats
│   ├── ai_chat/       # RAG chat dengan SSE streaming
│   ├── dashboard/     # XP, streak, daftar terbaru, level ring
│   ├── gamification/  # 8 lencana + halaman progress
│   ├── quiz/          # Quiz mingguan dari catatan 7 hari
│   └── profile/       # Pengaturan akun, privacy, about, sign-out
├── app.dart           # MaterialApp + global providers
└── main.dart          # Entry point + DI bootstrap
```

Skema database (4 migrasi di `supabase/migrations/`):

| Tabel | Kegunaan |
|---|---|
| `profiles` | XP, level, username, streak |
| `content_vault` | Catatan (URL, judul, markdown, tag, embedding `vector(1536)`) |
| `badges` | Master list lencana |
| `user_badges` | Lencana yang sudah didapat user |
| `chat_messages` | Riwayat chat (per user) |
| `share_links` | Token untuk berbagi catatan publik |
| `weekly_quizzes` | Quiz mingguan tergenerate (questions JSONB, jawaban user, skor) |

---

## Persiapan Lokal

### Prasyarat

- **Flutter** 3.19 atau lebih baru — `flutter --version`
- **Dart** 3.3+
- **Supabase CLI** — `npm i -g supabase`
- **Akun Supabase** dengan project kosong
- **API key** untuk provider OpenAI-compatible (OpenAI, GitHub Models PAT, dll)

### Clone & install dependensi

```bash
git clone https://github.com/<username>/ingatanku.git
cd ingatanku
flutter pub get
```

> Folder platform (`android/`, `ios/`, `web/`, dll) sudah ter-include. Tidak perlu `flutter create`.

---

## Deploy Backend

### 1. Link project Supabase

```bash
supabase login
supabase link --project-ref <YOUR_PROJECT_REF>
```

### 2. Push migrasi database

```bash
supabase db push
```

Migrasi ini membuat semua tabel, enable extension `pgvector`, dan menambahkan RPC `match_notes` untuk pencarian semantik.

### 3. Set secret untuk Edge Functions

```bash
# Wajib
supabase secrets set OPENAI_API_KEY=<api-key-kamu>

# Opsional — kalau pakai provider non-OpenAI
supabase secrets set OPENAI_BASE_URL=https://models.inference.ai.azure.com   # GitHub Models
supabase secrets set OPENAI_CHAT_MODEL=gpt-4o-mini
supabase secrets set OPENAI_EMBED_MODEL=text-embedding-3-small
```

### 4. Deploy Edge Functions

```bash
supabase functions deploy ask-brain
supabase functions deploy embed-note --no-verify-jwt
supabase functions deploy fetch-meta
supabase functions deploy auto-summarize
supabase functions deploy resolve-media
supabase functions deploy generate-weekly-quiz
```

> Untuk **self-hosted Supabase** (docker-compose), edge function di-mount dari `volumes/functions/`. Setelah copy folder fungsi ke sana, tambah env baru ke blok `environment:` service `functions` di `docker-compose.yml` (mis. `COBALT_API_BASE: ${COBALT_API_BASE}`) lalu `docker compose up -d functions` (bukan cuma restart — perlu recreate).

### 5. Pasang Database Webhook

Di Supabase Dashboard → **Database → Webhooks → Create**:

| Kolom | Nilai |
|---|---|
| Name | `embed-on-insert` |
| Table | `content_vault` |
| Events | `INSERT` |
| Type | HTTP Request |
| Method | `POST` |
| URL | `https://<project-ref>.functions.supabase.co/embed-note` |
| HTTP Headers | `Content-Type: application/json` |

Tujuannya: setiap catatan baru otomatis di-embed jadi vector tanpa blocking UI.

### 6. (Opsional) Self-host Cobalt untuk Download Video/Foto

Fitur **Download Video/Foto** memerlukan instance [Cobalt](https://github.com/imputnet/cobalt) yang reachable dari edge function `resolve-media`. Karena public Cobalt API (`api.cobalt.tools`) sejak v10 tidak menerima request anonim, paling reliable di-self-host.

Minimal setup di server Docker yang sama dengan Supabase:

```bash
docker run -d \
  --name cobalt-api \
  --network supabase_default \
  --restart unless-stopped \
  -p 9000:9000 \
  -e API_URL="https://cobalt.<your-domain>/" \
  -e DURATION_LIMIT="10800" \
  ghcr.io/imputnet/cobalt:10
```

Lalu set env `COBALT_API_BASE` di Supabase secrets / `.env` self-hosted (default fallback `https://api.cobalt.tools` kalau tidak di-set):

```bash
supabase secrets set COBALT_API_BASE=http://cobalt-api:9000
```

> `API_URL` di container Cobalt **harus** URL yang HP user bisa reach — untuk tunnel mode (IG/TikTok), Cobalt return URL pakai `API_URL` ini. Pakai Cloudflare Tunnel / domain publik kalau user di luar LAN/Tailscale.
>
> Tanpa Cobalt, fitur download masih jalan tapi cuma untuk OG-image / thumbnail (tidak bisa video).

---

## Menjalankan Aplikasi

### 1. Buat file kredensial lokal

Salin template lalu isi nilainya — file ini **wajib di-gitignore** (sudah).

```bash
cp supabase.example.json supabase.json
```

Isi `supabase.json`:

```json
{
  "SUPABASE_URL":      "https://your-project-ref.supabase.co",
  "SUPABASE_ANON_KEY": "eyJhbGciOi..."
}
```

### 2. Jalankan

**Cara cepat (Windows / PowerShell):**

```powershell
.\run.ps1                 # device default
.\run.ps1 -d chrome       # web
.\run.ps1 --release       # build release
```

**Cara manual (semua OS):**

```bash
flutter run --dart-define-from-file=supabase.json
```

> `String.fromEnvironment` membaca nilai saat *compile time*, jadi tidak ada secret yang ke-bundle ke source code.

### 3. Build untuk rilis

```bash
# Android
flutter build apk --release --dart-define-from-file=supabase.json
flutter build appbundle --release --dart-define-from-file=supabase.json

# iOS
flutter build ipa --release --dart-define-from-file=supabase.json

# Web
flutter build web --release --dart-define-from-file=supabase.json
```

---

## Lencana Bawaan

Diberikan otomatis oleh logika di klien berdasarkan `content_vault`, kecuali `WEEKLY_REVIEWER` yang dibuka via RPC `award_quiz_completion` saat user menyelesaikan Quiz Mingguan.

| Kode | Nama | Pemicu |
|---|---|---|
| `BUG_HUNTER` | Bug Hunter | 5 catatan ber-tag `debugging` |
| `FRAMEWORK_MASTER` | Framework Master | 10 catatan tentang satu framework yang sama |
| `CONSISTENCY_KING` | Consistency King | Streak 7 hari berturut-turut |
| `MIDNIGHT_CODER` | Midnight Coder | 7 catatan disimpan antara 00.00–04.00 |
| `THE_ORACLE` | The Oracle | 50 pertanyaan ke AI Brain |
| `POLYGLOT` | The Polyglot | Catatan dari 5 bahasa/framework berbeda |
| `KNOWLEDGE_CARTOGRAPHER` | Knowledge Cartographer | 25 tag unik dipakai |
| `WEEKLY_REVIEWER` | Weekly Reviewer | Selesaikan Quiz Mingguan pertama |

---

## Skrip Berguna

```bash
# Analisis kode (lint + type check)
flutter analyze

# Test
flutter test

# Format
dart format lib/ test/

# Bersihkan build cache
flutter clean
```

---

## Roadmap

- [x] Welcome onboarding flow (4 slides editorial)
- [x] Tag management (rename / delete massal)
- [x] Knowledge map editorial (typografi, bukan bubble cloud)
- [x] Notes stats & badges stats pages
- [x] Android home widget (3 catatan terbaru + shortcut)
- [x] Brand mark + app icon (IK monogram, iOS rounded square + Android adaptive)
- [x] Auto-Fill catatan dari URL via LLM streaming
- [x] Download offline video/foto (Cobalt-backed)
- [x] Quiz Mingguan dari catatan minggu berjalan
- [ ] iOS WidgetKit equivalent untuk home widget
- [ ] Sinkronisasi offline-first dengan Drift
- [ ] Export catatan ke Obsidian / Markdown ZIP
- [ ] Voice-to-Note dengan Whisper (di server)
- [ ] Tag suggestions berbasis embedding (otomatis dari isi catatan)
- [ ] Tema terang (saat ini hanya gelap)
- [ ] Cross-device sync untuk file Download (Supabase Storage opsional)

---

## Lisensi

[MIT](LICENSE) © 2026 — kontribusi & fork dipersilakan.
