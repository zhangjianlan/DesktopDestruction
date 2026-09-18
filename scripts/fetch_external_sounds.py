#!/usr/bin/env python3

import argparse
import shutil
import subprocess
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CACHE_DIR = ROOT / ".cache" / "sounds"

KENNEY_PACKAGES = {
    "impact": (
        "https://kenney.nl/media/pages/assets/impact-sounds/"
        "87b4ddecda-1677589768/kenney_impact-sounds.zip",
        "Kenney-Impact-Sounds-License.txt",
    ),
    "scifi": (
        "https://kenney.nl/media/pages/assets/sci-fi-sounds/"
        "6b296f9ecf-1677589334/kenney_sci-fi-sounds.zip",
        "Kenney-Sci-Fi-Sounds-License.txt",
    ),
    "interface": (
        "https://kenney.nl/media/pages/assets/interface-sounds/"
        "fa43c1dd4d-1677589452/kenney_interface-sounds.zip",
        "Kenney-Interface-Sounds-License.txt",
    ),
}

SAMPLES = {
    "impact_glass_heavy": ("impact", "Audio/impactGlass_heavy_000.ogg"),
    "impact_metal_light": ("impact", "Audio/impactMetal_light_000.ogg"),
    "impact_metal_heavy": ("impact", "Audio/impactMetal_heavy_000.ogg"),
    "impact_wood_heavy": ("impact", "Audio/impactWood_heavy_003.ogg"),
    "impact_punch_heavy": ("impact", "Audio/impactPunch_heavy_000.ogg"),
    "impact_punch_medium": ("impact", "Audio/impactPunch_medium_000.ogg"),
    "impact_soft_medium": ("impact", "Audio/impactSoft_medium_000.ogg"),
    "explosion_crunch": ("scifi", "Audio/explosionCrunch_000.ogg"),
    "explosion_low": ("scifi", "Audio/lowFrequency_explosion_000.ogg"),
    "explosion_crunch_long": ("scifi", "Audio/explosionCrunch_004.ogg"),
    "explosion_crunch_medium": ("scifi", "Audio/explosionCrunch_003.ogg"),
    "explosion_low_short": ("scifi", "Audio/lowFrequency_explosion_001.ogg"),
    "thruster_fire": ("scifi", "Audio/thrusterFire_000.ogg"),
    "slime": ("scifi", "Audio/slime_000.ogg"),
    "switch": ("interface", "Audio/switch_001.ogg"),
    "tick": ("interface", "Audio/scroll_001.ogg"),
}


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


def install_package(name: str, url: str, license_name: str, force: bool) -> None:
    archive_path = CACHE_DIR / f"{name}.zip"
    package_dir = CACHE_DIR / name
    if force or not archive_path.exists():
        archive_path.write_bytes(download(url))
    package_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive_path) as archive:
        archive.extractall(package_dir)

    license_source = package_dir / "License.txt"
    license_target = ROOT / "THIRD_PARTY_LICENSES" / license_name
    if license_source.exists():
        license_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(license_source, license_target)


def convert_sample(source: Path, target: Path, force: bool) -> None:
    if target.exists() and not force:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "ffmpeg",
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-i",
            str(source),
            "-vn",
            "-ac",
            "1",
            "-ar",
            "44100",
            "-c:a",
            "pcm_s16le",
            str(target),
        ],
        check=True,
    )


def ensure_external_samples(force: bool = False) -> dict[str, Path]:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    for name, (url, license_name) in KENNEY_PACKAGES.items():
        install_package(name, url, license_name, force)

    result: dict[str, Path] = {}
    for stem, (package, member) in SAMPLES.items():
        source = CACHE_DIR / package / member
        target = CACHE_DIR / f"{stem}.wav"
        if not source.exists():
            raise FileNotFoundError(f"missing external sound sample: {source}")
        convert_sample(source, target, force)
        result[stem] = target
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true")
    arguments = parser.parse_args()
    samples = ensure_external_samples(force=arguments.force)
    print(f"Fetched {len(samples)} external sound samples into {CACHE_DIR}")


if __name__ == "__main__":
    main()
