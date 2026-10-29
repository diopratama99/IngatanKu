# IngatanKu brand

Vector masters for the logo. Everything else (launcher icons, store
art, the promo videos) should be drawn from these. None of it is bundled
into the app.

| File | What |
|---|---|
| `ingatanku-logo.svg` | Bolubi reading, with the wordmark under it. The main logo. |
| `bolubi.svg` | Bolubi reading, no wordmark. Avatars, stickers, small spaces. |
| `ingatanku-wordmark.svg` | "Ingatanku" alone. |
| `app-icon.svg` | 1024 px square on cream: iOS, web, Android before 8.0. |
| `app-icon-foreground.svg` | Android adaptive-icon foreground: Bolubi alone, sized into the 66dp safe circle of the 108dp canvas. |

All have transparent backgrounds except `app-icon.svg`. They're drawn
for light backgrounds; the ground shadow under the book disappears on
anything darker than cream.

After editing an icon SVG, run `tools/make_icons.sh` to redraw the
PNGs in `assets/icons/` and regenerate the launcher icons. The status-bar
notification icon (`android/app/src/main/res/drawable/ic_stat_bolubi.xml`)
is the same shapes as a white silhouette, kept by hand.

## Colours

| | |
|---|---|
| Cream (icon background) | `#FEFDF8` |
| Wordmark brown | `#7E573C` |
| Coat | `#FFE9A8` → `#FCD67E` → `#F0BB5A`, outline `#E2AE52` |
| Sprout | leaves `#8FB46F`, stem `#74905B` |
| Book cover | `#82996F`, edge `#64714E`, lip `#A4BA8D` |
| Pages | `#FFFDF7`, edge `#DEC7A4` |
| Bookmark | `#F5C360`, edge `#C99A45` |
| Face | `#3A302B`, cheeks `#FDB38C` at 80% |

## Wordmark

Set in [Fredoka](https://fonts.google.com/specimen/Fredoka) (SIL Open Font
License) at width 80, weight 700, then turned into outlines, so the SVG
needs no font installed.
