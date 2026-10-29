// The IngatanKu landing page: static pages (English at /, Indonesian at
// /id/), with React islands for what moves.
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';

export default defineConfig({
  // The public address (canonical links, social previews); SITE_URL overrides it.
  site: process.env.SITE_URL || 'https://ingatanku.temanlabs.tech',
  integrations: [react()],
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'id'],
  },
});
