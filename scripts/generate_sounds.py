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

    person_death = []
    for index in range(seconds(0.46)):
        time = index / SAMPLE_RATE
        progress = time / 0.46
        frequency = 232 - 104 * progress
        voice = math.sin(2 * math.pi * frequency * time) * 0.52
        voice += math.sin(2 * math.pi * frequency * 2.08 * time) * 0.15
        voice += math.sin(2 * math.pi * frequency * 3.25 * time) * 0.05
        breath = lowpass([rng.uniform(-1, 1)], 3)[-1] * 0.16
        envelope = math.sin(math.pi * min(1, progress * 1.08)) * math.exp(-time * 4.1)
        person_death.append((voice + breath) * envelope)
    write_wav("person_death", normalize(person_death, 0.78))

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

    person_burn_death = []
    for index in range(seconds(0.62)):
        time = index / SAMPLE_RATE
        progress = time / 0.62
        frequency = 610 - 315 * progress
        voice = math.sin(2 * math.pi * frequency * time) * 0.48
        voice += math.sin(2 * math.pi * frequency * 1.68 * time) * 0.18
        voice += math.sin(2 * math.pi * frequency * 2.75 * time) * 0.08
        crackle = 0.0
        if rng.random() < 22 / SAMPLE_RATE:
            crackle = rng.uniform(-0.28, 0.28)
        envelope = min(1, time / 0.015) * math.exp(-time * 3.1)
        person_burn_death.append((voice + crackle) * envelope)
    write_wav("person_burn_death", normalize(person_burn_death, 0.78))

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
