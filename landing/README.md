# IngatanKu landing page

**English** &nbsp;|&nbsp; [Bahasa Indonesia](README.id.md)

The page that brings in beta testers: Astro (static HTML) with React
islands for what moves. English at `/`, Indonesian at `/id/`.

```bash
npm install
npm run dev       # http://localhost:4321
npm run build     # static site in dist/
npm run preview
```

## What's where

| | |
|---|---|
| `src/i18n/strings.ts` | Every word on the page, in both languages. |
| `src/components/Landing.astro` | The page, section by section. |
| `src/components/Hero.tsx` | The opening: the egg hatching as you scroll. |
| `src/components/Bolubi.tsx` | Bolubi from the logo, in parts the hero can move. |
| `src/components/islands.tsx` | The moving bits: chat, quiz, growing up, wardrobe, widget, demo clips, the trailer, beta form, the helper in the corner. |
| `public/mascot/` | Stills of the pet, drawn by the app's own painter (`BlobMascot`). |
| `public/art/` | The pet's room and food, from the app's assets. |
| `public/video/en/`, `public/video/id/` | Demo clips recorded from the app with its language set to match the page (540 px wide, H.264, no sound). |
| `public/video/trailer-en.mp4`, `trailer-id.mp4` | The one-minute trailer, each with a `.jpg` poster. |
| `public/brand/` | Copies of `assets/brand/`. |

## Beta sign-ups

The form posts to the `beta-signup` edge function
(`supabase/functions/beta-signup`), which keeps one row per email in
`ingatanku.beta_signups` (migration `20261029000000_beta_signups.sql`).
Read them in the Supabase dashboard; set `invited_at` once someone is
added to the Play Store closed test.

## Deploy

On the server (`~/apps/ingatanku-landing`), the same way as the TemanLabsOS site:

```bash
docker compose up -d --build     # nginx on port 3014 (SITE_PORT to change it)
```

The public address comes through the Cloudflare tunnel: point
`ingatanku.temanlabs.tech` at the container's port.
