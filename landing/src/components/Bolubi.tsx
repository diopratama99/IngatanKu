// Bolubi as in the logo (assets/brand/bolubi.svg), in parts so the hero
// can move them: the body, its sprout, the face (eyes that follow the
// pointer) and the open book. Drawn on the logo's 1254-unit grid.

import type { CSSProperties, ReactNode } from 'react';

const ink = '#3A302B';

export function BolubiDefs() {
  return (
    <defs>
      <radialGradient id="ik-coat" cx="0.36" cy="0.28" r="0.82">
        <stop offset="0" stopColor="#FFE9A8" />
        <stop offset="0.55" stopColor="#FCD67E" />
        <stop offset="1" stopColor="#F0BB5A" />
      </radialGradient>
      <linearGradient id="ik-arm" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#F8CB6C" />
        <stop offset="1" stopColor="#EDB656" />
      </linearGradient>
      <radialGradient id="ik-shell" cx="0.38" cy="0.3" r="0.85">
        <stop offset="0" stopColor="#FFFFFF" />
        <stop offset="0.55" stopColor="#FAEBCB" />
        <stop offset="1" stopColor="#EED5A2" />
      </radialGradient>
    </defs>
  );
}

/** The sprout's stem (behind the head). */
export const Stem = () => (
  <path d="M621,372 C619,338 609,312 613,287" fill="none" stroke="#74905B" strokeWidth="11" strokeLinecap="round" />
);

/** The two leaves, unfurling by [open] (0–1) from the top of the stem. */
export function Leaves({ open = 1 }: { open?: number }) {
  return (
    <g transform={`translate(613 287) scale(${open}) translate(-613 -287)`}>
      <path d="M612,287 C600,273 580,266 565,270 C556,272 553,279 558,284 C566,292 582,297 596,296 C604,295 609,291 612,287 Z" fill="#8FB46F" />
      <path d="M615,288 C614,270 628,252 650,243 C660,239 670,239 672,244 C674,252 664,266 648,276 C636,284 624,288 615,288 Z" fill="#8FB46F" />
    </g>
  );
}

/** Body, arms, shine and cheeks. */
export const Body = () => (
  <>
    <ellipse cx="389" cy="628" rx="26" ry="35" fill="url(#ik-arm)" stroke="#E2AE52" strokeWidth="5" />
    <ellipse cx="895" cy="628" rx="26" ry="35" fill="url(#ik-arm)" stroke="#E2AE52" strokeWidth="5" />
    <circle cx="642" cy="600" r="250" fill="url(#ik-coat)" stroke="#E2AE52" strokeWidth="6" />
    <ellipse cx="526" cy="443" rx="52" ry="27" transform="rotate(-30 526 443)" fill="#FFFFFF" fillOpacity="0.42" />
    <ellipse cx="517" cy="602" rx="26" ry="14" fill="#FDB38C" fillOpacity="0.8" />
    <ellipse cx="767" cy="586" rx="27" ry="15" fill="#FDB38C" fillOpacity="0.8" />
  </>
);

/** The smug, kind face; pupils shift by [look] (−1…1 each way). */
export function Face({ look = { x: 0, y: 0 } }: { look?: { x: number; y: number } }) {
  const dx = look.x * 7;
  const dy = look.y * 4;
  const blink: CSSProperties = {
    transformBox: 'fill-box',
    transformOrigin: 'center top',
    animation: 'ik-blink 5.2s infinite',
  };
  return (
    <>
      <g fill={ink} stroke={ink} strokeLinecap="round" strokeLinejoin="round">
        <path d="M533,516 L588,517" fill="none" strokeWidth="10" />
        <path d="M680,487 Q706,460 740,472" fill="none" strokeWidth="8" />
        <path d="M535,555 L594,550" fill="none" strokeWidth="10" />
        <path d="M681,546 L746,538" fill="none" strokeWidth="10" />
        <path d="M601,596 C627,595 660,586 686,573 C694,569 699,577 694,584 C680,604 658,622 634,622 C616,622 602,614 596,607 C592,602 594,597 601,596 Z" strokeWidth="1" />
      </g>
      <g style={blink}>
        <g transform={`translate(${dx} ${dy})`}>
          <path d="M545,553 L587,550 C588,574 579,588 566,588 C553,588 545,575 545,553 Z" fill={ink} stroke={ink} strokeWidth="2" strokeLinejoin="round" />
          <path d="M692,544 L737,540 C738,563 729,576 715,576 C701,576 692,564 692,544 Z" fill={ink} stroke={ink} strokeWidth="2" strokeLinejoin="round" />
          <circle cx="571" cy="570" r="5.5" fill="#FFFFFF" />
          <circle cx="721" cy="558" r="6" fill="#FFFFFF" />
        </g>
      </g>
      <path d="M612,605 C636,603 660,596 680,585 C670,602 652,613 635,614 C624,614 616,611 612,605 Z" fill="#FFFFFF" />
      <path d="M631,603 L632,613 M652,598 L653,610" stroke="#C9C0B4" strokeWidth="3" strokeLinecap="round" />
    </>
  );
}

const c = 642;
const x = (d: number) => c + d;

/** The open book's cover and bookmark (under the pages). */
export const BookCover = () => (
  <>
    <path d={`M${x(-372)},742 Q${x(-374)},722 ${x(-354)},724 L${x(-40)},778 Q${c},785 ${x(40)},778 L${x(354)},724 Q${x(374)},722 ${x(372)},742 L${x(342)},822 Q${x(338)},834 ${x(324)},835 L${x(40)},851 Q${c},858 ${x(-40)},851 L${x(-324)},835 Q${x(-338)},834 ${x(-342)},822 Z`} fill="#82996F" stroke="#64714E" strokeWidth="5" strokeLinejoin="round" />
    <path d={`M${x(-354)},739 L${x(-40)},792 Q${c},799 ${x(40)},792 L${x(354)},739`} fill="none" stroke="#A4BA8D" strokeWidth="12" strokeLinecap="round" />
    <path d={`M${x(-40)},802 L${x(-38)},848 M${x(40)},802 L${x(38)},848`} stroke="#6E8459" strokeWidth="4" strokeLinecap="round" />
    <path d={`M${x(150)},752 L${x(216)},748 L${x(218)},834 L${x(184)},812 L${x(152)},836 Z`} fill="#F5C360" stroke="#C99A45" strokeWidth="4" strokeLinejoin="round" />
  </>
);

/** The pages, fanned open by [open] (0–1) from the spine. */
export function BookPages({ open = 1 }: { open?: number }) {
  return (
    <g transform={`translate(${c} 777) scale(1 ${0.12 + 0.88 * open}) translate(${-c} -777)`}>
      <path d={`M${x(-338)},734 L${x(-338)},690 Q${x(-336)},666 ${x(-314)},666 C${x(-220)},668 ${x(-100)},692 ${c},745 C${x(100)},692 ${x(220)},668 ${x(314)},666 Q${x(336)},666 ${x(338)},690 L${x(338)},734 L${x(40)},777 Q${c},783 ${x(-40)},777 Z`} fill="#FFFDF7" stroke="#DEC7A4" strokeWidth="5" strokeLinejoin="round" />
      <path d={`M${x(-332)},713 C${x(-220)},713 ${x(-100)},737 ${c},773 C${x(100)},737 ${x(220)},713 ${x(332)},713`} fill="none" stroke="#EADBC4" strokeWidth="3" strokeLinecap="round" />
      <path d={`M${c},745 L${c},777`} stroke="#DEC7A4" strokeWidth="3" strokeLinecap="round" />
    </g>
  );
}

/** The whole logo mark, still — for small places. */
export function BolubiMark({ className, title }: { className?: string; title?: string }) {
  return (
    <svg viewBox="246 221 792 661" className={className} role={title ? 'img' : undefined} aria-label={title} aria-hidden={title ? undefined : true}>
      <BolubiDefs />
      <ellipse cx="642" cy="842" rx="380" ry="24" fill="#F6ECDA" />
      <Stem />
      <Body />
      <Leaves />
      <Face />
      <BookCover />
      <BookPages />
    </svg>
  );
}

export function Group({ t, children }: { t: string; children: ReactNode }) {
  return <g transform={t}>{children}</g>;
}
