// The small moving parts of the page: each one is an island of its own.

import { useEffect, useRef, useState, type FormEvent } from 'react';
import type { Strings } from '../i18n/strings';
import { BETA_SIGNUP_URL, SUPABASE_PUBLISHABLE_KEY } from '../config';

const pet = (name: string) => `/mascot/${name}.webp`;

/** True once [ref] has come on screen (and stays so). */
function useSeen<T extends Element>(ref: React.RefObject<T | null>, margin = '0px 0px -15% 0px') {
  const [seen, setSeen] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(
      ([e]) => {
        if (e.isIntersecting) {
          setSeen(true);
          io.disconnect();
        }
      },
      { rootMargin: margin },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [ref, margin]);
  return seen;
}

/** How far the page has scrolled through [ref] (0 at its top, 1 at its end). */
function useProgress<T extends HTMLElement>(ref: React.RefObject<T | null>) {
  const [p, setP] = useState(0);
  useEffect(() => {
    let raf = 0;
    const on = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        const el = ref.current;
        if (!el) return;
        const total = el.offsetHeight - window.innerHeight;
        setP(Math.min(1, Math.max(0, -el.getBoundingClientRect().top / Math.max(total, 1))));
      });
    };
    on();
    window.addEventListener('scroll', on, { passive: true });
    window.addEventListener('resize', on);
    return () => {
      window.removeEventListener('scroll', on);
      window.removeEventListener('resize', on);
      cancelAnimationFrame(raf);
    };
  }, [ref]);
  return p;
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// ─── Ask: a conversation with Bolubi, playing out ───────────────────

export function ChatDemo({ t }: { t: Strings['ask'] }) {
  const ref = useRef<HTMLDivElement>(null);
  const seen = useSeen(ref);
  const [turn, setTurn] = useState(0);
  const [stage, setStage] = useState<'q' | 'think' | 'a'>('q');

  useEffect(() => {
    if (!seen) return;
    let alive = true;
    (async () => {
      for (let i = 0; alive; i = (i + 1) % t.chat.length) {
        setTurn(i);
        setStage('q');
        await sleep(900);
        if (!alive) return;
        setStage('think');
        await sleep(1300);
        if (!alive) return;
        setStage('a');
        await sleep(5200);
      }
    })();
    return () => {
      alive = false;
    };
  }, [seen, t.chat.length]);

  const c = t.chat[turn];
  return (
    <div ref={ref} className="chat card" aria-live="polite">
      <div className="chat-head">
        <img className="pet" src={pet(stage === 'think' ? 'face-content' : 'face-smirk')} alt="" width="44" height="44" />
        <div>
          <b>Bolubi</b>
          <span>{stage === 'think' ? '…' : t.from}</span>
        </div>
      </div>
      <div className="chat-body" key={turn}>
        <p className="bubble me">{c.q}</p>
        {stage === 'think' && (
          <p className="bubble it typing" aria-label="…">
            <i />
            <i />
            <i />
          </p>
        )}
        {stage === 'a' && (
          <>
            <p className="bubble it">{c.a}</p>
            <span className="chat-source">
              <svg width="14" height="14" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M6 3h9l4 4v14H6z" fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
              </svg>
              {c.source}
            </span>
          </>
        )}
      </div>
    </div>
  );
}

// ─── Quiz: three questions to try, like the app's daily meal ────────

export function QuizDemo({ t }: { t: Strings['quiz']['sample'] }) {
  const [at, setAt] = useState(0);
  const [picked, setPicked] = useState<number | null>(null);
  const [checked, setChecked] = useState(false);
  const [score, setScore] = useState(0);
  const [done, setDone] = useState(false);
  const q = t.questions[at];
  const right = checked && picked === q.right;
  const last = at === t.questions.length - 1;

  function check() {
    setChecked(true);
    if (picked === q.right) setScore((n) => n + 1);
  }

  function next() {
    if (last) {
      setDone(true);
      return;
    }
    setAt(at + 1);
    setPicked(null);
    setChecked(false);
  }

  function again() {
    setAt(0);
    setPicked(null);
    setChecked(false);
    setScore(0);
    setDone(false);
  }

  if (done) {
    const perfect = score === t.questions.length;
    return (
      <div className="quiz card quiz-done" role="status">
        <img className="pet quiz-done-pet" src={pet(perfect ? 'face-happy' : 'face-content')} alt="" />
        <span className="quiz-label">{t.score}</span>
        <p className="quiz-score">
          {score}
          <span> / {t.questions.length}</span>
        </p>
        <p className="quiz-verdict">{perfect ? t.perfect : t.fine}</p>
        <button type="button" className="btn btn-ghost quiz-check" onClick={again}>
          {t.again}
        </button>
      </div>
    );
  }

  const face = !checked ? 'face-hungry' : right ? 'face-happy' : 'face-smirk';
  return (
    <div className="quiz card">
      <div className="quiz-top">
        <span className="quiz-label">{t.label.replace('{n}', String(at + 1))}</span>
        <div className="quiz-steps" aria-hidden="true">
          {t.questions.map((_, i) => (
            <i key={i} className={i < at || (i === at && checked) ? 'done' : i === at ? 'on' : ''} />
          ))}
        </div>
      </div>
      <div className="quiz-ask" key={at}>
        <img key={face} className={`pet quiz-pet${checked ? ' ate' : ''}`} src={pet(face)} alt="" width="84" height="84" />
        <p className="quiz-q">{q.q}</p>
      </div>
      <div className="quiz-options" role="radiogroup" aria-label={q.q}>
        {q.options.map((o, i) => {
          const state = checked ? (i === q.right ? 'right' : i === picked ? 'wrong' : '') : picked === i ? 'picked' : '';
          return (
            <button
              key={`${at}-${o}`}
              type="button"
              role="radio"
              aria-checked={picked === i}
              disabled={checked}
              className={`quiz-option ${state}`}
              onClick={() => setPicked(i)}
            >
              <span>{'ABCD'[i]}</span>
              {o}
            </button>
          );
        })}
      </div>
      {checked && (
        <p className={`quiz-feedback ${right ? 'good' : 'bad'}`} role="status">
          {right ? t.right : t.wrong.replace('{answer}', q.options[q.right])}
        </p>
      )}
      <button
        type="button"
        className="btn btn-primary quiz-check"
        disabled={picked === null}
        onClick={checked ? next : check}
      >
        {!checked ? t.check : last ? t.finish : t.next}
      </button>
    </div>
  );
}

// ─── Grow: egg to sage as you scroll ────────────────────────────────

const STAGES = ['egg', 'baby', 'kid', 'teen', 'adult', 'sage'];
// PetStage.scale in the app: how big each one is next to the adult.
const SCALE = [0.7, 0.6, 0.72, 0.84, 0.94, 1];

export function Grow({ t }: { t: Strings['grow'] }) {
  const ref = useRef<HTMLDivElement>(null);
  const p = useProgress(ref);
  const at = Math.min(STAGES.length - 1, Math.floor(p * STAGES.length * 0.999));
  return (
    <div ref={ref} className="grow-track">
      <div className="grow-sticky">
        <div className="wrap grow-grid">
          <div className="grow-text">
            <span className="eyebrow">{t.eyebrow}</span>
            <h2 className="h2">{t.title}</h2>
            <p className="lead">{t.body}</p>
            <div className="grow-meter" aria-hidden="true">
              <i style={{ width: `${(p * 100).toFixed(1)}%` }} />
            </div>
          </div>
          <div className="grow-stage">
            <div className="grow-floor" />
            {STAGES.map((s, i) => (
              <img
                key={s}
                className={`pet grow-pet${i === at ? ' on' : ''}`}
                src={pet(`stage-${s}`)}
                alt={i === at ? t.stages[i] : ''}
                style={{ height: `${SCALE[i] * 100}%` }}
                loading="lazy"
              />
            ))}
            <span className="grow-name" key={at}>
              {t.stages[at]}
            </span>
          </div>
        </div>
        <ol className="wrap grow-row">
          {STAGES.map((s, i) => (
            <li key={s} className={i <= at ? 'done' : ''}>
              <img className="pet" src={pet(`stage-${s}`)} alt="" loading="lazy" style={{ height: `${SCALE[i] * 56}px` }} />
              <span>{t.stages[i]}</span>
            </li>
          ))}
        </ol>
      </div>
    </div>
  );
}

// ─── Wardrobe: try things on ────────────────────────────────────────

const WARDROBE: string[][] = [
  ['color-honey', 'color-matcha', 'color-peach', 'color-sky', 'color-taro', 'color-mocha', 'color-mochi'],
  ['acc-sprout', 'acc-bow', 'acc-glasses', 'acc-scarf', 'acc-beanie', 'acc-headphones', 'acc-crown', 'acc-chefHat', 'acc-partyHat', 'acc-catEars', 'acc-flower', 'acc-peci'],
  ['outfit-frog', 'outfit-dino', 'outfit-bee', 'outfit-astronaut', 'outfit-hoodie', 'outfit-stripedTee', 'outfit-overalls', 'outfit-sweater', 'outfit-batik', 'outfit-raincoat', 'outfit-koko', 'outfit-pumpkin'],
];

export function Wardrobe({ t }: { t: Strings['wardrobe'] }) {
  const [tab, setTab] = useState(0);
  const [pick, setPick] = useState(0);
  const [touched, setTouched] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const seen = useSeen(ref);

  // Tries things on by itself until you do.
  useEffect(() => {
    if (!seen || touched) return;
    const id = setInterval(() => {
      setPick((i) => {
        const next = i + 1;
        if (next >= WARDROBE[tab].length) {
          setTab((x) => (x + 1) % WARDROBE.length);
          return 0;
        }
        return next;
      });
    }, 1700);
    return () => clearInterval(id);
  }, [seen, touched, tab]);

  const items = WARDROBE[tab];
  const current = items[Math.min(pick, items.length - 1)];
  return (
    <div ref={ref} className="wardrobe card">
      <div className="wardrobe-mirror">
        <img key={current} className="pet wardrobe-pet" src={pet(current)} alt="" />
        <div className="wardrobe-floor" />
      </div>
      <div className="wardrobe-side">
        <div className="tabs" role="tablist">
          {t.tabs.map((label, i) => (
            <button
              key={label}
              type="button"
              role="tab"
              aria-selected={tab === i}
              className={tab === i ? 'on' : ''}
              onClick={() => {
                setTouched(true);
                setTab(i);
                setPick(0);
              }}
            >
              {label}
            </button>
          ))}
        </div>
        <div className="wardrobe-grid" role="tabpanel">
          {items.map((name, i) => (
            <button
              key={name}
              type="button"
              className={`wardrobe-item${name === current ? ' on' : ''}`}
              onClick={() => {
                setTouched(true);
                setPick(i);
              }}
              aria-pressed={name === current}
              aria-label={name.replace(/^(color|acc|outfit)-/, '')}
            >
              <img className="pet" src={pet(name)} alt="" loading="lazy" />
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── Widget: a day on the home screen ───────────────────────────────

export function WidgetDemo({ t }: { t: Strings['widget'] }) {
  const [at, setAt] = useState(0);
  const [touched, setTouched] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const seen = useSeen(ref);
  useEffect(() => {
    if (!seen || touched) return;
    const id = setInterval(() => setAt((i) => (i + 1) % t.states.length), 3200);
    return () => clearInterval(id);
  }, [seen, touched, t.states.length]);
  const s = t.states[at];
  const clock = ['08:00', '19:30', '20:15'][at];
  return (
    <div ref={ref} className="widget-demo">
      <div className="seg" role="tablist">
        {t.times.map((label, i) => (
          <button
            key={label}
            type="button"
            role="tab"
            aria-selected={at === i}
            className={at === i ? 'on' : ''}
            onClick={() => {
              setTouched(true);
              setAt(i);
            }}
          >
            {label}
          </button>
        ))}
      </div>
      <div className="phone home-phone">
        <div className="phone-screen home-screen">
          <div className="home-clock">{clock}</div>
          <div className="home-widget" key={at}>
            <img className="pet" src={pet(`face-${s.face}`)} alt="" />
            <div>
              <b>{s.title}</b>
              <p>{s.body}</p>
              <div className="home-widget-row">
                <span className="home-widget-cta">{s.cta}</span>
                {at !== 1 && <span className="home-widget-streak">{t.streak}</span>}
              </div>
            </div>
          </div>
          <div className="home-apps" aria-hidden="true">
            {Array.from({ length: 12 }, (_, i) => (
              <i key={i} />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Trailer: the one-minute film, with sound ───────────────────────

/** [lang]'s trailer behind a big play button. The hero's "Watch it work"
 * link starts it too, since its click lets the page play sound. */
export function TrailerPlayer({ t, lang }: { t: Strings['trailer']; lang: string }) {
  const video = useRef<HTMLVideoElement>(null);
  const [playing, setPlaying] = useState(false);

  const play = () => {
    const v = video.current;
    if (!v) return;
    setPlaying(true);
    v.play().catch(() => {
      // No sound allowed yet: start muted, the controls can unmute.
      v.muted = true;
      v.play().catch(() => setPlaying(false));
    });
  };

  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if ((e.target as Element | null)?.closest('a[href="#trailer"]')) play();
    };
    document.addEventListener('click', onClick);
    return () => document.removeEventListener('click', onClick);
  }, []);

  return (
    <div className={playing ? 'trailer playing' : 'trailer'}>
      <video
        ref={video}
        src={`/video/trailer-${lang}.mp4`}
        poster={`/video/trailer-${lang}.jpg`}
        preload="none"
        playsInline
        controls={playing}
        onEnded={() => setPlaying(false)}
        aria-label={t.title}
      />
      {!playing && (
        <button type="button" className="trailer-play" onClick={play}>
          <span className="trailer-btn" aria-hidden="true">
            <svg viewBox="0 0 14 14">
              <path d="M3 1.8v10.4L12 7z" fill="currentColor" />
            </svg>
          </span>
          <span className="trailer-label">
            {t.play} · {t.length}
          </span>
        </button>
      )}
    </div>
  );
}

// ─── Demo: clips recorded from the app ──────────────────────────────

/** [lang]'s clips: recorded with the app in that language. */
export function DemoTour({ t, lang }: { t: Strings['demo']; lang: string }) {
  const [at, setAt] = useState(0);
  const video = useRef<HTMLVideoElement>(null);
  const ref = useRef<HTMLDivElement>(null);
  const seen = useSeen(ref, '200px 0px');
  const tab = t.tabs[at];

  useEffect(() => {
    const v = video.current;
    if (!v || !seen) return;
    v.load();
    v.play().catch(() => {});
  }, [at, seen]);

  return (
    <div ref={ref} className="tour">
      <div className="tour-tabs" role="tablist">
        {t.tabs.map((x, i) => (
          <button
            key={x.id}
            type="button"
            role="tab"
            aria-selected={at === i}
            className={at === i ? 'on' : ''}
            onClick={() => setAt(i)}
          >
            {x.label}
          </button>
        ))}
      </div>
      <div className="tour-phone">
        <div className="phone">
          <div className="phone-screen">
            <video
              ref={video}
              key={tab.id}
              src={seen ? `/video/${lang}/${tab.id}.mp4` : undefined}
              muted
              loop
              playsInline
              autoPlay
              preload="none"
              aria-label={tab.title}
            />
          </div>
        </div>
      </div>
      <div className="tour-text" key={tab.id}>
        <h3>{tab.title}</h3>
        <p>{tab.body}</p>
        <div className="tour-nav">
          <button type="button" className="btn btn-ghost" onClick={() => setAt((at + t.tabs.length - 1) % t.tabs.length)} aria-label="Previous">
            ←
          </button>
          <button type="button" className="btn btn-ghost" onClick={() => setAt((at + 1) % t.tabs.length)} aria-label="Next">
            →
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Beta: the sign-up ──────────────────────────────────────────────

export function BetaForm({ t, lang }: { t: Strings['beta']; lang: string }) {
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [trap, setTrap] = useState('');
  const [state, setState] = useState<'idle' | 'sending' | 'done' | 'failed' | 'invalid'>('idle');

  async function submit(e: FormEvent) {
    e.preventDefault();
    const clean = email.trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(clean)) {
      setState('invalid');
      return;
    }
    setState('sending');
    try {
      const res = await fetch(BETA_SIGNUP_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', apikey: SUPABASE_PUBLISHABLE_KEY },
        body: JSON.stringify({ email: clean, name: name.trim(), locale: lang, website: trap }),
      });
      if (!res.ok) throw new Error(String(res.status));
      setState('done');
    } catch {
      setState('failed');
    }
  }

  if (state === 'done') {
    return (
      <div className="beta-done" role="status">
        <img className="pet beta-done-pet" src={pet('stage-baby')} alt="" />
        <h3>{t.doneTitle}</h3>
        <p>{t.doneBody}</p>
        <div className="confetti" aria-hidden="true">
          {Array.from({ length: 18 }, (_, i) => (
            <i key={i} style={{ ['--i' as string]: i }} />
          ))}
        </div>
      </div>
    );
  }

  return (
    <form className="beta-form" onSubmit={submit} noValidate>
      <label>
        <span>{t.email}</span>
        <input
          type="email"
          inputMode="email"
          autoComplete="email"
          placeholder={t.emailHint}
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            if (state === 'invalid' || state === 'failed') setState('idle');
          }}
          aria-invalid={state === 'invalid'}
          required
        />
      </label>
      <label>
        <span>{t.name}</span>
        <input type="text" autoComplete="given-name" placeholder={t.nameHint} value={name} maxLength={60} onChange={(e) => setName(e.target.value)} />
      </label>
      {/* For bots only. */}
      <label className="sr-only" aria-hidden="true">
        Website
        <input tabIndex={-1} autoComplete="off" value={trap} onChange={(e) => setTrap(e.target.value)} />
      </label>
      <button className="btn btn-primary" type="submit" disabled={state === 'sending'}>
        {state === 'sending' ? t.sending : t.submit}
      </button>
      <p className={`beta-msg${state === 'invalid' || state === 'failed' ? ' bad' : ''}`} role="alert">
        {state === 'invalid' ? t.invalid : state === 'failed' ? t.failed : t.note}
      </p>
    </form>
  );
}

// ─── The helper: Bolubi in the corner, with a word for each section ─

const FACES: Record<string, string> = {
  hero: 'face-smirk',
  save: 'face-happy',
  ask: 'face-content',
  quiz: 'face-hungry',
  grow: 'stage-baby',
  wardrobe: 'outfit-frog',
  widget: 'face-sad',
  demo: 'face-smirk',
  features: 'face-happy',
  beta: 'face-happy',
  faq: 'face-content',
};

export function Helper({ t }: { t: Strings['helper'] }) {
  const [where, setWhere] = useState('hero');
  const [hidden, setHidden] = useState(false);
  const [talk, setTalk] = useState(true);

  useEffect(() => {
    try {
      if (sessionStorage.getItem('helper.hidden') === '1') setHidden(true);
    } catch {
      /* private mode */
    }
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) setWhere((e.target as HTMLElement).dataset.helper ?? 'hero');
        }
      },
      { rootMargin: '-45% 0px -45% 0px' },
    );
    document.querySelectorAll('[data-helper]').forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);

  // Says its line, then goes quiet after a while.
  useEffect(() => {
    setTalk(true);
    const id = setTimeout(() => setTalk(false), window.innerWidth < 600 ? 2800 : 4200);
    return () => clearTimeout(id);
  }, [where]);

  if (hidden) return null;
  const line = (t as Record<string, string>)[where];
  return (
    <div className="helper" aria-live="polite">
      {talk && line && (
        <p className="helper-bubble" key={where}>
          {line}
        </p>
      )}
      <button type="button" className="helper-pet" onClick={() => setTalk((v) => !v)} aria-label="Bolubi">
        <img className="pet" key={where} src={pet(FACES[where] ?? 'face-happy')} alt="" />
      </button>
      <button
        type="button"
        className="helper-x"
        aria-label={t.hide}
        onClick={() => {
          setHidden(true);
          try {
            sessionStorage.setItem('helper.hidden', '1');
          } catch {
            /* private mode */
          }
        }}
      >
        ×
      </button>
    </div>
  );
}
