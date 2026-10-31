import os
import math
import struct
import wave
import numpy as np

SAMPLE_RATE = 44100

def write_wav(filepath: str, audio: np.ndarray, sample_rate: int = SAMPLE_RATE):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    # Normalize to prevent clipping, leaving 1.5 dB headroom
    max_val = np.max(np.abs(audio))
    if max_val > 1e-6:
        audio = (audio / max_val) * 0.85
    else:
        audio = np.zeros_like(audio)
    int_samples = (audio * 32767).astype(np.int16)
    with wave.open(filepath, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(int_samples.tobytes())
    print(f"Generated: {filepath} ({len(audio)/sample_rate:.2f}s)")

# -------------------------------------------------------------
# Sound Synthesizers for SFX
# -------------------------------------------------------------

def gen_jump():
    dur = 0.12
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    freq = np.linspace(160, 390, len(t))
    phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
    env = np.exp(-t * 18.0) * np.sin(np.pi * t / dur)
    # Sine + slight second harmonic
    signal = np.sin(phase) + 0.3 * np.sin(2 * phase)
    return signal * env

def gen_double_jump():
    dur = 0.20
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    freq = np.linspace(260, 680, len(t))
    phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
    env = np.exp(-t * 12.0)
    # Shimmering turquoise nature wind with slight frequency wobble
    wobble = 1.0 + 0.15 * np.sin(2 * np.pi * 32 * t)
    noise = np.random.uniform(-0.15, 0.15, len(t)) * np.exp(-t * 18.0)
    signal = (np.sin(phase * wobble) + 0.4 * np.sin(phase * 2) + noise) * env
    return signal

def gen_land():
    dur = 0.14
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    freq = np.linspace(110, 42, len(t))
    phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
    env = np.exp(-t * 26.0)
    noise = np.random.uniform(-0.35, 0.35, len(t)) * np.exp(-t * 35.0)
    return (np.sin(phase) * 0.8 + noise) * env

def gen_slash():
    dur = 0.14
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    noise = np.random.uniform(-1.0, 1.0, len(t))
    # Bandpass / low-pass filter by moving average
    kernel = np.ones(5) / 5.0
    smooth_noise = np.convolve(noise, kernel, mode='same')
    pitch_env = np.sin(2 * np.pi * np.linspace(650, 180, len(t)) * t)
    env = np.sin(np.pi * np.clip(t / dur, 0, 1))**1.5 * np.exp(-t * 12.0)
    return (smooth_noise * 0.7 + pitch_env * 0.4) * env

def gen_heavy_slash():
    dur = 0.28
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    bass = np.sin(2 * np.pi * np.linspace(180, 50, len(t)) * t) * np.exp(-t * 10.0)
    crystal = np.sin(2 * np.pi * 880 * t) * np.exp(-t * 16.0) * 0.35
    noise = np.random.uniform(-0.6, 0.6, len(t)) * np.exp(-t * 15.0)
    return bass * 0.7 + crystal + noise * 0.4

def gen_bow_shoot():
    dur = 0.16
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    # Bowstring pluck snap
    snap = np.sin(2 * np.pi * np.linspace(950, 220, len(t)) * t) * np.exp(-t * 40.0)
    # Whistling air flutter
    whistle = np.sin(2 * np.pi * np.linspace(350, 550, len(t)) * t) * np.exp(-t * 12.0) * 0.4
    return snap * 0.8 + whistle

def gen_arrow_hit():
    dur = 0.12
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    click = np.random.uniform(-0.8, 0.8, len(t)) * np.exp(-t * 60.0)
    twang = np.sin(2 * np.pi * 520 * t) * np.exp(-t * 28.0) * 0.5
    return click + twang

def gen_slide():
    dur = 0.25
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    noise = np.random.uniform(-0.5, 0.5, len(t))
    kernel = np.ones(8) / 8.0
    whoosh = np.convolve(noise, kernel, mode='same')
    env = np.sin(np.pi * t / dur) * np.exp(-t * 3.5)
    whistle = np.sin(2 * np.pi * 320 * t) * 0.15 * env
    return (whoosh + whistle) * env

def gen_grapple_shoot():
    dur = 0.22
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    # Chain rattle
    rattle = np.sin(2 * np.pi * 780 * t) * (np.sin(2 * np.pi * 45 * t) > 0) * np.exp(-t * 12.0)
    whoosh = np.random.uniform(-0.3, 0.3, len(t)) * np.exp(-t * 10.0)
    return rattle * 0.6 + whoosh * 0.4

def gen_grapple_latch():
    dur = 0.24
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    # Bronze metallic ping harmonics: 1100Hz, 1760Hz, 2420Hz
    ping = (np.sin(2 * np.pi * 1100 * t) * 0.6 +
            np.sin(2 * np.pi * 1760 * t) * 0.4 +
            np.sin(2 * np.pi * 2420 * t) * 0.2) * np.exp(-t * 14.0)
    click = np.random.uniform(-0.5, 0.5, len(t)) * np.exp(-t * 60.0)
    return ping + click

def gen_player_hurt():
    dur = 0.22
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    grunt = np.sin(2 * np.pi * np.linspace(190, 85, len(t)) * t) * np.exp(-t * 12.0)
    crunch = np.random.uniform(-0.5, 0.5, len(t)) * np.exp(-t * 22.0)
    return grunt * 0.7 + crunch * 0.5

def gen_player_die():
    dur = 1.2
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    tone1 = np.sin(2 * np.pi * 220 * t) * np.exp(-t * 2.5)
    tone2 = np.sin(2 * np.pi * 164.8 * t) * np.exp(-t * 2.2) # Minor second / modal drop
    shimmer = np.sin(2 * np.pi * 880 * t) * 0.25 * np.exp(-t * 3.5)
    noise = np.random.uniform(-0.15, 0.15, len(t)) * np.exp(-t * 1.8)
    return tone1 * 0.5 + tone2 * 0.5 + shimmer + noise

def gen_enemy_hit():
    dur = 0.15
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    crunch = np.random.uniform(-0.7, 0.7, len(t)) * np.exp(-t * 25.0)
    low_pop = np.sin(2 * np.pi * np.linspace(240, 70, len(t)) * t) * np.exp(-t * 22.0)
    return crunch * 0.6 + low_pop * 0.5

def gen_enemy_die():
    dur = 0.42
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    rumble = np.sin(2 * np.pi * np.linspace(140, 40, len(t)) * t) * np.exp(-t * 6.0)
    spectral = np.sin(2 * np.pi * np.linspace(440, 180, len(t)) * t) * 0.3 * np.exp(-t * 7.0)
    noise = np.random.uniform(-0.4, 0.4, len(t)) * np.exp(-t * 10.0)
    return rumble * 0.6 + spectral + noise * 0.3

def gen_wolf_bite():
    dur = 0.18
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    snap = np.sin(2 * np.pi * np.linspace(480, 110, len(t)) * t) * np.exp(-t * 24.0)
    noise = np.random.uniform(-0.6, 0.6, len(t)) * np.exp(-t * 30.0)
    return snap * 0.6 + noise * 0.5

def gen_shield_block():
    dur = 0.32
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    # Heavy bronze clang
    clang = (np.sin(2 * np.pi * 840 * t) * 0.7 +
             np.sin(2 * np.pi * 1280 * t) * 0.4 +
             np.sin(2 * np.pi * 2150 * t) * 0.25) * np.exp(-t * 10.0)
    crack = np.random.uniform(-0.6, 0.6, len(t)) * np.exp(-t * 45.0)
    return clang + crack * 0.5

def gen_boss_slam():
    dur = 0.75
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    sub = np.sin(2 * np.pi * np.linspace(85, 28, len(t)) * t) * np.exp(-t * 3.5)
    rock = np.random.uniform(-0.6, 0.6, len(t)) * np.exp(-t * 7.0)
    crack = np.random.uniform(-0.9, 0.9, len(t)) * np.exp(-t * 30.0)
    return sub * 0.8 + rock * 0.4 + crack * 0.5

def gen_stalactite_fall():
    dur = 0.45
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    snap = np.random.uniform(-0.7, 0.7, len(t)) * np.exp(-t * 35.0)
    descend = np.sin(2 * np.pi * np.linspace(450, 120, len(t)) * t) * np.exp(-t * 6.0) * 0.4
    return snap + descend

def gen_pickup_scrap():
    dur = 0.25
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    # Bright high double-chime (D6 -> A6)
    t1 = t[t < 0.10]
    t2 = t[t >= 0.10] - 0.10
    tone1 = np.sin(2 * np.pi * 1174.66 * t1) * np.exp(-t1 * 18.0)
    tone2 = np.sin(2 * np.pi * 1760.0 * t2) * np.exp(-t2 * 14.0)
    sig = np.concatenate([tone1, tone2])
    return sig

def gen_pomegranate_pickup():
    dur = 0.65
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    # Sacred Persian flourish: D5 -> F#5 -> A5 -> D6
    chord = (np.sin(2 * np.pi * 587.33 * t) * 0.4 +
             np.sin(2 * np.pi * 739.99 * t) * 0.35 +
             np.sin(2 * np.pi * 880.00 * t) * 0.3 +
             np.sin(2 * np.pi * 1174.66 * t) * 0.25) * np.exp(-t * 4.5)
    return chord

def gen_keystone_unlock():
    dur = 0.85
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    # Ancient mechanism turning
    grind = np.random.uniform(-0.35, 0.35, len(t)) * (np.sin(2 * np.pi * 20 * t) > 0) * np.exp(-t * 3.0)
    chime = (np.sin(2 * np.pi * 440 * t) + np.sin(2 * np.pi * 659.25 * t)) * 0.35 * np.exp(-t * 2.8)
    return grind * 0.6 + chime * 0.6

def gen_beacon_ignite():
    dur = 1.4
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    whoosh = np.random.uniform(-0.5, 0.5, len(t)) * np.sin(np.pi * t / dur) * np.exp(-t * 1.5)
    swell = (np.sin(2 * np.pi * 293.66 * t) * 0.4 +
             np.sin(2 * np.pi * 440.0 * t) * 0.3 +
             np.sin(2 * np.pi * 587.33 * t) * 0.25) * np.sin(np.pi * np.clip(t / 0.8, 0, 1)) * np.exp(-t * 1.2)
    return whoosh * 0.6 + swell * 0.6

def gen_anvil_hammer():
    dur = 0.38
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    strike = (np.sin(2 * np.pi * 1320 * t) * 0.6 +
              np.sin(2 * np.pi * 2640 * t) * 0.3 +
              np.sin(2 * np.pi * 3960 * t) * 0.15) * np.exp(-t * 11.0)
    spark = np.random.uniform(-0.3, 0.3, len(t)) * np.exp(-t * 20.0)
    low_iron = np.sin(2 * np.pi * 330 * t) * 0.4 * np.exp(-t * 8.0)
    return strike + spark + low_iron

def gen_ui_click():
    dur = 0.05
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    click = np.sin(2 * np.pi * np.linspace(800, 200, len(t)) * t) * np.exp(-t * 70.0)
    return click

def gen_ui_select():
    dur = 0.28
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    tone1 = np.sin(2 * np.pi * 587.33 * t) * 0.5 * np.exp(-t * 9.0) # D5
    tone2 = np.sin(2 * np.pi * 880.0 * t) * 0.4 * np.exp(-t * 8.0)  # A5
    return tone1 + tone2

# -------------------------------------------------------------
# Persian Metroidvania Looping Music Synthesizer
# -------------------------------------------------------------

def note_freq(note_name: str) -> float:
    # Persian modal reference notes (A4 = 440 Hz)
    notes = {
        'D2': 73.42, 'A2': 110.00, 'C3': 130.81, 'D3': 146.83,
        'Eb3': 155.56, 'F3': 174.61, 'G3': 196.00, 'A3': 220.00,
        'Bb3': 246.94, 'C4': 261.63, 'D4': 293.66, 'Eb4': 311.13,
        'E4': 329.63, 'F4': 349.23, 'G4': 392.00, 'A4': 440.00,
        'Bb4': 466.16, 'C5': 523.25, 'D5': 587.33, 'E5': 659.25,
        'F5': 698.46, 'A5': 880.00
    }
    return notes.get(note_name, 220.0)

def pluck_string(freq: float, duration: float, sample_rate: int = SAMPLE_RATE) -> np.ndarray:
    t = np.linspace(0, duration, int(sample_rate * duration), False)
    # Plucked string model: fundamental + rich decaying harmonics (Santur/Tar)
    env = np.exp(-t * (4.5 + freq * 0.006))
    signal = (np.sin(2 * np.pi * freq * t) * 0.6 +
              np.sin(2 * np.pi * freq * 2 * t) * 0.35 +
              np.sin(2 * np.pi * freq * 3 * t) * 0.2 +
              np.sin(2 * np.pi * freq * 4 * t) * 0.1) * env
    # Metallic string transient at start
    transient = np.random.uniform(-0.25, 0.25, len(t)) * np.exp(-t * 60.0)
    return signal + transient

def drum_tombak(pattern_type: str, duration: float = 0.28, sample_rate: int = SAMPLE_RATE) -> np.ndarray:
    t = np.linspace(0, duration, int(sample_rate * duration), False)
    if pattern_type == "tom":
        # Deep bass strike (Tom)
        pitch = np.linspace(110, 48, len(t))
        phase = 2 * np.pi * np.cumsum(pitch) / sample_rate
        env = np.exp(-t * 12.0)
        return np.sin(phase) * env * 0.9
    elif pattern_type == "bak":
        # Sharp rim/edge slap (Bak)
        pitch = np.linspace(340, 160, len(t))
        phase = 2 * np.pi * np.cumsum(pitch) / sample_rate
        env = np.exp(-t * 28.0)
        noise = np.random.uniform(-0.4, 0.4, len(t)) * np.exp(-t * 35.0)
        return (np.sin(phase) * 0.5 + noise) * env
    else: # soft tap
        noise = np.random.uniform(-0.2, 0.2, len(t)) * np.exp(-t * 40.0)
        return noise * 0.5

def synth_music_menu() -> np.ndarray:
    # 16-second seamless atmospheric menu loop (Dastgah Shur / Isfahan)
    duration = 16.0
    num_samples = int(SAMPLE_RATE * duration)
    buffer = np.zeros(num_samples)
    t_full = np.linspace(0, duration, num_samples, False)

    # 1. Warm mystical drone (D2 + A2 + D3)
    drone = (np.sin(2 * np.pi * note_freq('D2') * t_full) * 0.25 +
             np.sin(2 * np.pi * note_freq('A2') * t_full) * 0.18 +
             np.sin(2 * np.pi * note_freq('D3') * t_full) * 0.12)
    # Slow breathing low-frequency filter modulation
    lfo = 0.8 + 0.2 * np.sin(2 * np.pi * 0.125 * t_full)
    buffer += drone * lfo

    # 2. Santur modal melody phrase (D - F - G - A - Bb - A - G - F - E - D)
    melody = [
        (0.5, 'D4', 1.8), (2.0, 'F4', 1.5), (3.5, 'G4', 1.2), (4.5, 'A4', 2.2),
        (6.5, 'Bb4', 1.5), (8.0, 'A4', 1.8), (9.8, 'G4', 1.5), (11.0, 'F4', 1.5),
        (12.5, 'E4', 1.2), (13.5, 'D4', 2.2)
    ]
    for start_t, note, note_dur in melody:
        start_idx = int(start_t * SAMPLE_RATE)
        sound = pluck_string(note_freq(note), note_dur)
        end_idx = min(start_idx + len(sound), num_samples)
        buffer[start_idx:end_idx] += sound[:end_idx - start_idx] * 0.45

    # 3. Soft crystalline bell chime at peak
    bell_t = np.linspace(0, 3.5, int(SAMPLE_RATE * 3.5), False)
    bell = (np.sin(2 * np.pi * 1174.66 * bell_t) * 0.15 + np.sin(2 * np.pi * 1760.0 * bell_t) * 0.08) * np.exp(-bell_t * 1.5)
    b_idx = int(5.0 * SAMPLE_RATE)
    buffer[b_idx:b_idx + len(bell)] += bell

    return buffer

def synth_music_forge() -> np.ndarray:
    # 24-second seamless rhythmic Metroidvania exploration loop
    duration = 24.0
    num_samples = int(SAMPLE_RATE * duration)
    buffer = np.zeros(num_samples)
    t_full = np.linspace(0, duration, num_samples, False)

    # 1. Dark subterranean pulse & pad
    drone = (np.sin(2 * np.pi * note_freq('D2') * t_full) * 0.3 +
             np.sin(2 * np.pi * (note_freq('D2') * 1.002) * t_full) * 0.2 + # Detuned chorusing
             np.sin(2 * np.pi * note_freq('A2') * t_full) * 0.18)
    buffer += drone

    # 2. Driving Persian frame drum rhythm (6/8 rhythm pattern every 1.5s: 16 measures)
    beat_step = 0.25 # 6 eighth-notes = 1.5s measure
    for m in range(16):
        m_t = m * 1.5
        # Beat 1: heavy Tom
        s_tom = drum_tombak("tom", 0.35)
        idx = int(m_t * SAMPLE_RATE)
        buffer[idx:idx + len(s_tom)] += s_tom * 0.55
        # Beat 3: soft tap
        s_tap = drum_tombak("tap", 0.15)
        idx3 = int((m_t + 0.5) * SAMPLE_RATE)
        if idx3 + len(s_tap) < num_samples:
            buffer[idx3:idx3 + len(s_tap)] += s_tap * 0.3
        # Beat 4: Bak rim slap
        s_bak = drum_tombak("bak", 0.22)
        idx4 = int((m_t + 0.75) * SAMPLE_RATE)
        if idx4 + len(s_bak) < num_samples:
            buffer[idx4:idx4 + len(s_bak)] += s_bak * 0.45
        # Beat 6: Bak syncopation
        idx6 = int((m_t + 1.25) * SAMPLE_RATE)
        if idx6 + len(s_bak) < num_samples:
            buffer[idx6:idx6 + len(s_bak)] += s_bak * 0.35

    # 3. Ostinato Tar bass riff (D3 - D3 - F3 - G3 - A3 - F3)
    riff = [
        (0.0, 'D3'), (0.75, 'D3'), (1.5, 'F3'), (2.25, 'G3'),
        (3.0, 'A3'), (3.75, 'F3'), (4.5, 'G3'), (5.25, 'E4')
    ]
    for rep in range(4):
        offset = rep * 6.0
        for start_t, note in riff:
            actual_t = offset + start_t
            if actual_t + 0.6 < duration:
                idx = int(actual_t * SAMPLE_RATE)
                s = pluck_string(note_freq(note), 0.55)
                end = min(idx + len(s), num_samples)
                buffer[idx:end] += s[:end - idx] * 0.4

    # 4. Melodic lead (Santur solo on Mount Espinas) starting at measure 4
    solo = [
        (6.0, 'A4', 1.2), (7.25, 'Bb4', 0.8), (8.0, 'A4', 0.8), (8.75, 'G4', 1.0),
        (10.0, 'F4', 1.2), (11.25, 'G4', 0.8), (12.0, 'A4', 2.0),
        (14.5, 'C5', 1.2), (15.75, 'Bb4', 0.8), (16.5, 'A4', 1.0), (17.5, 'G4', 1.5),
        (19.0, 'F4', 1.0), (20.0, 'E4', 1.2), (21.5, 'D4', 2.2)
    ]
    for start_t, note, dur in solo:
        idx = int(start_t * SAMPLE_RATE)
        s = pluck_string(note_freq(note), dur)
        end = min(idx + len(s), num_samples)
        buffer[idx:end] += s[:end - idx] * 0.45

    return buffer

def synth_music_boss() -> np.ndarray:
    # 20-second intense combat loop for Crusher of the Ruins
    duration = 20.0
    num_samples = int(SAMPLE_RATE * duration)
    buffer = np.zeros(num_samples)
    t_full = np.linspace(0, duration, num_samples, False)

    # 1. Aggressive distorted sub-bass ostinato
    sub = (np.sin(2 * np.pi * 55.0 * t_full) + 0.4 * np.sin(2 * np.pi * 110.0 * t_full)) * 0.35
    buffer += sub

    # 2. Rapid war drums (160 BPM / 0.375s measure)
    step = 0.1875
    num_steps = int(duration / step)
    for s in range(num_steps):
        s_t = s * step
        idx = int(s_t * SAMPLE_RATE)
        if s % 4 == 0:
            sound = drum_tombak("tom", 0.30)
            mult = 0.75
        elif s % 2 == 1:
            sound = drum_tombak("bak", 0.18)
            mult = 0.55
        else:
            sound = drum_tombak("tap", 0.12)
            mult = 0.35
        end = min(idx + len(sound), num_samples)
        buffer[idx:end] += sound[:end - idx] * mult

    # 3. High tension dramatic brass/synth stabs
    stabs = [
        (0.0, 'D4'), (0.375, 'D4'), (1.5, 'Eb4'), (1.875, 'Eb4'),
        (3.0, 'F4'), (3.75, 'D4'), (5.0, 'G4'), (6.5, 'A4')
    ]
    for rep in range(3):
        offset = rep * 6.5
        for st_t, note in stabs:
            actual = offset + st_t
            if actual + 0.4 < duration:
                idx = int(actual * SAMPLE_RATE)
                s = pluck_string(note_freq(note), 0.32) * 0.5
                end = min(idx + len(s), num_samples)
                buffer[idx:end] += s[:end - idx]

    return buffer

def ney_flute(freq: float, duration: float, sample_rate: int = SAMPLE_RATE) -> np.ndarray:
    # Breathy reed flute (Ney): soft attack, slow vibrato, airy noise
    t = np.linspace(0, duration, int(sample_rate * duration), False)
    vibrato = 1.0 + 0.006 * np.sin(2 * np.pi * 5.0 * t) * np.clip(t * 1.5, 0, 1)
    phase = 2 * np.pi * np.cumsum(freq * vibrato) / sample_rate
    env = np.clip(t / 0.35, 0, 1) * np.clip((duration - t) / 0.5, 0, 1)
    tone = np.sin(phase) * 0.7 + np.sin(phase * 2) * 0.12 + np.sin(phase * 3) * 0.05
    breath = np.random.uniform(-1, 1, len(t))
    breath = np.convolve(breath, np.ones(24) / 24, mode="same") * 0.25
    return (tone + breath) * env

def synth_music_forest() -> np.ndarray:
    # 24-second seamless misty-forest exploration loop (Act II): airy pad, Ney melody, sparse Santur
    np.random.seed(22)
    duration = 24.0
    num_samples = int(SAMPLE_RATE * duration)
    buffer = np.zeros(num_samples)
    t_full = np.linspace(0, duration, num_samples, False)

    # 1. Soft fog pad (D - A - E fifths) with a slow swell that loops cleanly every 12s
    swell = 0.75 + 0.25 * np.sin(2 * np.pi * t_full / 12.0)
    pad = (np.sin(2 * np.pi * note_freq('D3') * t_full) * 0.16 +
           np.sin(2 * np.pi * note_freq('A3') * 1.003 * t_full) * 0.11 +
           np.sin(2 * np.pi * note_freq('E4') * 0.998 * t_full) * 0.06 +
           np.sin(2 * np.pi * note_freq('D2') * t_full) * 0.2)
    buffer += pad * swell

    # 2. Wind through the canopy: band-limited noise
    wind = np.random.uniform(-1, 1, num_samples)
    wind = np.convolve(wind, np.ones(180) / 180, mode="same")
    buffer += wind * (0.5 + 0.5 * np.sin(2 * np.pi * t_full / 8.0)) * 0.9

    # 3. Gentle daf heartbeat every 3 seconds
    for m in range(8):
        idx = int(m * 3.0 * SAMPLE_RATE)
        s_tom = drum_tombak("tom", 0.35)
        buffer[idx:idx + len(s_tom)] += s_tom * 0.28
        idx2 = int((m * 3.0 + 1.5) * SAMPLE_RATE)
        s_tap = drum_tombak("tap", 0.15)
        buffer[idx2:idx2 + len(s_tap)] += s_tap * 0.2

    # 4. Ney melody (D Dorian, wistful)
    melody = [
        (1.0, 'A4', 2.4), (3.6, 'G4', 1.2), (4.9, 'F4', 1.2), (6.2, 'E4', 2.6),
        (9.4, 'D4', 1.4), (10.9, 'F4', 1.2), (12.2, 'G4', 1.6), (14.0, 'A4', 2.8),
        (17.2, 'C5', 1.2), (18.5, 'Bb4', 1.0), (19.6, 'A4', 1.4), (21.1, 'D4', 2.4)
    ]
    for start_t, note, dur in melody:
        idx = int(start_t * SAMPLE_RATE)
        s = ney_flute(note_freq(note), dur)
        end = min(idx + len(s), num_samples)
        buffer[idx:end] += s[:end - idx] * 0.32

    # 5. Sparse Santur droplets like dew falling
    drops = [(2.2, 'D5'), (5.4, 'A4'), (8.1, 'E5'), (11.6, 'D5'), (15.3, 'F5'), (18.0, 'A4'), (22.6, 'E5')]
    for start_t, note in drops:
        idx = int(start_t * SAMPLE_RATE)
        s = pluck_string(note_freq(note), 1.4)
        end = min(idx + len(s), num_samples)
        buffer[idx:end] += s[:end - idx] * 0.22

    return buffer

# -------------------------------------------------------------
# Main Generation Runner
# -------------------------------------------------------------

def main():
    print("=== Generating Persian Mythos SFX & Music Assets ===")
    sfx_map = {
        "jump.wav": gen_jump(),
        "double_jump.wav": gen_double_jump(),
        "land.wav": gen_land(),
        "slash.wav": gen_slash(),
        "heavy_slash.wav": gen_heavy_slash(),
        "bow_shoot.wav": gen_bow_shoot(),
        "arrow_hit.wav": gen_arrow_hit(),
        "slide.wav": gen_slide(),
        "grapple_shoot.wav": gen_grapple_shoot(),
        "grapple_latch.wav": gen_grapple_latch(),
        "player_hurt.wav": gen_player_hurt(),
        "player_die.wav": gen_player_die(),
        "enemy_hit.wav": gen_enemy_hit(),
        "enemy_die.wav": gen_enemy_die(),
        "wolf_bite.wav": gen_wolf_bite(),
        "shield_block.wav": gen_shield_block(),
        "boss_slam.wav": gen_boss_slam(),
        "stalactite_fall.wav": gen_stalactite_fall(),
        "pickup_scrap.wav": gen_pickup_scrap(),
        "pomegranate_pickup.wav": gen_pomegranate_pickup(),
        "keystone_unlock.wav": gen_keystone_unlock(),
        "beacon_ignite.wav": gen_beacon_ignite(),
        "anvil_hammer.wav": gen_anvil_hammer(),
        "ui_click.wav": gen_ui_click(),
        "ui_select.wav": gen_ui_select()
    }

    for name, audio in sfx_map.items():
        write_wav(os.path.join("assets", "audio", "sfx", name), audio)

    print("=== Generating Looping Music Tracks ===")
    write_wav(os.path.join("assets", "audio", "music", "music_menu.wav"), synth_music_menu())
    write_wav(os.path.join("assets", "audio", "music", "music_forge.wav"), synth_music_forge())
    write_wav(os.path.join("assets", "audio", "music", "music_boss.wav"), synth_music_boss())
    write_wav(os.path.join("assets", "audio", "music", "music_forest.wav"), synth_music_forest())
    print("All audio assets generated successfully!")

if __name__ == "__main__":
    import sys
    # `python generate_audio_assets.py forest` regenerates only the Act II track
    if len(sys.argv) > 1 and sys.argv[1] == "forest":
        write_wav(os.path.join("assets", "audio", "music", "music_forest.wav"), synth_music_forest())
    else:
        main()
