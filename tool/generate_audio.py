#!/usr/bin/env python3
"""Synthesizes MazeDrop's sound effects and background loop as WAV files.

Everything is generated from simple oscillators, so the assets are
original (no licensing concerns) and reproducible. Water-themed: soft
sine "drips", short bell-like dings, a low ambient pad for music.

Usage: python3 tool/generate_audio.py assets/audio
"""
import math
import random
import struct
import sys
import wave
from pathlib import Path

RATE = 22050


def _clip(x):
    return max(-1.0, min(1.0, x))


def render(duration, fn, gain=0.8, fade_in=0.004, fade_out=0.03):
    n = int(duration * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        s = fn(t) * gain
        if t < fade_in:
            s *= t / fade_in
        if duration - t < fade_out:
            s *= max(0.0, (duration - t) / fade_out)
        out.append(_clip(s))
    return out


def write_wav(path, samples):
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in samples))


def env_exp(t, decay):
    return math.exp(-t * decay)


def sine(f, t):
    return math.sin(2 * math.pi * f * t)


def sweep(f0, f1, t, dur):
    # linear glide from f0 to f1 over dur, phase-correct
    k = (f1 - f0) / dur
    return math.sin(2 * math.pi * (f0 * t + 0.5 * k * t * t))


def noise(rng):
    return rng.uniform(-1, 1)


# --------------------------------------------------------------------------
# SFX
# --------------------------------------------------------------------------

def sfx_move():
    # a tiny water drip: fast downward glide, very short
    return render(0.09, lambda t: sweep(900, 420, t, 0.09) * env_exp(t, 38), gain=0.35)


def sfx_button():
    return render(0.05, lambda t: sweep(1400, 900, t, 0.05) * env_exp(t, 70), gain=0.3)


def sfx_coin():
    def f(t):
        a = sine(1046.5, t) * env_exp(t, 14)          # C6
        b = sine(1568.0, max(0.0, t - 0.06)) * env_exp(max(0.0, t - 0.06), 12) * (1 if t > 0.06 else 0)  # G6
        return 0.6 * a + 0.6 * b
    return render(0.28, f, gain=0.6)


def sfx_key():
    notes = [(0.0, 880.0), (0.07, 1108.7), (0.14, 1318.5)]  # A5 C#6 E6
    def f(t):
        s = 0.0
        for start, freq in notes:
            if t >= start:
                s += sine(freq, t - start) * env_exp(t - start, 11)
        return s * 0.5
    return render(0.4, f, gain=0.6)


def sfx_unlock():
    def f(t):
        thud = sine(110, t) * env_exp(t, 18)
        rise = sweep(300, 900, t, 0.3) * env_exp(max(0.0, t - 0.05), 8) * (1 if t > 0.05 else 0)
        return 0.7 * thud + 0.4 * rise
    return render(0.32, f, gain=0.65)


def sfx_trap():
    rng = random.Random(3)
    def f(t):
        buzz = (1 if sine(140, t) > 0 else -1) * env_exp(t, 9)  # square
        hiss = noise(rng) * env_exp(t, 14)
        return 0.5 * buzz + 0.35 * hiss
    return render(0.24, f, gain=0.55)


def sfx_death():
    rng = random.Random(5)
    def f(t):
        fall = sweep(520, 90, t, 0.5) * env_exp(t, 4)
        splash = noise(rng) * env_exp(t, 10) * (1 if t < 0.15 else 0.3)
        return 0.65 * fall + 0.3 * splash
    return render(0.5, f, gain=0.6)


def sfx_teleport():
    def f(t):
        vib = 1 + 0.02 * sine(28, t)
        up = sweep(400 * vib, 1600, t, 0.16) if t < 0.16 else 0
        down = sweep(1600, 500, t - 0.16, 0.16) if t >= 0.16 else 0
        return (up + down) * env_exp(abs(t - 0.16), 6)
    return render(0.32, f, gain=0.45)


def sfx_level_complete():
    # major arpeggio C5 E5 G5 C6 with a soft sustained chord underneath
    notes = [(0.0, 523.25), (0.11, 659.25), (0.22, 783.99), (0.33, 1046.5)]
    def f(t):
        s = 0.0
        for start, freq in notes:
            if t >= start:
                dt = t - start
                s += sine(freq, dt) * env_exp(dt, 5) * 0.45
        if t > 0.33:
            dt = t - 0.33
            chord = sine(523.25, dt) + sine(659.25, dt) + sine(783.99, dt)
            s += chord * 0.12 * env_exp(dt, 2.5)
        return s
    return render(0.9, f, gain=0.6, fade_out=0.15)


# --------------------------------------------------------------------------
# Music: gentle looping pad, I - vi - IV - V in C major, 2 bars each
# --------------------------------------------------------------------------

def music_loop(bpm=72, bars_per_chord=1):
    chords = [
        (261.63, 329.63, 392.00),   # C
        (220.00, 261.63, 329.63),   # Am
        (174.61, 220.00, 261.63),   # F
        (196.00, 246.94, 293.66),   # G
    ]
    beat = 60 / bpm
    chord_dur = beat * 4 * bars_per_chord
    total = chord_dur * len(chords)

    def f(t):
        idx = int(t // chord_dur) % len(chords)
        local = t - idx * chord_dur
        # crossfade window so chord changes don't click
        env = min(1.0, local / 0.35) * min(1.0, (chord_dur - local) / 0.35)
        s = 0.0
        for freq in chords[idx]:
            # two slightly detuned sines per note = soft pad
            s += sine(freq, t) + 0.6 * sine(freq * 1.003, t)
            s += 0.25 * sine(freq / 2, t)  # sub octave
        # slow tremolo for movement
        s *= 0.85 + 0.15 * sine(0.25, t)
        # sparse "droplet" melody on beats 1 and 3 of each bar
        beat_pos = (t % (beat * 4)) / beat
        for b in (0.0, 2.0):
            if b <= beat_pos < b + 0.8:
                dt = (beat_pos - b) * beat
                top = chords[idx][2] * 2
                s += 0.35 * sine(top, dt) * env_exp(dt, 6)
        return s * env / 9.0

    return render(total, f, gain=0.9, fade_in=0.0, fade_out=0.0)


def main():
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/audio")
    out.mkdir(parents=True, exist_ok=True)
    files = {
        "move.wav": sfx_move(),
        "button_click.wav": sfx_button(),
        "collect_coin.wav": sfx_coin(),
        "collect_key.wav": sfx_key(),
        "unlock_door.wav": sfx_unlock(),
        "trap.wav": sfx_trap(),
        "death.wav": sfx_death(),
        "teleport.wav": sfx_teleport(),
        "level_complete.wav": sfx_level_complete(),
        "background_music.wav": music_loop(),
    }
    for name, samples in files.items():
        write_wav(out / name, samples)
        print(f"{name}: {len(samples) / RATE:.2f}s")


if __name__ == "__main__":
    main()
