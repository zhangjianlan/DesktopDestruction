#!/usr/bin/env python3

import argparse
from io import BytesIO
import re
import time
import tempfile
import urllib.request
import urllib.error
import zipfile
from pathlib import Path

from PIL import (
    Image,
    ImageChops,
    ImageDraw,
    ImageEnhance,
    ImageFilter,
    ImageOps,
)


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
KENNEY_MONSTER_BUILDER = (
    "https://kenney.nl/media/pages/assets/monster-builder-pack/"
    "663e4ef6de-1677495438/kenney_monster-builder-pack.zip"
)
OPEN_GAME_ART_EXPLOSION = (
    "https://opengameart.org/sites/default/files/explosion_0.zip"
)
GAME_ICONS_ARCHIVE = (
    "https://game-icons.net/archives/ffffff/transparent/"
    "game-icons.net.png.zip"
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

GAME_ICONS = {
    "tool-hammer": ("lorc/flat-hammer.png", ((226, 232, 240), (100, 116, 139))),
    "tool-machine-gun": ("lorc/minigun.png", ((203, 213, 225), (51, 65, 85))),
    "tool-saw": ("sbed/circular-saw.png", ((226, 232, 240), (71, 85, 105))),
    "tool-water": ("delapouite/water-gun.png", ((125, 211, 252), (14, 116, 144))),
    "tool-flame": ("delapouite/flamethrower.png", ((254, 240, 138), (185, 28, 28))),
    "tool-bomb": ("lorc/grenade.png", ((147, 197, 253), (30, 64, 175))),
    "tool-eraser": ("delapouite/broom.png", ((254, 240, 138), (146, 64, 14))),
    "tool-rocket": ("lorc/rocket.png", ((254, 215, 170), (194, 65, 12))),
    "tool-nuke": ("skoll/nuclear-bomb.png", ((254, 240, 138), (22, 163, 74))),
    "tool-fist": ("lorc/fist.png", ((254, 215, 170), (180, 83, 9))),
    "tool-insect": ("lorc/scarab-beetle.png", ((134, 239, 172), (6, 78, 59))),
    "tool-person": ("delapouite/person.png", ((254, 215, 170), (31, 41, 55))),
    "tool-vehicle": ("delapouite/jeep.png", ((252, 165, 165), (153, 27, 27))),
    "tool-animal": ("lorc/paw-front.png", ((253, 230, 138), (41, 37, 36))),
    "tool-anything": ("delapouite/sparkles.png", ((254, 249, 195), (202, 138, 4))),
    "tool-wall": ("delapouite/brick-wall.png", ((251, 191, 36), (120, 53, 15))),
    "tool-target": ("lorc/archery-target.png", ((254, 226, 226), (159, 18, 57))),
    "tool-sparkle": ("delapouite/stars-stack.png", ((254, 249, 195), (37, 99, 235))),
    "ui-restore": (
        "delapouite/anticlockwise-rotation.png",
        ((191, 219, 254), (29, 78, 216)),
    ),
    "ui-settings": ("delapouite/settings-knobs.png", ((226, 232, 240), (51, 65, 85))),
    "ui-exit": ("delapouite/exit-door.png", ((254, 202, 202), (127, 29, 29))),
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
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "DesktopDestruction",
            "Accept": "*/*",
            "Connection": "close",
        },
    )
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


def fetch_kenney_monster_builder(force: bool) -> None:
    output = ROOT / "Sources/DesktopDestruction/Resources/Characters/character-radiation-monster.png"
    archive_data = download(KENNEY_MONSTER_BUILDER)

    with zipfile.ZipFile(BytesIO(archive_data)) as archive:
        def sprite(filename: str) -> Image.Image:
            member = f"PNG/Double/{filename}"
            return Image.open(BytesIO(archive.read(member))).convert("RGBA")

        def paste(
            filename: str,
            box: tuple[int, int, int, int],
            mirror: bool = False,
        ) -> None:
            image = sprite(filename)
            if mirror:
                image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            image = image.resize((box[2], box[3]), Image.LANCZOS)
            canvas.alpha_composite(image, (box[0], box[1]))

        canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
        paste("arm_greenA.png", (30, 175, 310, 665), mirror=True)
        paste("arm_greenA.png", (684, 175, 310, 665))
        paste("leg_greenA.png", (250, 460, 230, 535), mirror=True)
        paste("leg_greenA.png", (530, 460, 230, 535))

        body = sprite("body_greenB.png").resize(
            (740, 740),
            Image.LANCZOS,
        )
        canvas.alpha_composite(body, (142, 142))

        radiation_tint = Image.new("RGBA", body.size, (136, 255, 112, 42))
        radiation_tint.putalpha(
            ImageChops.multiply(
                radiation_tint.getchannel("A"),
                body.getchannel("A"),
            )
        )
        canvas.alpha_composite(radiation_tint, (142, 142))

        radiation_mark = Image.new("RGBA", body.size, (0, 0, 0, 0))
        mark_draw = ImageDraw.Draw(radiation_mark)
        mark_bounds = (296, 406, 444, 554)
        for start in (18, 138, 258):
            mark_draw.pieslice(
                mark_bounds,
                start=start,
                end=start + 58,
                fill=(255, 214, 0, 205),
            )
        mark_draw.ellipse((331, 441, 409, 519), fill=(24, 58, 30, 235))
        radiation_mark.putalpha(
            ImageChops.multiply(
                radiation_mark.getchannel("A"),
                body.getchannel("A"),
            )
        )
        canvas.alpha_composite(radiation_mark, (142, 142))

        paste("detail_yellow_horn_large.png", (318, 62, 158, 166))
        paste("detail_yellow_horn_large.png", (548, 62, 158, 166))
        paste("eye_angry_red.png", (318, 294, 158, 145))
        paste("eye_angry_blue.png", (548, 294, 158, 145))
        paste("mouthF.png", (415, 440, 194, 110))

        output.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(output, optimize=True)
        write_if_needed(
            ROOT / "THIRD_PARTY_LICENSES/Kenney-Monster-Builder-Pack-License.txt",
            archive.read("License.txt"),
            force,
        )

    print("Kenney Monster Builder Pack: radiation monster composed")


def stylize_game_icon(
    source: Image.Image,
    colors: tuple[tuple[int, int, int], tuple[int, int, int]],
) -> Image.Image:
    """Turn a white Game-icons glyph into a cohesive comic toolbar icon."""
    icon = ImageOps.pad(
        source,
        (208, 208),
        method=Image.Resampling.LANCZOS,
        color=(0, 0, 0, 0),
    )
    alpha = icon.getchannel("A")

    gradient = Image.linear_gradient("L").resize(
        (208, 208),
        Image.Resampling.BILINEAR,
    )
    fill = ImageOps.colorize(
        gradient,
        black=colors[1],
        white=colors[0],
    ).convert("RGBA")
    fill.putalpha(alpha)

    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    shadow_alpha = alpha.filter(ImageFilter.MaxFilter(5)).filter(
        ImageFilter.GaussianBlur(8)
    )
    shadow = Image.new("RGBA", (208, 208), (0, 0, 0, 0))
    shadow.putalpha(shadow_alpha.point(lambda value: min(92, int(value * 0.38))))
    canvas.alpha_composite(shadow, (8, 12))

    outline_alpha = alpha.filter(ImageFilter.MaxFilter(9))
    outline = Image.new("RGBA", (208, 208), (0, 0, 0, 0))
    outline.putalpha(outline_alpha)
    outline.paste((23, 20, 31, 255), (0, 0), outline_alpha)
    canvas.alpha_composite(outline, (20, 18))
    canvas.alpha_composite(fill, (20, 18))
    return canvas


def fetch_game_icons(force: bool) -> None:
    output = ROOT / "Sources/DesktopDestruction/Resources/Art"
    archive_data = download(GAME_ICONS_ARCHIVE)
    with tempfile.TemporaryDirectory() as temporary_directory:
        archive_path = Path(temporary_directory) / "game-icons.zip"
        archive_path.write_bytes(archive_data)
        with zipfile.ZipFile(archive_path) as archive:
            for filename, (member, colors) in GAME_ICONS.items():
                archive_member = f"icons/ffffff/transparent/1x1/{member}"
                source = Image.open(BytesIO(archive.read(archive_member))).convert("RGBA")
                image = stylize_game_icon(source, colors)
                buffer = BytesIO()
                image.save(buffer, format="PNG", optimize=True)
                write_if_needed(output / f"{filename}.png", buffer.getvalue(), force)
            write_if_needed(
                ROOT / "THIRD_PARTY_LICENSES/Game-Icons-License.txt",
                archive.read("icons/license.txt"),
                force,
            )
    print(f"Game-icons.net: {len(GAME_ICONS)} stylized icons installed")


def fetch_open_game_art_explosion(force: bool) -> None:
    output = ROOT / "Sources/DesktopDestruction/Resources/Art/effect-explosion.png"
    archive_data = download(OPEN_GAME_ART_EXPLOSION)
    with zipfile.ZipFile(BytesIO(archive_data)) as archive:
        sheet = Image.open(BytesIO(archive.read("explosion.png"))).convert("RGBA")
        frame = sheet.crop((4 * 125, 0, 5 * 125, sheet.height))
        frame = frame.crop(frame.getbbox())
        frame = ImageOps.pad(
            frame,
            (512, 512),
            method=Image.Resampling.LANCZOS,
            color=(0, 0, 0, 0),
        )
        frame = ImageEnhance.Color(frame).enhance(1.22)
        frame = ImageEnhance.Contrast(frame).enhance(1.1)

        glow_alpha = frame.getchannel("A").filter(ImageFilter.GaussianBlur(28))
        glow = Image.new("RGBA", frame.size, (255, 178, 62, 0))
        glow.putalpha(glow_alpha.point(lambda value: min(108, int(value * 0.42))))
        frame.alpha_composite(glow)

        buffer = BytesIO()
        frame.save(buffer, format="PNG", optimize=True)
        write_if_needed(output, buffer.getvalue(), force)

    license_text = (
        "Explosion sprites\n"
        "Author: Rebekka Helzle / TinyWorlds\n"
        "Source: https://opengameart.org/content/explosion-animation\n"
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
    fetch_kenney_monster_builder(arguments.force)
    fetch_game_icons(arguments.force)
    fetch_open_game_art_explosion(arguments.force)


if __name__ == "__main__":
    main()
