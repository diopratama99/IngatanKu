// The opening: an egg that cracks as you scroll, Bolubi popping out of
// it, a book opening under it and the first notes flying in, then the
// headline. Everything is driven by how far the section has scrolled
// (still, at its end, for reduced motion).

import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import type { Strings } from '../i18n/strings';
import { BolubiDefs, Body, BookCover, BookPages, Face, Group, Leaves, Stem } from './Bolubi';

const clamp = (v: number, a = 0, b = 1) => Math.min(b, Math.max(a, v));
/** How far [p] is through [a, b], 0–1. */
const seg = (p: number, a: number, b: number) => clamp((p - a) / (b - a));
const ease = (t: number) => 1 - Math.pow(1 - t, 3);
const back = (t: number) => {
  const c1 = 2.2;
  return 1 + (c1 + 1) * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2);
};
const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

// The scene's window onto the logo grid.
const VB = { x: 230, y: 180, w: 824, h: 720 };

const EGG = 'M642,392 C744,392 806,536 806,640 C806,734 734,786 642,786 C550,786 478,734 478,640 C478,536 540,392 642,392 Z';
const CRACK = [
  [470, 612], [512, 588], [548, 620], [590, 584], [630, 618],
  [668, 582], [708, 616], [748, 586], [790, 610], [816, 598],
];
const crackLine = CRACK.map(([x, y]) => `${x},${y}`).join(' ');
const above = `M440,360 L840,360 L840,${CRACK[CRACK.length - 1][1]} ${CRACK.slice().reverse().map(([x, y]) => `L${x},${y}`).join(' ')} L440,${CRACK[0][1]} Z`;
const below = `M440,820 L840,820 L840,${CRACK[CRACK.length - 1][1]} ${CRACK.slice().reverse().map(([x, y]) => `L${x},${y}`).join(' ')} L440,${CRACK[0][1]} Z`;

function Egg() {
  return (
    <>
      <path d={EGG} fill="url(#ik-shell)" stroke="#E6CD98" strokeWidth="5" />
      <ellipse cx="590" cy="470" rx="24" ry="16" fill="#F2C76E" opacity="0.85" />
      <ellipse cx="712" cy="520" rx="20" ry="14" fill="#F2C76E" opacity="0.85" />
      <ellipse cx="560" cy="690" rx="22" ry="15" fill="#F2C76E" opacity="0.85" />
      <ellipse cx="730" cy="702" rx="17" ry="12" fill="#F2C76E" opacity="0.85" />
      <ellipse cx="575" cy="455" rx="36" ry="20" transform="rotate(-28 575 455)" fill="#FFFFFF" opacity="0.6" />
    </>
  );
}

type Props = { t: Strings['hero']; joinHref: string; demoHref: string };

export default function Hero({ t, joinHref, demoHref }: Props) {
  const section = useRef<HTMLElement>(null);
  const stageRef = useRef<HTMLDivElement>(null);
  const textRef = useRef<HTMLDivElement>(null);
  const [p, setP] = useState(0);
  const [look, setLook] = useState({ x: 0, y: 0 });
  const [box, setBox] = useState({ vh: 800, vw: 1200, stage: 480, text: 260, w: 560 });

  useEffect(() => {
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
      setP(1);
      return;
    }
    let raf = 0;
    const onScroll = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        const el = section.current;
        if (!el) return;
        const total = el.offsetHeight - window.innerHeight;
        setP(clamp(-el.getBoundingClientRect().top / Math.max(total, 1)));
      });
    };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
    return () => {
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', onScroll);
      cancelAnimationFrame(raf);
    };
  }, []);

  // Its eyes follow you.
  useEffect(() => {
    const onMove = (e: PointerEvent) =>
      setLook({
        x: clamp((e.clientX / window.innerWidth) * 2 - 1, -1, 1),
        y: clamp((e.clientY / window.innerHeight) * 2 - 1, -1, 1),
      });
    window.addEventListener('pointermove', onMove, { passive: true });
    return () => window.removeEventListener('pointermove', onMove);
  }, []);

  useLayoutEffect(() => {
    const measure = () =>
      setBox({
        vh: window.innerHeight,
        vw: window.innerWidth,
        stage: stageRef.current?.offsetHeight ?? 480,
        w: stageRef.current?.offsetWidth ?? 560,
        text: textRef.current?.offsetHeight ?? 260,
      });
    measure();
    window.addEventListener('resize', measure);
    return () => window.removeEventListener('resize', measure);
  }, []);

  // ── The timeline ─────────────────────────────────────────────
  const crack = seg(p, 0.05, 0.2);
  const hatch = ease(seg(p, 0.2, 0.32));
  const rise = seg(p, 0.22, 0.38);
  const leaves = back(seg(p, 0.34, 0.46));
  const book = ease(seg(p, 0.42, 0.56));
  const pages = back(seg(p, 0.5, 0.62));
  const settle = ease(seg(p, 0.7, 0.88));
  const words = ease(seg(p, 0.76, 0.94));
  const wobble = hatch < 1 ? Math.sin(p * 90) * (2 + crack * 9) * (1 - hatch) : 0;

  const bolubiScale = rise === 0 ? 0 : lerp(0.25, 1, back(rise));
  const bolubiY = lerp(80, 0, ease(rise));

  // The scene shrinks and moves up to make room for the words (less on
  // a short screen).
  const kEnd = clamp((box.vh - box.text - 60) / box.stage, 0.3, 0.6);
  const k = lerp(1, kEnd, settle);
  const finalTop = Math.max(64, (box.vh - (box.stage * kEnd + 20 + box.text)) / 2);
  const centerNow = lerp(box.vh / 2, finalTop + (box.stage * kEnd) / 2, settle);
  const stageShift = centerNow - box.vh / 2;

  const caption = p < 0.2 ? 0 : p < 0.46 ? 1 : p < 0.7 ? 2 : -1;
  const unit = box.w / 560;

  return (
    <section ref={section} className="hero" id="top" aria-label={t.title}>
      <div className="hero-sticky">
        <div className="hero-glow" style={{ opacity: 0.55 + 0.45 * rise }} />
        <div
          ref={stageRef}
          className="hero-stage"
          style={{ transform: `translate(-50%, -50%) translateY(${stageShift}px) scale(${k})` }}
        >
          <svg viewBox={`${VB.x} ${VB.y} ${VB.w} ${VB.h}`} aria-hidden="true">
            <BolubiDefs />
            <ellipse cx="642" cy="842" rx={lerp(170, 380, book)} ry={lerp(14, 24, book)} fill="#EADFCB" opacity="0.8" />
            {/* Bolubi, out of the egg */}
            <Group t={`translate(0 ${bolubiY}) translate(642 700) scale(${bolubiScale}) translate(-642 -700)`}>
              <Stem />
              <Body />
              <Leaves open={leaves} />
              <Face look={look} />
            </Group>
            {/* The egg: whole, then in two */}
            {hatch < 1 && (
              <Group t={`rotate(${wobble} 642 780)`}>
                <clipPath id="egg-top">
                  <path d={above} />
                </clipPath>
                <clipPath id="egg-bottom">
                  <path d={below} />
                </clipPath>
                <g opacity={1 - hatch} transform={`translate(${-90 * hatch} ${-260 * hatch}) rotate(${-38 * hatch} 642 600)`}>
                  <g clipPath="url(#egg-top)">
                    <Egg />
                  </g>
                </g>
                <g opacity={1 - hatch} transform={`translate(${60 * hatch} ${200 * hatch}) rotate(${18 * hatch} 642 700)`}>
                  <g clipPath="url(#egg-bottom)">
                    <Egg />
                  </g>
                </g>
                <polyline
                  points={crackLine}
                  fill="none"
                  stroke="#C9A46A"
                  strokeWidth="5"
                  strokeLinejoin="round"
                  strokeLinecap="round"
                  pathLength={1}
                  strokeDasharray="1"
                  strokeDashoffset={1 - crack}
                  opacity={1 - hatch}
                />
              </Group>
            )}
            {/* The book it reads */}
            <Group t={`translate(0 ${lerp(300, 0, book)})`}>
              <g opacity={book}>
                <BookCover />
                <BookPages open={pages} />
              </g>
            </Group>
          </svg>

          {/* The first notes, flying into the book */}
          {t.cards.map((label, i) => {
            const show = seg(p, 0.5 + i * 0.03, 0.55 + i * 0.03);
            const fly = ease(seg(p, 0.58 + i * 0.05, 0.74 + i * 0.05));
            const from = [
              [-300, -170],
              [300, -110],
              [-260, 90],
            ][i];
            // Kept on screen on a narrow phone.
            const reach = box.vw / 2 - 96;
            const xPos = clamp(lerp(from[0], 0, fly) * unit, -reach, reach);
            const yPos = lerp(from[1], 150, fly) * unit;
            return (
              <div
                key={label}
                className="hero-card"
                style={{
                  opacity: show * (1 - seg(fly, 0.75, 1)),
                  transform: `translate(-50%, -50%) translate(${xPos}px, ${yPos}px) rotate(${lerp(i % 2 ? 6 : -7, 0, fly)}deg) scale(${lerp(1, 0.3, fly)})`,
                }}
              >
                <span className="hero-card-dot" style={{ background: ['#F5C360', '#8FB46F', '#D9A35B'][i] }} />
                {label}
              </div>
            );
          })}
        </div>

        <p className="hero-caption" aria-hidden="true" style={{ top: `calc(50% + ${box.stage / 2 - 6}px)` }}>
          {t.captions.map((line, i) => (
            <span key={line} className={caption === i ? 'on' : ''}>
              {line}
            </span>
          ))}
        </p>

        <div
          ref={textRef}
          className="hero-words"
          style={{
            top: finalTop + box.stage * kEnd + 20,
            opacity: words,
            transform: `translateY(${lerp(30, 0, words)}px)`,
            pointerEvents: words > 0.5 ? 'auto' : 'none',
          }}
        >
          <span className="hero-kicker">{t.kicker}</span>
          <h1 className="display">{t.title}</h1>
          <p className="lead">{t.sub}</p>
          <div className="hero-ctas">
            <a className="btn btn-primary" href={joinHref}>
              {t.join}
            </a>
            <a className="btn btn-ghost" href={demoHref}>
              <svg width="14" height="14" viewBox="0 0 14 14" aria-hidden="true">
                <path d="M3 1.8v10.4L12 7z" fill="currentColor" />
              </svg>
              {t.watch}
            </a>
          </div>
        </div>

        <div className="hero-scroll" style={{ opacity: 1 - seg(p, 0, 0.06) }} aria-hidden="true">
          <span>{t.scroll}</span>
          <i />
        </div>
      </div>
    </section>
  );
}
