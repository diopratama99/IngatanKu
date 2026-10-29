"""Self-contained procedural sound kit for IngatanKu.

The synthesizers use only Python's standard library so the kit can be reused
without installing a native audio or numerical package. Signals are mono
``array('f')`` buffers at 44.1 kHz; stereo material is represented as a pair
of buffers. All synthesis is original and sample-free.
"""

from __future__ import annotations

import array
import math
import os
import random
import wave
from typing import Sequence

SAMPLE_RATE = 44_100
_TAU = math.tau
_VOWELS = {
    # F1, F2, F3 (Hz), relative spectral weights
    "a": (820, 1_260, 2_800, (1.0, 0.74, 0.37)),
    "e": (530, 1_840, 2_480, (1.0, 0.72, 0.31)),
    "i": (300, 2_250, 3_000, (1.0, 0.8, 0.34)),
    "o": (500, 900, 2_600, (1.0, 0.72, 0.32)),
    "u": (350, 800, 2_200, (1.0, 0.7, 0.28)),
    "m": (300, 1_050, 2_400, (1.0, 0.58, 0.23)),
}


def _n(seconds: float) -> int:
    return max(1, int(round(seconds * SAMPLE_RATE)))


def _smooth_env(i: int, count: int, attack: float = 0.008,
                release: float = 0.025) -> float:
    t = i / max(1, count - 1)
    a = min(1.0, max(0.0, t / max(0.0001, attack)))
    r = min(1.0, max(0.0, (1.0 - t) / max(0.0001, release)))
    return min(1.0, a) * min(1.0, r)


def silence(seconds: float) -> array.array:
    return array.array("f", [0.0]) * _n(seconds)


def fit(signal: Sequence[float], seconds: float) -> array.array:
    count = _n(seconds)
    out = array.array("f", signal[:count])
    if len(out) < count:
        out.extend([0.0] * (count - len(out)))
    return out


def mix(*signals: Sequence[float], gains: Sequence[float] | None = None) -> array.array:
    if not signals:
        return array.array("f")
    count = max(map(len, signals))
    out = array.array("f", [0.0]) * count
    if gains is None:
        gains = [1.0] * len(signals)
    for sig, gain in zip(signals, gains):
        for i, value in enumerate(sig):
            out[i] += value * gain
    return out


def add_at(destination: array.array, signal: Sequence[float], start: float,
           gain: float = 1.0) -> None:
    offset = max(0, int(round(start * SAMPLE_RATE)))
    end = min(len(destination), offset + len(signal))
    for i in range(offset, end):
        destination[i] += signal[i - offset] * gain


def _interp(points: Sequence[float], t: float) -> float:
    if not points:
        return 1.0
    if len(points) == 1:
        return float(points[0])
    p = min(1.0, max(0.0, t)) * (len(points) - 1)
    left = int(p)
    right = min(len(points) - 1, left + 1)
    frac = p - left
    return float(points[left]) * (1.0 - frac) + float(points[right]) * frac


def tone(frequency: float, seconds: float, amplitude: float = 0.35,
         waveform: str = "sine", sweep_to: float | None = None,
         attack: float = 0.008, release: float = 0.035,
         vibrato: float = 0.0, seed: int = 0) -> array.array:
    count = _n(seconds)
    out = array.array("f")
    phase = 0.0
    rng = random.Random(seed)
    for i in range(count):
        t = i / SAMPLE_RATE
        p = i / max(1, count - 1)
        hz = frequency if sweep_to is None else frequency + (sweep_to - frequency) * p
        if vibrato:
            hz *= 1.0 + vibrato * math.sin(_TAU * 5.2 * t)
        phase += _TAU * hz / SAMPLE_RATE
        if waveform == "triangle":
            value = (2.0 / math.pi) * math.asin(math.sin(phase))
        elif waveform == "soft_square":
            value = math.tanh(1.7 * math.sin(phase))
        elif waveform == "noise":
            value = rng.uniform(-1.0, 1.0)
        else:
            value = math.sin(phase)
        env = _smooth_env(i, count, attack, release)
        out.append(value * amplitude * env)
    return out


def _decaying_partials(frequency: float, seconds: float, amplitude: float,
                       partials: Sequence[tuple[float, float]],
                       decay: float = 4.0, seed: int = 0) -> array.array:
    count = _n(seconds)
    out = array.array("f", [0.0]) * count
    phases = [0.0] * len(partials)
    rng = random.Random(seed)
    for i in range(count):
        t = i / SAMPLE_RATE
        value = 0.0
        for j, (ratio, weight) in enumerate(partials):
            phases[j] += _TAU * frequency * ratio / SAMPLE_RATE
            value += math.sin(phases[j]) * weight
        env = (1.0 - math.exp(-t * 150.0)) * math.exp(-decay * t)
        # A very small soft attack transient makes toy instruments feel struck.
        transient = (rng.uniform(-1.0, 1.0) * math.exp(-t * 850.0) * 0.018)
        out[i] = (value + transient) * amplitude * env
    return out


def toy_bell(frequency: float = 880.0, seconds: float = 0.55,
             amplitude: float = 0.32, seed: int = 0) -> array.array:
    return _decaying_partials(frequency, seconds, amplitude,
                              ((1.0, 1.0), (2.01, 0.32), (3.9, 0.11), (6.2, 0.035)),
                              decay=5.0, seed=seed)


def marimba(frequency: float = 440.0, seconds: float = 0.32,
            amplitude: float = 0.34, seed: int = 0) -> array.array:
    return _decaying_partials(frequency, seconds, amplitude,
                              ((1.0, 1.0), (2.76, 0.35), (5.4, 0.08)),
                              decay=8.0, seed=seed)


def music_box(frequency: float = 880.0, seconds: float = 0.7,
              amplitude: float = 0.23, seed: int = 0) -> array.array:
    return _decaying_partials(frequency, seconds, amplitude,
                              ((1.0, 1.0), (2.0, 0.43), (3.01, 0.2), (4.04, 0.07)),
                              decay=3.4, seed=seed)


def noise(seconds: float, amplitude: float = 0.2, color: str = "soft",
          seed: int = 0, loop: bool = False) -> array.array:
    count = _n(seconds)
    rng = random.Random(seed)
    out = array.array("f")
    lp = 0.0
    hp_prev = 0.0
    for i in range(count):
        x = rng.uniform(-1.0, 1.0)
        if color == "soft":
            lp += 0.075 * (x - lp)
            value = lp * 4.7
        elif color == "airy":
            lp += 0.025 * (x - lp)
            value = lp * 8.0
        elif color == "paper":
            lp += 0.42 * (x - lp)
            value = lp * 1.9
        elif color == "high":
            lp += 0.62 * (x - lp)
            value = (lp - hp_prev) * 1.5
            hp_prev = lp
        else:
            value = x
        if not loop:
            value *= _smooth_env(i, count, 0.008, 0.04)
        out.append(value * amplitude)
    if loop and count > 1:
        _crossfade_loop(out, int(0.08 * SAMPLE_RATE))
    return out


def pet_voice(vowel: str = "i", pitch: float = 390.0, length: float = 0.22,
              contour: Sequence[float] = (0.95, 1.08, 0.92),
              breathiness: float = 0.035, amplitude: float = 0.3,
              seed: int = 0) -> array.array:
    vowel = vowel.lower() if vowel.lower() in _VOWELS else "a"
    f1, f2, f3, weights = _VOWELS[vowel]
    count = _n(length)
    out = array.array("f")
    phases = [0.0] * 18
    rng = random.Random(seed)
    for i in range(count):
        t = i / SAMPLE_RATE
        p = i / max(1, count - 1)
        f0 = pitch * _interp(contour, p)
        sample = 0.0
        for h in range(1, len(phases) + 1):
            hz = f0 * h
            phases[h - 1] += _TAU * hz / SAMPLE_RATE
            formant = (weights[0] * math.exp(-((hz - f1) / 210.0) ** 2) +
                       weights[1] * math.exp(-((hz - f2) / 390.0) ** 2) +
                       weights[2] * math.exp(-((hz - f3) / 520.0) ** 2))
            sample += math.sin(phases[h - 1]) * formant / h
        breath = rng.uniform(-1.0, 1.0) * breathiness
        env = _smooth_env(i, count, 0.012, 0.028)
        out.append((sample * 0.8 + breath) * amplitude * env)
    return out


def friend_voice(vowel: str = "i", pitch: float = 510.0, length: float = 0.22,
                contour: Sequence[float] = (1.0, 1.12, 0.96),
                breathiness: float = 0.025, amplitude: float = 0.3,
                seed: int = 0) -> array.array:
    return pet_voice(vowel, pitch, length, contour, breathiness, amplitude, seed)


def squish(seconds: float = 0.24, amplitude: float = 0.42,
           pitch: float = 240.0, seed: int = 0) -> array.array:
    low = tone(pitch, seconds, amplitude * 0.78, sweep_to=pitch * 0.64,
               attack=0.004, release=0.09, seed=seed)
    fizz = noise(seconds, amplitude * 0.12, "soft", seed + 1)
    return mix(low, fizz)


def thud(seconds: float = 0.22, amplitude: float = 0.38,
         pitch: float = 105.0, seed: int = 0) -> array.array:
    low = tone(pitch, seconds, amplitude, sweep_to=pitch * 0.58,
               attack=0.002, release=0.11, seed=seed)
    body = noise(seconds, amplitude * 0.18, "paper", seed + 1)
    return mix(low, body)


def pop(seconds: float = 0.19, amplitude: float = 0.36,
        pitch: float = 510.0, seed: int = 0) -> array.array:
    body = tone(pitch, seconds, amplitude, sweep_to=pitch * 1.55,
                attack=0.002, release=0.065, seed=seed)
    click = noise(min(seconds, 0.035), amplitude * 0.32, "high", seed + 1)
    return mix(body, click)


def paper(seconds: float = 0.35, amplitude: float = 0.28,
          seed: int = 0) -> array.array:
    return noise(seconds, amplitude, "paper", seed)


def wood_tick(seconds: float = 0.12, amplitude: float = 0.28,
              pitch: float = 820.0, seed: int = 0) -> array.array:
    tap = _decaying_partials(pitch, seconds, amplitude,
                             ((1.0, 1.0), (2.7, 0.22)), 28.0, seed)
    return mix(tap, noise(min(seconds, 0.04), amplitude * 0.24, "paper", seed + 1))


def small_metal(seconds: float = 0.18, amplitude: float = 0.26,
                seed: int = 0) -> array.array:
    return toy_bell(1_420.0, seconds, amplitude, seed)


def sparkle(seconds: float = 0.7, amplitude: float = 0.24,
            seed: int = 0) -> array.array:
    rng = random.Random(seed)
    out = array.array("f", [0.0]) * _n(seconds)
    count = max(3, int(seconds * 5.0))
    scale = 1.0 / math.sqrt(count)
    for k in range(count):
        start = 0.025 + k * (seconds - 0.12) / max(1, count - 1)
        hz = rng.choice((880, 988, 1_176, 1_320, 1_568, 1_760))
        add_at(out, toy_bell(hz, min(0.42, seconds - start), amplitude * scale,
                             seed + k * 7), start)
    return out


def room(signal: Sequence[float], amount: float = 0.11,
         loop: bool = False) -> array.array:
    """Add a small warm room using six quiet early reflections."""
    out = array.array("f", signal)
    delays = ((0.027, 0.16), (0.043, 0.1), (0.071, 0.055),
              (0.112, 0.035), (0.181, 0.021), (0.287, 0.012))
    n = len(out)
    for seconds, gain in delays:
        delay = max(1, int(seconds * SAMPLE_RATE))
        for i in range(n):
            source = (i - delay) % n if loop else i - delay
            if source >= 0:
                out[i] += signal[source] * amount * gain
    return out


def _crossfade_loop(signal: array.array, fade_count: int) -> None:
    n = len(signal)
    fade_count = min(fade_count, n // 4)
    if fade_count < 1:
        return
    seam = array.array("f")
    for i in range(fade_count):
        w = i / max(1, fade_count - 1)
        tail = signal[n - fade_count + i]
        head = signal[i]
        seam.append(tail * (1.0 - w) + head * w)
    body = signal[fade_count:n - fade_count]
    # Put the blended tail-to-head seam at the end of the buffer. The file
    # boundary then connects the original samples immediately before and
    # after the removed overlap, which avoids a hard jump when tiled.
    signal[:] = body
    signal.extend(seam)


def export(path: str | os.PathLike[str], signal,
           loop: bool = False, stereo: bool = False,
           reverb: bool = True) -> None:
    """Write peak-normalised, 44.1 kHz, 16-bit PCM WAV.

    Mono is the default. Pass ``stereo=True`` with a pair of buffers for
    background music and ambience. Loop files are left without an end fade
    and receive a circular room reflection.
    """
    if stereo:
        left, right = signal
        channels = [array.array("f", left), array.array("f", right)]
        n = min(map(len, channels))
        channels = [channel[:n] for channel in channels]
        if reverb:
            channels = [room(channel, 0.09, loop) for channel in channels]
    else:
        channels = [array.array("f", signal)]
        n = len(channels[0])
        if reverb:
            channels[0] = room(channels[0], 0.1, loop)
    if not loop and n:
        fade_in = min(int(0.006 * SAMPLE_RATE), n // 4)
        fade_out = min(int(0.012 * SAMPLE_RATE), n // 4)
        for ch in channels:
            for i in range(fade_in):
                ch[i] *= i / max(1, fade_in - 1)
            for i in range(fade_out):
                ch[n - fade_out + i] *= 1.0 - i / max(1, fade_out - 1)
    peak = max((abs(value) for channel in channels for value in channel), default=0.0)
    target = 10.0 ** ((-3.0 if loop else -1.0) / 20.0)
    scale = target / peak if peak else 1.0
    os.makedirs(os.path.dirname(os.fspath(path)) or ".", exist_ok=True)
    with wave.open(os.fspath(path), "wb") as wav:
        wav.setnchannels(2 if stereo else 1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for i in range(n):
            for ch in channels:
                value = max(-1.0, min(1.0, ch[i] * scale))
                frames.extend(int(round(value * 32767)).to_bytes(2, "little", signed=True))
        wav.writeframes(frames)


def _note(midi: int) -> float:
    return 440.0 * (2.0 ** ((midi - 69) / 12.0))

