# Landing page IngatanKu

[English](README.md) &nbsp;|&nbsp; **Bahasa Indonesia**

Halaman untuk menjaring beta tester: Astro (HTML statis) dengan React
islands untuk bagian yang bergerak. Bahasa Inggris di `/`, bahasa Indonesia di `/id/`.

```bash
npm install
npm run dev       # http://localhost:4321
npm run build     # situs statis di dist/
npm run preview
```

## Apa di mana

| | |
|---|---|
| `src/i18n/strings.ts` | Semua teks di halaman, dalam dua bahasa. |
| `src/components/Landing.astro` | Halamannya, bagian demi bagian. |
| `src/components/Hero.tsx` | Pembuka: telur yang menetas saat di-scroll. |
| `src/components/Bolubi.tsx` | Bolubi dari logo, dipecah per bagian supaya bisa digerakkan oleh hero. |
| `src/components/islands.tsx` | Bagian yang bergerak: chat, kuis, tumbuh besar, lemari baju, widget, klip demo, trailer, form beta, dan pembantu di pojok. |
| `public/mascot/` | Gambar diam si pet, digambar oleh painter app sendiri (`BlobMascot`). |
| `public/art/` | Kamar dan makanan si pet, dari aset app. |
| `public/video/en/`, `public/video/id/` | Klip demo yang direkam dari app dengan bahasa yang sama dengan halamannya (lebar 540 px, H.264, tanpa suara). |
| `public/video/trailer-en.mp4`, `trailer-id.mp4` | Trailer satu menit, dengan poster `.jpg` masing-masing. |
| `public/brand/` | Salinan `assets/brand/`. |

## Pendaftaran beta

Form-nya mengirim ke edge function `beta-signup`
(`supabase/functions/beta-signup`), yang menyimpan satu baris per email di
`ingatanku.beta_signups` (migration `20261029000000_beta_signups.sql`).
Lihat datanya di dashboard Supabase; isi `invited_at` setelah orangnya
dimasukkan ke closed test Play Store.

## Deploy

Di server (`~/apps/ingatanku-landing`), dengan cara yang sama seperti situs TemanLabsOS:

```bash
docker compose up -d --build     # nginx di port 3014 (ubah dengan SITE_PORT)
```

Alamat publiknya lewat Cloudflare tunnel: arahkan
`ingatanku.temanlabs.tech` ke port container-nya.
