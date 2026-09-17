#!/usr/bin/env python3
import math
import os
import random
import struct
import wave

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
    for index in range(seconds(duration)):
        time = index / SAMPLE_RATE
        progress = time / duration
        frequency = start_frequency + (end_frequency - start_frequency) * min(
            1.0,
            progress * 1.22,
        )
        frequency += math.sin(2 * math.pi * 6.5 * time) * 3.2 * tension
        frequency += (rng.random() - 0.5) * 3.8 * tension
        phase += frequency / SAMPLE_RATE
        if phase >= 1.0:
            phase -= math.floor(phase)
        pulse = (
            math.sin(2 * math.pi * phase)
            + 0.36 * math.sin(4 * math.pi * phase)
            + 0.20 * math.sin(6 * math.pi * phase)
            + 0.11 * math.sin(8 * math.pi * phase)
        )
        envelope = min(1.0, time / 0.028) * math.exp(-time * (2.7 + tension * 1.5))
        source.append(math.tanh(pulse * (1.2 + tension * 0.5)) * envelope)

    voiced = mix(
        *[
            resonator(source, frequency, bandwidth, gain)
            for frequency, bandwidth, gain in formants
        ],
        master=0.68,
    )
    breath = lowpass([rng.uniform(-1, 1) for _ in range(len(source))], 2)
    output = []
    for index, (voice, air) in enumerate(zip(voiced, breath)):
        time = index / SAMPLE_RATE
        tail = math.exp(-time * 8.0) * (1.0 - min(1.0, time / duration))
        shout = voice * (1.0 + 0.22 * math.tanh(voice * 2.0))
        output.append(shout + air * breath_amount * tail)
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
    for index in range(seconds(duration)):
        time = index / SAMPLE_RATE
        progress = time / duration
        shape = math.sin(math.pi * min(1.0, progress * 1.12))
        frequency = start_frequency + (end_frequency - start_frequency) * shape
        frequency += math.sin(2 * math.pi * 11.0 * time) * 2.8
        frequency += math.sin(2 * math.pi * 3.1 * time) * 3.6
        phase += frequency / SAMPLE_RATE
        if phase >= 1.0:
            phase -= math.floor(phase)
        pulse = (
            math.sin(2 * math.pi * phase)
            + 0.48 * math.sin(4 * math.pi * phase)
            + 0.30 * math.sin(6 * math.pi * phase)
            + 0.18 * math.sin(8 * math.pi * phase)
        )
        envelope = min(1.0, time / 0.06) * shape
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
    growl = lowpass([rng.uniform(-1, 1) for _ in range(len(source))], 6)
    output = []
    for index, (voice, roughness) in enumerate(zip(voiced, growl)):
        time = index / SAMPLE_RATE
        envelope = min(1.0, time / 0.035) * math.exp(-time * (1.7 if roar else 2.7))
        output.append(
            (voice + roughness * 0.28 * growl_strength)
            * envelope
            * (0.82 + 0.18 * math.sin(2 * math.pi * 16.5 * time)),
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

    hammer = []
    for index in range(seconds(0.28)):
        time = index / SAMPLE_RATE
        impact = math.exp(-time * 32)
        body = math.sin(2 * math.pi * 118 * time) * 0.45
        click = math.exp(-time * 180) * math.sin(2 * math.pi * 1700 * time) * 0.35
        hammer.append((body + click + lowpass([rng.uniform(-1, 1)], 1.5)[-1] * impact) * impact)
    write_wav("hammer_hit", normalize(hammer))

    for number in range(1, 5):
        shot = []
        seed = rng.uniform(0.9, 1.15)
        for index in range(seconds(0.22)):
            time = index / SAMPLE_RATE
            envelope = math.exp(-time * 58)
            noise = rng.uniform(-1, 1)
            thump = math.sin(2 * math.pi * (140 * seed + index / SAMPLE_RATE * 45) * time)
            shot.append((noise * 0.68 + thump * 0.42) * envelope)
        write_wav(f"gun_0{number}", normalize(shot))

    saw = []
    for index in range(seconds(0.5)):
        time = index / SAMPLE_RATE
        frequency = 62 + math.sin(2 * math.pi * 4 * time) * 4
        value = sum(math.sin(2 * math.pi * frequency * harmonic * time) / harmonic for harmonic in range(1, 9))
        saw.append(value * 0.24)
    write_wav("saw_loop", normalize(loopify(saw)))

    water = []
    source = [rng.uniform(-1, 1) for _ in range(seconds(1.05))]
    high = lowpass(source, 4)
    low = lowpass(source, 28)
    for index, (bright, dark) in enumerate(zip(high, low)):
        time = index / SAMPLE_RATE
        amplitude = (0.72 + 0.28 * math.sin(2 * math.pi * 13 * time)) * math.sin(math.pi * time / 1.05)
        water.append((bright - dark) * amplitude * 2.2)
    write_wav("water_spray", normalize(water))

    flame = []
    brown = 0.0
    for index in range(seconds(1.2)):
        time = index / SAMPLE_RATE
        brown = (brown * 0.996 + rng.uniform(-1, 1) * 0.02)
        crackle = 0.0
        if rng.random() < 14 / SAMPLE_RATE:
            crackle = rng.uniform(-0.35, 0.35)
        flame.append((brown + crackle) * (0.85 + 0.15 * math.sin(2 * math.pi * 2.2 * time)))
    write_wav("flame_loop", normalize(loopify(flame)))

    explosion = []
    for index in range(seconds(1.15)):
        time = index / SAMPLE_RATE
        boom = (math.sin(2 * math.pi * 50 * time) * 0.7 + math.sin(2 * math.pi * 88 * time) * 0.35)
        noise = lowpass([rng.uniform(-1, 1) for _ in range(1)], 1.1)[-1]
        value = (boom + noise * 0.8) * math.exp(-time * 3.2)
        explosion.append(math.tanh(value * 1.5))
    write_wav("explosion", normalize(explosion))

    rocket = []
    previous = 0.0
    for index in range(seconds(0.85)):
        time = index / SAMPLE_RATE
        progress = time / 0.85
        strength = 2 + 24 * math.sin(math.pi * progress)
        noise = rng.uniform(-1, 1)
        previous += (noise - previous) / strength
        tone = math.sin(2 * math.pi * (320 - 120 * progress) * time)
        rocket.append((previous * 0.85 + tone * 0.24) * math.sin(math.pi * min(1, progress * 1.1)))
    write_wav("rocket_launch", normalize(rocket))

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
    write_wav("nuke_detonation", normalize(nuke_detonation, 0.92))

    punch = []
    for index in range(seconds(0.25)):
        time = index / SAMPLE_RATE
        value = math.sin(2 * math.pi * 82 * time) * math.exp(-time * 34)
        value += rng.uniform(-1, 1) * math.exp(-time * 90) * 0.4
        punch.append(value)
    write_wav("punch_hit", normalize(punch))

    tick = []
    for index in range(seconds(0.1)):
        time = index / SAMPLE_RATE
        tick.append(math.sin(2 * math.pi * 1150 * time) * math.exp(-time * 72))
    write_wav("bomb_tick", normalize(tick, 0.55))

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
    write_wav("switch_click", normalize(click, 0.5))

    chime = []
    for index in range(seconds(0.7)):
        time = index / SAMPLE_RATE
        frequency = 620 + (930 - 620) * min(1, time / 0.22)
        chime.append(math.sin(2 * math.pi * frequency * time) * math.exp(-time * 4.2) * 0.7)
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

    animal_death = []
    for index in range(seconds(0.54)):
        time = index / SAMPLE_RATE
        progress = time / 0.54
        frequency = 134 - 58 * progress + math.sin(2 * math.pi * 7.5 * time) * 3.5
        voice = math.sin(2 * math.pi * frequency * time) * 0.58
        voice += math.sin(2 * math.pi * frequency * 1.92 * time) * 0.2
        voice += math.sin(2 * math.pi * frequency * 3.1 * time) * 0.08
        growl = lowpass([rng.uniform(-1, 1)], 7)[-1] * 0.18
        envelope = min(1, time / 0.025) * math.exp(-time * 3.5) * (1 - progress * 0.35)
        animal_death.append((voice + growl) * envelope)
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

    animal_burn_death = []
    for index in range(seconds(0.56)):
        time = index / SAMPLE_RATE
        progress = time / 0.56
        frequency = 252 - 126 * progress
        voice = math.sin(2 * math.pi * frequency * time) * 0.55
        voice += math.sin(2 * math.pi * frequency * 1.84 * time) * 0.19
        voice += math.sin(2 * math.pi * frequency * 3.02 * time) * 0.07
        distress = lowpass([rng.uniform(-1, 1)], 4)[-1] * 0.14
        crackle = 0.0
        if rng.random() < 16 / SAMPLE_RATE:
            crackle = rng.uniform(-0.22, 0.22)
        envelope = min(1, time / 0.025) * math.exp(-time * 3.3)
        animal_burn_death.append((voice + distress + crackle) * envelope)
    write_wav("animal_burn_death", normalize(animal_burn_death, 0.8))


if __name__ == "__main__":
    generate()
    print(f"Generated sounds in {OUTPUT_DIR}")
