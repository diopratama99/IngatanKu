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
| **Voice-to-Note** | Tap mikrofon di halaman Tambah Catatan, dikte langsung jadi teks (on-device speech-to-text). |
| **Tanya Otak Kedua** | RAG chat di atas catatanmu sendiri. Streaming jawaban via Server-Sent Events. |
| **Berbagi Publik** | Generate tautan baca-saja (`/share/:token`) untuk catatan yang ingin kamu bagikan. |
| **Share Intent** | Klik tombol Bagikan dari aplikasi lain (browser, IG, dll) langsung masuk ke alur Tambah Catatan. |
| **Streak & Reminder** | XP, level, dan notifikasi lokal harian agar konsistensi belajar terjaga. |
| **7 Lencana Bawaan** | Diberikan otomatis berdasarkan pola perilaku (lihat tabel di bawah). |
| **UI Editorial** | Latar netral, tipografi Space Grotesk + Inter, satu warna aksen indigo, hairline divider. |

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
│   ├── auth/          # login, signup, OTP verification
│   ├── vault/         # CRUD catatan, tag, share, list
│   ├── ai_chat/       # RAG chat dengan SSE streaming
│   ├── dashboard/     # XP, streak, daftar terbaru
│   ├── gamification/  # Lencana
│   └── profile/       # Pengaturan akun
├── app.dart           # MaterialApp + global providers
└── main.dart          # Entry point + DI bootstrap
```

Skema database (3 migrasi di `supabase/migrations/`):

| Tabel | Kegunaan |
|---|---|
| `profiles` | XP, level, username, streak |
| `content_vault` | Catatan (URL, judul, markdown, tag, embedding `vector(1536)`) |
| `badges` | Master list lencana |
| `user_badges` | Lencana yang sudah didapat user |
| `chat_messages` | Riwayat chat (per user) |
| `share_links` | Token untuk berbagi catatan publik |

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
```

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

Diberikan otomatis oleh logika di klien berdasarkan `content_vault`:

| Kode | Nama | Pemicu |
|---|---|---|
| `BUG_HUNTER` | Bug Hunter | 5 catatan ber-tag `debugging` |
| `FRAMEWORK_MASTER` | Framework Master | 10 catatan tentang satu framework yang sama |
| `CONSISTENCY_KING` | Consistency King | Streak 7 hari berturut-turut |
| `MIDNIGHT_CODER` | Midnight Coder | 7 catatan disimpan antara 00.00–04.00 |
| `THE_ORACLE` | The Oracle | 50 pertanyaan ke AI Brain |
| `POLYGLOT` | The Polyglot | Catatan dari 5 bahasa/framework berbeda |
| `KNOWLEDGE_CARTOGRAPHER` | Knowledge Cartographer | 25 tag unik dipakai |

---

## Keamanan

Project ini dirancang aman untuk di-push ke repo publik. Catatan penting:

- **Tidak ada secret di source code.** Semua kredensial di-inject lewat `--dart-define-from-file=supabase.json` saat build, bukan di-bundle.
- **`supabase.json`** (kredensial Flutter) dan **`android/key.properties`** (signing key Android) sudah di-gitignore. Hanya `supabase.example.json` yang ikut.
- **Service role key Supabase** hanya hidup di environment Edge Functions (`Deno.env.get`) — tidak pernah dipakai di klien Flutter. Klien hanya pakai *anon key* yang aman dipublikasikan.
- **OpenAI API key** disimpan sebagai Supabase secret, dipakai *server-side* di `ask-brain` dan `embed-note`. Klien tidak pernah memegang API key LLM.
- **Row Level Security** aktif di semua tabel user — lihat `supabase/migrations/20260101000000_init.sql`.

### Sebelum push ke GitHub

Jalankan sanity check:

```powershell
# pastikan tidak ada file kredensial yang ke-stage
git status
git ls-files | Select-String -Pattern "supabase\.json|key\.properties|\.keystore|\.jks|\.env$"
```

Output kedua perintah harus **kosong** (kecuali `supabase.example.json`).

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

- [ ] Sinkronisasi offline-first dengan Drift
- [ ] Export catatan ke Obsidian / Markdown ZIP
- [ ] Voice-to-Note dengan Whisper (di server)
- [ ] Tag suggestions berbasis embedding (otomatis dari isi catatan)
- [ ] Tema terang (saat ini hanya gelap)

---

## Lisensi

[MIT](LICENSE) © 2026 — kontribusi & fork dipersilakan.
