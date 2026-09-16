#!/usr/bin/env python3

import argparse
import re
import time
import tempfile
import urllib.request
import urllib.error
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SOURCE_FILES = [
    ROOT / "Sources/DesktopDestruction/Engine/CreatureSimulation.swift",
    ROOT / "Sources/DesktopDestruction/Engine/AnimalSpecies.swift",
    ROOT / "Sources/DesktopDestruction/Engine/EmojiSpecies.swift",
]
OPENMOJI_BASE = (
    "https://raw.githubusercontent.com/hfg-gmuend/openmoji/master"
    "/color/618x618"
)
OPENMOJI_LICENSE = (
    "https://raw.githubusercontent.com/hfg-gmuend/openmoji/master/LICENSE.txt"
)
KENNEY_PARTICLE_PACK = (
    "https://kenney.nl/media/pages/assets/particle-pack/"
    "f8fe0f8cb8-1677578741/kenney_particle-pack.zip"
)
KENNEY_PARTICLES = {
    "PNG (Transparent)/fire_01.png": "effect-fire.png",
    "PNG (Transparent)/smoke_01.png": "effect-smoke.png",
    "PNG (Transparent)/spark_01.png": "effect-spark.png",
    "PNG (Transparent)/muzzle_01.png": "effect-muzzle-flash.png",
    "PNG (Transparent)/dirt_01.png": "effect-debris.png",
}
KENNEY_ANIMAL_PACK = (
    "https://kenney.nl/media/pages/assets/animal-pack-remastered/"
    "54a307a369-1774771709/kenney_animal-pack-remastered.zip"
)
KENNEY_TOON_CHARACTERS = (
    "https://kenney.nl/media/pages/assets/toon-characters/"
    "4e8a6e4e53-1774770819/kenney_toon-characters.zip"
)
KENNEY_PLATFORMER_CHARACTERS = (
    "https://kenney.nl/media/pages/assets/platformer-characters/"
    "b85f388c42-1677693768/kenney_platformer-characters.zip"
)
OPEN_GAME_ART_EXPLOSION = (
    "https://opengameart.org/sites/default/files/exp2_0.png"
)
CC0_LICENSE = "https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt"
KENNEY_ANIMALS = {
    filename: f"animal-{filename.removesuffix('.png')}.png"
    for filename in [
        "bear", "buffalo", "chick", "chicken", "cow", "crocodile", "dog",
        "duck", "elephant", "frog", "giraffe", "goat", "gorilla", "hippo",
        "horse", "monkey", "moose", "narwhal", "owl", "panda", "parrot",
        "penguin", "pig", "rabbit", "rhino", "sloth", "snake", "walrus",
        "whale", "zebra",
    ]
}
KENNEY_TOON_PEOPLE = {
    "Female person/PNG/Poses HD/character_femalePerson_idle.png": "character-female.png",
    "Male person/PNG/Poses HD/character_malePerson_idle.png": "character-male.png",
    "Robot/PNG/Poses HD/character_robot_idle.png": "character-robot.png",
    "Zombie/PNG/Poses HD/character_zombie_idle.png": "character-zombie-medium.png",
    "Zombie/PNG/Poses HD/character_zombie_walk0.png": "character-zombie-large.png",
    "Zombie/PNG/Poses HD/character_zombie_attack0.png": "character-zombie-brute.png",
}
KENNEY_PLATFORMER_PEOPLE = {
    "PNG/Player/Poses/player_idle.png": "character-runner.png",
    "PNG/Adventurer/Poses/adventurer_idle.png": "character-adventurer.png",
    "PNG/Soldier/Poses/soldier_idle.png": "character-soldier.png",
    "PNG/Zombie/Poses/zombie_idle.png": "character-zombie-small.png",
}


def is_emoji(value: str) -> bool:
    if not value:
        return False
    return any(
        0x1F000 <= ord(character) <= 0x1FAFF
        or 0x2600 <= ord(character) <= 0x27BF
        or 0x2190 <= ord(character) <= 0x21FF
        or 0x2B00 <= ord(character) <= 0x2BFF
        or 0xFE0F == ord(character)
        for character in value
    )


def openmoji_name(emoji: str) -> str:
    scalars = [ord(character) for character in emoji if ord(character) != 0xFE0F]
    return "-".join(f"{scalar:04X}" for scalar in scalars)


def collect_emojis() -> list[str]:
    values: set[str] = set()
    pattern = re.compile(r'"([^"\\]+)"')
    for source in SOURCE_FILES:
        for match in pattern.finditer(source.read_text(encoding="utf-8")):
            value = match.group(1)
            if is_emoji(value):
                values.add(value)
    return sorted(values, key=openmoji_name)


def download(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": "DesktopDestruction"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return response.read()
        except urllib.error.HTTPError:
            raise
        except urllib.error.URLError:
            if attempt == 3:
                raise
            time.sleep(0.5 * (attempt + 1))
    raise RuntimeError("unreachable download retry state")


def write_if_needed(path: Path, data: bytes, force: bool) -> bool:
    if path.exists() and not force and path.read_bytes() == data:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return True


def fetch_openmoji(force: bool) -> None:
    output = ROOT / "Sources/DesktopDestruction/Resources/OpenMoji"
    emojis = collect_emojis()
    downloaded = 0
    missing: list[str] = []
    for emoji in emojis:
        name = openmoji_name(emoji)
        path = output / f"{name}.png"
        if path.exists() and not force:
            continue
        try:
            data = download(f"{OPENMOJI_BASE}/{name}.png")
        except urllib.error.HTTPError as error:
            if error.code == 404:
                missing.append(emoji)
                continue
            raise
        if write_if_needed(path, data, force):
            downloaded += 1
    write_if_needed(
        ROOT / "THIRD_PARTY_LICENSES/OpenMoji-LICENSE.txt",
        download(OPENMOJI_LICENSE),
        force,
    )
    print(
        f"OpenMoji: {len(emojis) - len(missing)} bundled sprites, "
        f"{downloaded} downloaded/updated"
    )
    if missing:
        print("Missing from OpenMoji (system emoji fallback): " + " ".join(missing))


def fetch_kenney_particles(force: bool) -> None:
    output = ROOT / "Sources/DesktopDestruction/Resources/Art"
    install_from_zip(
        KENNEY_PARTICLE_PACK,
        members=KENNEY_PARTICLES,
        output=output,
        license_name="Kenney-Particle-Pack-License.txt",
        force=force,
    )
    print(f"Kenney Particle Pack: {len(KENNEY_PARTICLES)} sprites installed")


def fetch_kenney_characters(force: bool) -> None:
    output = ROOT / "Sources/DesktopDestruction/Resources/Characters"
    animal_members = {
        f"PNG/Round/{filename}.png": output_name
        for filename, output_name in KENNEY_ANIMALS.items()
    }
    install_from_zip(
        KENNEY_ANIMAL_PACK,
        members=animal_members,
        output=output,
        license_name="Kenney-Animal-Pack-Remastered-License.txt",
        force=force,
    )
    print(f"Kenney Animal Pack Remastered: {len(KENNEY_ANIMALS)} sprites installed")

    install_from_zip(
        KENNEY_TOON_CHARACTERS,
        members=KENNEY_TOON_PEOPLE,
        output=output,
        license_name="Kenney-Toon-Characters-License.txt",
        force=force,
    )
    print(f"Kenney Toon Characters: {len(KENNEY_TOON_PEOPLE)} sprites installed")

    install_from_zip(
        KENNEY_PLATFORMER_CHARACTERS,
        members=KENNEY_PLATFORMER_PEOPLE,
        output=output,
        license_name="Kenney-Platformer-Characters-License.txt",
        force=force,
    )
    print(f"Kenney Platformer Characters: {len(KENNEY_PLATFORMER_PEOPLE)} sprites installed")


def fetch_open_game_art_explosion(force: bool) -> None:
    output = ROOT / "Sources/DesktopDestruction/Resources/Art/effect-explosion.png"
    write_if_needed(output, download(OPEN_GAME_ART_EXPLOSION), force)
    license_text = (
        "Explosion sprites\n"
        "Author: Cuzco\n"
        "Source: https://opengameart.org/content/explosion\n"
        "License: CC0 1.0 Universal\n"
        "\n"
    ).encode("utf-8") + download(CC0_LICENSE)
    write_if_needed(
        ROOT / "THIRD_PARTY_LICENSES/OpenGameArt-Explosion-License.txt",
        license_text,
        force,
    )
    print("OpenGameArt Explosion: 1 sprite installed")


def install_from_zip(
    url: str,
    members: dict[str, str],
    output: Path,
    license_name: str,
    force: bool,
) -> None:
    archive_data = download(url)
    with tempfile.TemporaryDirectory() as temporary_directory:
        archive_name = url.rsplit("/", 1)[-1]
        archive_path = Path(temporary_directory) / archive_name
        archive_path.write_bytes(archive_data)
        with zipfile.ZipFile(archive_path) as archive:
            for member, filename in members.items():
                write_if_needed(output / filename, archive.read(member), force)
            write_if_needed(
                ROOT / "THIRD_PARTY_LICENSES" / license_name,
                archive.read("License.txt"),
                force,
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true")
    arguments = parser.parse_args()
    fetch_openmoji(arguments.force)
    fetch_kenney_particles(arguments.force)
    fetch_kenney_characters(arguments.force)
    fetch_open_game_art_explosion(arguments.force)


if __name__ == "__main__":
    main()
