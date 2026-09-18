#!/usr/bin/env python3
import math
import os
import random
import struct
import wave

from fetch_external_sounds import ensure_external_samples


SAMPLE_RATE = 44100
OUTPUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Sources",
    "DesktopDestruction",
    "Resources",
    "Sounds",
)


def write_wav(name, samples):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, f"{name}.wav")
    frames = bytearray()
    for sample in samples:
        value = int(max(-1.0, min(1.0, sample)) * 32767)
        frames.extend(struct.pack("<h", value))
    with wave.open(path, "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(bytes(frames))


def seconds(duration):
    return int(SAMPLE_RATE * duration)


def lowpass(samples, strength):
    result = []
    current = 0.0
    coefficient = 1.0 / (1.0 + strength)
    for sample in samples:
        current += (sample - current) * coefficient
        result.append(current)
    return result


def resonator(samples, frequency, bandwidth, gain=1.0):
    radius = math.exp(-math.pi * bandwidth / SAMPLE_RATE)
    angle = 2 * math.pi * frequency / SAMPLE_RATE
    feedback1 = 2 * radius * math.cos(angle)
    feedback2 = -radius * radius
    output = []
    previous1 = 0.0
    previous2 = 0.0
    for sample in samples:
        value = sample + feedback1 * previous1 + feedback2 * previous2
        output.append(value * gain)
        previous2 = previous1
        previous1 = value
    return output


def mix(*layers, master=1.0):
    length = max(len(layer) for layer in layers)
    output = []
    for index in range(length):
        value = 0.0
        for layer in layers:
            if index < len(layer):
                value += layer[index]
        output.append(math.tanh(value * master))
    return output


def read_wav(path):
    with wave.open(str(path), "rb") as source:
        if source.getsampwidth() != 2:
            raise ValueError(f"external sample must be 16-bit PCM: {path}")
        count = source.getnframes()
        frames = source.readframes(count)
        return list(struct.unpack(f"<{count}h", frames))


def scaled(samples, gain):
    return [sample * gain / 32768.0 for sample in samples]


def delayed(samples, delay):
    return [0.0] * seconds(delay) + samples


def fit(samples, duration):
    target = seconds(duration)
    if len(samples) >= target:
        return samples[:target]
    return samples + [0.0] * (target - len(samples))


def segment(samples, start, duration):
    start_index = seconds(start)
    end_index = start_index + seconds(duration)
    if start_index >= len(samples):
        return [0.0] * seconds(duration)
    return fit(samples[start_index:end_index], duration)


def tile(samples, repetitions, crossfade=0.035):
    if repetitions <= 1:
        return list(samples)
    output = list(samples)
    fade_count = min(len(output), seconds(crossfade))
    for _ in range(repetitions - 1):
        chunk = list(samples)
        if fade_count and len(output) >= fade_count:
            for index in range(fade_count):
                weight = index / fade_count
                output[-fade_count + index] = (
                    output[-fade_count + index] * (1.0 - weight)
                    + chunk[index] * weight
                )
            output.extend(chunk[fade_count:])
        else:
            output.extend(chunk)
    return output


def load_external_samples():
    paths = ensure_external_samples()
    return {name: scaled(read_wav(path), 1.0) for name, path in paths.items()}


def generate_human_scream(
    rng,
    duration,
    start_frequency,
    end_frequency,
    formants,
    tension=1.0,
    breath_amount=0.16,
):
    source = []
    phase = 0.0
    jitter = 0.0
    for index in range(seconds(duration)):
        time = index / SAMPLE_RATE
        progress = time / duration
        frequency = start_frequency + (end_frequency - start_frequency) * min(
            1.0,
            progress * 1.22,
        )
        frequency += math.sin(2 * math.pi * 6.5 * time) * 3.2 * tension
        jitter += ((rng.random() - 0.5) * 9.0 * tension - jitter) * 0.10
        frequency += jitter
        phase += frequency / SAMPLE_RATE
        if phase >= 1.0:
            phase -= math.floor(phase)
        pulse = (
            math.sin(2 * math.pi * phase)
            + 0.36 * math.sin(4 * math.pi * phase)
            + 0.20 * math.sin(6 * math.pi * phase)
            + 0.11 * math.sin(8 * math.pi * phase)
        )
        envelope = (
            min(1.0, time / (0.020 + 0.010 * tension))
            * (0.94 + 0.06 * math.sin(2 * math.pi * 8.5 * time))
            * math.exp(-time * (2.4 + tension * 1.35))
        )
        source.append(math.tanh(pulse * (1.2 + tension * 0.5)) * envelope)

    voiced = mix(
        *[
            resonator(source, frequency, bandwidth, gain)
            for frequency, bandwidth, gain in formants
        ],
        master=0.68,
    )
    breath = lowpass([rng.uniform(-1, 1) for _ in range(len(source))], 3)
    throat = lowpass([rng.uniform(-1, 1) for _ in range(len(source))], 12)
    output = []
    for index, (voice, air, roughness) in enumerate(zip(voiced, breath, throat)):
        time = index / SAMPLE_RATE
        tail = math.exp(-time * 6.5) * (1.0 - min(1.0, time / duration))
        shout = voice * (1.0 + 0.22 * math.tanh(voice * 2.0))
        output.append(
            shout
            + air * breath_amount * tail
            + roughness * 0.055 * tension * tail
        )
    return output


def generate_zombie_voice(
    rng,
    duration,
    start_frequency,
    end_frequency,
    growl_strength=1.0,
    roar=False,
):
    source = []
    phase = 0.0
    jitter = 0.0
    for index in range(seconds(duration)):
        time = index / SAMPLE_RATE
        progress = time / duration
        shape = math.sin(math.pi * min(1.0, progress * 1.12))
        frequency = start_frequency + (end_frequency - start_frequency) * shape
        frequency += math.sin(2 * math.pi * 9.5 * time) * (2.2 + growl_strength)
        frequency += math.sin(2 * math.pi * 3.1 * time) * (2.7 + growl_strength)
        jitter += ((rng.random() - 0.5) * 8.0 * growl_strength - jitter) * 0.08
        frequency += jitter
        phase += frequency / SAMPLE_RATE
        if phase >= 1.0:
            phase -= math.floor(phase)
        pulse = (
            math.sin(2 * math.pi * phase)
            + 0.48 * math.sin(4 * math.pi * phase)
            + 0.30 * math.sin(6 * math.pi * phase)
            + 0.18 * math.sin(8 * math.pi * phase)
        )
        envelope = min(1.0, time / (0.045 + 0.015 * growl_strength)) * shape
        source.append(math.tanh(pulse * (1.1 + growl_strength * 0.5)) * envelope)

    formants = [
        (250 + (42 if roar else 0), 135, 1.0),
        (700 + (90 if roar else 0), 190, 0.42),
        (1450 + (180 if roar else 0), 260, 0.14),
    ]
    voiced = mix(
        *[resonator(source, frequency, bandwidth, gain) for frequency, bandwidth, gain in formants],
        master=0.72,
    )
    growl = lowpass([rng.uniform(-1, 1) for _ in range(len(source))], 5)
    wet = lowpass([rng.uniform(-1, 1) for _ in range(len(source))], 15)
    output = []
    for index, (voice, roughness, moisture) in enumerate(
        zip(voiced, growl, wet)
    ):
        time = index / SAMPLE_RATE
        envelope = min(1.0, time / 0.035) * math.exp(
            -time * ((1.1 if roar else 2.3) + 0.15 * growl_strength)
        )
        output.append(
            (
                voice
                + roughness * (0.27 + 0.07 * growl_strength) * growl_strength
                + moisture * 0.06 * growl_strength
            )
            * envelope
            * (0.82 + 0.18 * math.sin(2 * math.pi * (13.5 if roar else 17.5) * time)),
        )
    return output


def generate_animal_voice(
    rng,
    duration,
    start_frequency,
    end_frequency,
    formants,
    distress=1.0,
):
    source = []
    phase = 0.0
    jitter = 0.0
    for index in range(seconds(duration)):
        time = index / SAMPLE_RATE
        progress = time / duration
        shape = math.sin(math.pi * min(1.0, progress * 1.08))
        frequency = start_frequency + (end_frequency - start_frequency) * shape
        frequency += math.sin(2 * math.pi * 8.0 * time) * 3.0 * distress
        jitter += ((rng.random() - 0.5) * 8.0 * distress - jitter) * 0.09
        frequency += jitter
        phase += frequency / SAMPLE_RATE
        if phase >= 1.0:
            phase -= math.floor(phase)
        pulse = (
            math.sin(2 * math.pi * phase)
            + 0.44 * math.sin(4 * math.pi * phase)
            + 0.24 * math.sin(6 * math.pi * phase)
            + 0.12 * math.sin(8 * math.pi * phase)
        )
        envelope = min(1.0, time / 0.028) * shape
        source.append(math.tanh(pulse * 1.35) * envelope)

    voiced = mix(
        *[
            resonator(source, frequency, bandwidth, gain)
            for frequency, bandwidth, gain in formants
        ],
        master=0.68,
    )
    roughness = lowpass([rng.uniform(-1, 1) for _ in range(len(source))], 6)
    output = []
    for voice, rough in zip(voiced, roughness):
        time = len(output) / SAMPLE_RATE
        envelope = min(1.0, time / 0.028) * math.exp(-time * 2.7)
        output.append(
            (voice + rough * 0.16 * distress)
            * envelope
            * (0.88 + 0.12 * math.sin(2 * math.pi * 14.0 * time))
        )
    return output


def band_noise(rng, high_strength, low_strength):
    raw = [rng.uniform(-1, 1) for _ in range(seconds(1.2))]
    return lowpass(raw, high_strength)


def normalize(samples, peak=0.85):
    maximum = max((abs(sample) for sample in samples), default=0.0)
    if maximum < 0.000001:
        return samples
    scale = peak / maximum
    return [sample * scale for sample in samples]


def loopify(samples, fade_ms=20):
    count = int(SAMPLE_RATE * fade_ms / 1000)
    if count <= 0 or len(samples) <= count:
        return samples
    output = samples[:-count]
    for index in range(count):
        weight = index / count
        output[index] = output[index] * weight + samples[-count + index] * (1 - weight)
    return output


def generate():
    rng = random.Random(20260915)
    external = load_external_samples()

    hammer_body = []
    for index in range(seconds(0.34)):
        time = index / SAMPLE_RATE
        impact = math.exp(-time * 25)
        body = math.sin(2 * math.pi * 73 * time) * 0.62
        slap = math.sin(2 * math.pi * 225 * time) * 0.22
        hammer_body.append((body + slap) * impact)
    hammer_ring = []
    for index in range(seconds(0.34)):
        time = index / SAMPLE_RATE
        hammer_ring.append(
            math.sin(2 * math.pi * 415 * time)
            * math.exp(-time * 12)
            * 0.18
        )
    hammer = mix(
        scaled(external["impact_metal_heavy"], 0.95),
        hammer_body,
        delayed(hammer_ring, 0.012),
        master=0.92,
    )
    write_wav("hammer_hit", normalize(hammer, 0.90))

    glass_tail = []
    glass_noise_state = 0.0
    for index in range(seconds(0.68)):
        time = index / SAMPLE_RATE
        raw = rng.uniform(-1, 1)
        glass_noise_state += (raw - glass_noise_state) / 2.0
        if rng.random() < (58.0 * math.exp(-time * 4.5)) / SAMPLE_RATE:
            glass_noise_state += rng.uniform(-0.65, 0.65)
        glass_tail.append(glass_noise_state * math.exp(-time * 3.4))
    glass_tail = mix(
        resonator(glass_tail, 1900, 320, 1.0),
        resonator(glass_tail, 3100, 420, 0.62),
        resonator(glass_tail, 5200, 560, 0.35),
        master=0.70,
    )
    glass = mix(
        scaled(external["impact_glass_heavy"], 1.0),
        delayed(glass_tail, 0.015),
        master=0.90,
    )
    write_wav("glass_shatter", normalize(glass, 0.88))

    for number in range(1, 5):
        shot = []
        noise_state = 0.0
        mechanical_state = 0.0
        seed = rng.uniform(0.9, 1.15)
        for index in range(seconds(0.20)):
            time = index / SAMPLE_RATE
            raw = rng.uniform(-1, 1)
            noise_state += (raw - noise_state) / (1.8 + 9.0 * math.exp(-time * 24.0))
            muzzle = noise_state * math.exp(-time * 42.0)
            thump = math.sin(2 * math.pi * (74.0 * seed + time * 38.0) * time)
            thump *= math.exp(-time * 28.0)
            shot.append((muzzle * 1.15 + thump * 0.58))

        mechanical = []
        for index in range(seconds(0.09)):
            time = index / SAMPLE_RATE
            raw = rng.uniform(-1, 1)
            mechanical_state += (raw - mechanical_state) / 4.0
            mechanical.append(
                mechanical_state
                * (
                    math.exp(-abs(time - 0.018) * 260.0)
                    + 0.55 * math.exp(-abs(time - 0.055) * 220.0)
                )
            )
        full_shot = mix(
            scaled(external["impact_metal_light"], 0.48),
            shot,
            delayed(mechanical, 0.028),
            master=0.88,
        )
        write_wav(f"gun_0{number}", normalize(full_shot, 0.88))

    saw_rng = random.Random(20260918)
    saw_motor = []
    motor_state = 0.0
    for index in range(seconds(1.30)):
        time = index / SAMPLE_RATE
        motor_frequency = 54 + math.sin(2 * math.pi * 3.1 * time) * 3.5
        motor = sum(
            math.sin(2 * math.pi * motor_frequency * harmonic * time) / harmonic
            for harmonic in range(1, 10)
        )
        raw = saw_rng.uniform(-1, 1)
        motor_state += (raw - motor_state) / 5.2
        tooth_load = 0.72 + 0.28 * math.sin(2 * math.pi * 103.0 * time)
        saw_motor.append(motor * 0.62 + motor_state * 0.24 * tooth_load)

    blade_noise = [saw_rng.uniform(-1, 1) for _ in range(seconds(1.30))]
    blade_tone = mix(
        resonator(blade_noise, 1750, 980, 0.34),
        resonator(blade_noise, 3400, 1750, 0.13),
        master=0.42,
    )
    saw = mix(saw_motor, blade_tone, master=0.74)
    write_wav("saw_loop", normalize(loopify(saw, 48), 0.72))

    cut_rng = random.Random(20260919)
    cut_noise = []
    cut_state = 0.0
    for index in range(seconds(0.15)):
        time = index / SAMPLE_RATE
        raw = cut_rng.uniform(-1, 1)
        cut_state += (raw - cut_state) / 1.8
        wood_thump = math.sin(
            2 * math.pi * (148 + 72 * math.exp(-time * 72.0)) * time
        ) * math.exp(-time * 36.0)
        cut_noise.append(cut_state * math.exp(-time * 34.0) + wood_thump * 0.48)
    cut_resonance = mix(
        resonator(cut_noise, 780, 860, 0.48),
        resonator(cut_noise, 2050, 1250, 0.18),
        master=0.48,
    )
    saw_cut = mix(
        scaled(external["impact_metal_light"], 0.20),
        cut_noise,
        delayed(cut_resonance, 0.003),
        master=0.72,
    )
    saw_cut = lowpass(saw_cut, 1.6)
    write_wav("saw_cut_hit", normalize(saw_cut, 0.58))
    # Keep the main RNG sequence aligned with the original saw generation so
    # later sounds do not silently change when saw samples are regenerated.
    for _ in range(seconds(0.65)):
        rng.uniform(-1, 1)

    water = []
    source = [rng.uniform(-1, 1) for _ in range(seconds(1.05))]
    high = lowpass(source, 4)
    low = lowpass(source, 28)
    for index, (bright, dark) in enumerate(zip(high, low)):
        time = index / SAMPLE_RATE
        amplitude = (0.72 + 0.28 * math.sin(2 * math.pi * 13 * time)) * math.sin(math.pi * time / 1.05)
        water.append((bright - dark) * amplitude * 1.8)
    liquid = segment(tile(external["slime"], 3), 0.04, 1.05)
    water = mix(water, liquid, master=0.78)
    write_wav("water_spray", normalize(loopify(water, 35), 0.76))

    flame = []
    brown = 0.0
    flame_external = segment(external["thruster_fire"], 0.55, 1.20)
    for index in range(seconds(1.2)):
        time = index / SAMPLE_RATE
        brown = (brown * 0.996 + rng.uniform(-1, 1) * 0.02)
        crackle = 0.0
        if rng.random() < 18 / SAMPLE_RATE:
            crackle = rng.uniform(-0.35, 0.35)
        flame.append((brown + crackle) * (0.85 + 0.15 * math.sin(2 * math.pi * 2.2 * time)))
    flame = mix(flame_external, flame, master=0.72)
    write_wav("flame_loop", normalize(loopify(flame, 45), 0.74))

    # Keep the external samples intact apart from gain staging and limiting.
    # Earlier versions low-passed the sample and added a synthetic rumble,
    # which made the blast dull and detached from the visual impact.
    explosion = mix(
        scaled(external["explosion_crunch_long"], 0.92),
        scaled(external["explosion_low"], 0.58),
        master=0.88,
    )
    write_wav("explosion", normalize(explosion, 0.84))

    vehicle_explosion = mix(
        scaled(external["explosion_crunch_medium"], 0.88),
        scaled(external["explosion_low_short"], 0.68),
        scaled(external["impact_metal_heavy"], 0.38),
        master=0.86,
    )
    write_wav("vehicle_explosion", normalize(vehicle_explosion, 0.84))
    # Preserve the generator's historical RNG sequence so later sounds remain
    # byte-identical when only the explosion mixes are changed.
    for _ in range(seconds(1.75) + seconds(1.9)):
        rng.uniform(-1, 1)

    rocket = []
    previous = 0.0
    rocket_duration = 1.05
    for index in range(seconds(rocket_duration)):
        time = index / SAMPLE_RATE
        progress = time / rocket_duration
        strength = 2 + 24 * math.sin(math.pi * progress)
        noise = rng.uniform(-1, 1)
        previous += (noise - previous) / strength
        tone = math.sin(2 * math.pi * (285 - 125 * progress) * time)
        rocket.append(
            (previous * 0.82 + tone * 0.22)
            * math.sin(math.pi * min(1, progress * 1.08))
        )
    rocket = mix(
        segment(external["thruster_fire"], 0.18, rocket_duration),
        rocket,
        master=0.74,
    )
    write_wav("rocket_launch", normalize(rocket, 0.88))

    nuke_alarm = []
    siren_phase = 0.0
    alarm_noise_state = 0.0
    alarm_duration = 4.15
    for index in range(seconds(alarm_duration)):
        time = index / SAMPLE_RATE
        progress = time / alarm_duration
        cycle = time % 0.92
        if cycle < 0.46:
            frequency = 612 + 118 * math.sin(math.pi * cycle / 0.46)
        else:
            frequency = 486 - 94 * math.sin(math.pi * (cycle - 0.46) / 0.46)
        siren_phase += frequency / SAMPLE_RATE
        if siren_phase >= 1.0:
            siren_phase -= math.floor(siren_phase)
        saw = 2.0 * siren_phase - 1.0
        square = 1.0 if saw >= 0.0 else -1.0
        voice = math.tanh((saw * 1.12 + square * 0.28) * 1.45) * 0.62
        voice += math.sin(2 * math.pi * frequency * 2 * time) * 0.14
        voice += math.sin(2 * math.pi * frequency * 0.5 * time) * 0.20
        air = rng.uniform(-1, 1)
        alarm_noise_state += (air - alarm_noise_state) / 7.0
        voice += alarm_noise_state * 0.12
        attack = min(1.0, time / 0.10)
        body = min(1.0, time / 0.18) * (0.88 + 0.12 * math.sin(2 * math.pi * 6.2 * time))
        release = min(1.0, max(0.0, (alarm_duration - time) / 0.28))
        nuke_alarm.append(voice * attack * body * release)
    write_wav("nuke_alarm", normalize(nuke_alarm, 0.84))

    nuke_detonation = []
    sub_phase = 0.0
    rumble_state = 0.0
    shock_state = 0.0
    crackle_state = 0.0
    detonation_duration = 5.2
    for index in range(seconds(detonation_duration)):
        time = index / SAMPLE_RATE
        sub_frequency = 20 + 48 * math.exp(-time * 1.45)
        sub_phase += sub_frequency / SAMPLE_RATE
        if sub_phase >= 1.0:
            sub_phase -= math.floor(sub_phase)
        sub = math.sin(2 * math.pi * sub_phase)
        sub += 0.34 * math.sin(2 * math.pi * (sub_frequency * 1.51) * time)
        sub *= math.exp(-time * 0.82)

        white = rng.uniform(-1, 1)
        rumble_state = rumble_state * 0.992 + white * 0.035
        shock_white = rng.uniform(-1, 1)
        shock_state += (shock_white - shock_state) / (1.8 + 45.0 * math.exp(-time * 7.0))
        shock = shock_state * math.exp(-time * 2.6)
        rumble = rumble_state * (0.34 + 0.66 * math.exp(-time * 0.55))

        crackle = 0.0
        if rng.random() < (28.0 * math.exp(-time * 1.8)) / SAMPLE_RATE:
            crackle_state = rng.uniform(-0.65, 0.65)
        crackle_state *= 0.90
        crackle = crackle_state * math.exp(-time * 0.55)

        afterwave = 0.38 * math.exp(-abs(time - 0.24) * 5.0) * math.sin(
            2 * math.pi * 36 * time
        )
        value = sub * 0.92 + shock * 1.82 + rumble * 1.0 + crackle + afterwave
        attack = min(1.0, time / 0.006)
        release = min(1.0, max(0.0, (detonation_duration - time) / 0.58))
        nuke_detonation.append(math.tanh(value * 1.15) * attack * release)
    nuke_detonation = mix(
        scaled(external["explosion_crunch"], 0.52),
        scaled(external["explosion_low"], 0.78),
        nuke_detonation,
        master=0.76,
    )
    write_wav("nuke_detonation", normalize(nuke_detonation, 0.92))

    punch = []
    for index in range(seconds(0.32)):
        time = index / SAMPLE_RATE
        value = math.sin(2 * math.pi * 68 * time) * math.exp(-time * 24)
        value += rng.uniform(-1, 1) * math.exp(-time * 82) * 0.34
        punch.append(value)
    punch = mix(
        scaled(external["impact_punch_heavy"], 0.92),
        punch,
        master=0.86,
    )
    write_wav("punch_hit", normalize(punch, 0.90))

    creature_hit = []
    creature_state = 0.0
    for index in range(seconds(0.24)):
        time = index / SAMPLE_RATE
        raw = rng.uniform(-1, 1)
        creature_state += (raw - creature_state) / (2.0 + 8.0 * math.exp(-time * 32.0))
        body = math.sin(2 * math.pi * 96 * time) * math.exp(-time * 31.0)
        creature_hit.append((creature_state * 0.55 + body * 0.52) * math.exp(-time * 18.0))
    creature_hit = mix(
        scaled(external["impact_soft_medium"], 0.68),
        creature_hit,
        master=0.82,
    )
    write_wav("creature_hit", normalize(creature_hit, 0.82))

    metal_hit = []
    for index in range(seconds(0.34)):
        time = index / SAMPLE_RATE
        body = math.sin(2 * math.pi * 102 * time) * math.exp(-time * 23)
        ring = math.sin(2 * math.pi * 620 * time) * math.exp(-time * 15) * 0.20
        metal_hit.append(body + ring)
    metal_hit = mix(
        scaled(external["impact_metal_heavy"], 0.86),
        metal_hit,
        master=0.84,
    )
    write_wav("metal_hit", normalize(metal_hit, 0.86))

    tick = []
    for index in range(seconds(0.1)):
        time = index / SAMPLE_RATE
        tick.append(math.sin(2 * math.pi * 1150 * time) * math.exp(-time * 72))
    tick = mix(scaled(external["tick"], 0.72), tick, master=0.72)
    write_wav("bomb_tick", normalize(tick, 0.58))

    swish = []
    source = [rng.uniform(-1, 1) for _ in range(seconds(0.22))]
    high = lowpass(source, 2)
    low = lowpass(source, 14)
    for index, (bright, dark) in enumerate(zip(high, low)):
        time = index / SAMPLE_RATE
        swish.append((bright - dark) * math.sin(math.pi * time / 0.22) * 1.6)
    write_wav("erase_swish", normalize(swish, 0.6))

    click = []
    for index in range(seconds(0.07)):
        time = index / SAMPLE_RATE
        click.append(math.sin(2 * math.pi * 1800 * time) * math.exp(-time * 130))
    click = mix(scaled(external["switch"], 0.78), click, master=0.72)
    write_wav("switch_click", normalize(click, 0.54))

    chime = []
    for index in range(seconds(0.7)):
        time = index / SAMPLE_RATE
        chime.append(
            (
                math.sin(2 * math.pi * 660 * time) * 0.58
                + math.sin(2 * math.pi * 990 * time) * 0.32
                + math.sin(2 * math.pi * 1320 * time) * 0.12
            )
            * math.exp(-time * 4.6)
        )
    write_wav("restore_chime", normalize(chime, 0.7))

    person_death = generate_human_scream(
        rng,
        duration=0.62,
        start_frequency=184,
        end_frequency=101,
        formants=[(430, 96, 1.0), (790, 135, 0.48), (2380, 210, 0.14)],
        tension=0.85,
        breath_amount=0.19,
    )
    write_wav("person_death", normalize(person_death, 0.80))

    person_death_oh = generate_human_scream(
        rng,
        duration=0.70,
        start_frequency=163,
        end_frequency=88,
        formants=[(395, 102, 1.0), (750, 145, 0.46), (2260, 225, 0.13)],
        tension=0.78,
        breath_amount=0.22,
    )
    write_wav("person_death_oh", normalize(person_death_oh, 0.80))

    person_death_ah = generate_human_scream(
        rng,
        duration=0.76,
        start_frequency=238,
        end_frequency=112,
        formants=[(690, 115, 1.0), (1130, 155, 0.54), (2620, 200, 0.17)],
        tension=1.08,
        breath_amount=0.19,
    )
    write_wav("person_death_ah", normalize(person_death_ah, 0.80))

    person_death_scream = generate_human_scream(
        rng,
        duration=0.88,
        start_frequency=291,
        end_frequency=124,
        formants=[(735, 125, 1.0), (1230, 175, 0.55), (2750, 190, 0.20)],
        tension=1.28,
        breath_amount=0.20,
    )
    write_wav("person_death_scream", normalize(person_death_scream, 0.80))

    animal_death = generate_animal_voice(
        rng,
        duration=0.62,
        start_frequency=148,
        end_frequency=84,
        formants=[(315, 125, 1.0), (900, 180, 0.38), (2050, 290, 0.12)],
        distress=0.92,
    )
    write_wav("animal_death", normalize(animal_death, 0.82))

    person_burn_death = generate_human_scream(
        rng,
        duration=0.82,
        start_frequency=252,
        end_frequency=92,
        formants=[(705, 130, 1.0), (1180, 170, 0.48), (2560, 210, 0.18)],
        tension=1.18,
        breath_amount=0.25,
    )
    burn_noise = lowpass([rng.uniform(-1, 1) for _ in range(len(person_burn_death))], 4)
    for index in range(len(person_burn_death)):
        time = index / SAMPLE_RATE
        crackle = 0.0
        if rng.random() < 25 / SAMPLE_RATE:
            crackle = rng.uniform(-0.24, 0.24)
        person_burn_death[index] += (burn_noise[index] * 0.14 + crackle) * math.exp(-time * 2.5)
    write_wav("person_burn_death", normalize(person_burn_death, 0.80))

    zombie_growls = [
        generate_zombie_voice(rng, 0.86, 82, 59, growl_strength=1.0),
        generate_zombie_voice(rng, 1.02, 71, 94, growl_strength=0.86),
        generate_zombie_voice(rng, 0.78, 97, 64, growl_strength=1.14),
    ]
    for number, growl in enumerate(zombie_growls, 1):
        write_wav(f"zombie_growl_{number:02d}", normalize(growl, 0.82))

    zombie_bite = []
    bite_noise = lowpass([rng.uniform(-1, 1) for _ in range(seconds(0.24))], 1.6)
    for index in range(seconds(0.24)):
        time = index / SAMPLE_RATE
        snap1 = math.exp(-abs(time - 0.025) * 260)
        snap2 = math.exp(-abs(time - 0.110) * 190)
        wet = math.sin(2 * math.pi * (152 - 58 * time) * time) * snap2
        bite = bite_noise[index] * (snap1 * 0.85 + snap2 * 0.55)
        zombie_bite.append((bite + wet * 0.55) * min(1.0, time / 0.008))
    write_wav("zombie_bite", normalize(zombie_bite, 0.66))

    zombie_elite_roar = generate_zombie_voice(
        rng,
        duration=1.38,
        start_frequency=51,
        end_frequency=82,
        growl_strength=1.45,
        roar=True,
    )
    write_wav("zombie_elite_roar", normalize(zombie_elite_roar, 0.88))

    animal_burn_death = generate_animal_voice(
        rng,
        duration=0.78,
        start_frequency=252,
        end_frequency=92,
        formants=[(660, 145, 1.0), (1340, 220, 0.42), (2650, 300, 0.14)],
        distress=1.24,
    )
    animal_burn_noise = lowpass(
        [rng.uniform(-1, 1) for _ in range(len(animal_burn_death))], 5
    )
    for index in range(len(animal_burn_death)):
        time = index / SAMPLE_RATE
        crackle = 0.0
        if rng.random() < 22 / SAMPLE_RATE:
            crackle = rng.uniform(-0.22, 0.22)
        animal_burn_death[index] += (
            animal_burn_noise[index] * 0.13 + crackle
        ) * math.exp(-time * 2.2)
    write_wav("animal_burn_death", normalize(animal_burn_death, 0.8))


if __name__ == "__main__":
    generate()
    print(f"Generated sounds in {OUTPUT_DIR}")
