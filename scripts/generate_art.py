#!/usr/bin/env python3
"""Generate the comic-style PNG assets used by DesktopDestruction."""

from __future__ import annotations

import argparse
import math
from collections.abc import Callable
from pathlib import Path

from PIL import Image, ImageDraw


SIZE = 256
SCALE = 4
CANVAS = SIZE * SCALE

OUTLINE = (30, 25, 36, 255)
RED = (239, 68, 68, 255)
DARK_RED = (185, 28, 28, 255)
ORANGE = (249, 115, 22, 255)
YELLOW = (250, 204, 21, 255)
BLUE = (56, 189, 248, 255)
LIGHT_BLUE = (125, 211, 252, 255)
GREEN = (34, 197, 94, 255)
DARK_GREEN = (21, 128, 61, 255)
PURPLE = (168, 85, 247, 255)
GRAY = (107, 114, 128, 255)
LIGHT_GRAY = (203, 213, 225, 255)
WHITE = (255, 255, 255, 255)
SKIN = (255, 224, 178, 255)
BROWN = (120, 72, 24, 255)
DARK_BROWN = (87, 66, 42, 255)


class Art:
    def __init__(self) -> None:
        self.image = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.image, "RGBA")

    @staticmethod
    def _points(points: list[tuple[float, float]]) -> list[tuple[float, float]]:
        return [(x * SCALE, y * SCALE) for x, y in points]

    @staticmethod
    def _box(box: tuple[float, float, float, float]) -> tuple[float, float, float, float]:
        x, y, width, height = box
        return (x * SCALE, y * SCALE, (x + width) * SCALE, (y + height) * SCALE)

    def polygon(
        self,
        points: list[tuple[float, float]],
        fill: tuple[int, int, int, int],
        outline: tuple[int, int, int, int] | None = OUTLINE,
        width: float = 9,
    ) -> None:
        self.draw.polygon(
            self._points(points),
            fill=fill,
            outline=outline,
            width=max(0, int(width * SCALE)),
        )

    def rounded(
        self,
        box: tuple[float, float, float, float],
        radius: float,
        fill: tuple[int, int, int, int],
        outline: tuple[int, int, int, int] | None = OUTLINE,
        width: float = 9,
    ) -> None:
        self.draw.rounded_rectangle(
            self._box(box),
            radius=radius * SCALE,
            fill=fill,
            outline=outline,
            width=max(0, int(width * SCALE)),
        )

    def ellipse(
        self,
        box: tuple[float, float, float, float],
        fill: tuple[int, int, int, int],
        outline: tuple[int, int, int, int] | None = OUTLINE,
        width: float = 9,
    ) -> None:
        self.draw.ellipse(
            self._box(box),
            fill=fill,
            outline=outline,
            width=max(0, int(width * SCALE)),
        )

    def line(
        self,
        points: list[tuple[float, float]],
        fill: tuple[int, int, int, int],
        width: float,
    ) -> None:
        self.draw.line(
            self._points(points),
            fill=fill,
            width=max(1, int(width * SCALE)),
            joint="curve",
        )

    def star(
        self,
        center: tuple[float, float],
        outer: float,
        inner: float,
        points: int,
        rotation: float = 0,
        fill: tuple[int, int, int, int] = YELLOW,
        outline: tuple[int, int, int, int] | None = OUTLINE,
        width: float = 8,
    ) -> None:
        coords: list[tuple[float, float]] = []
        step = 2 * math.pi / points
        for index in range(points):
            outer_angle = rotation + index * step
            inner_angle = outer_angle + step / 2
            coords.append(
                (
                    center[0] + math.cos(outer_angle) * outer,
                    center[1] + math.sin(outer_angle) * outer,
                )
            )
            coords.append(
                (
                    center[0] + math.cos(inner_angle) * inner,
                    center[1] + math.sin(inner_angle) * inner,
                )
            )
        self.polygon(coords, fill=fill, outline=outline, width=width)

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        self.image.resize((SIZE, SIZE), Image.Resampling.LANCZOS).save(path)


def draw_hammer(art: Art) -> None:
    art.line([(128, 30), (128, 154)], OUTLINE, 38)
    art.line([(128, 34), (128, 150)], BROWN, 26)
    art.rounded((48, 132, 160, 64), 28, LIGHT_GRAY)
    art.rounded((64, 156, 128, 20), 10, WHITE, outline=None)
    art.rounded((112, 126, 32, 24), 10, ORANGE)
    art.star((204, 206), 26, 11, 8, fill=YELLOW)


def draw_machine_gun(art: Art) -> None:
    art.polygon(
        [(38, 98), (14, 82), (18, 52), (50, 60), (50, 98)],
        fill=(31, 41, 55, 255),
    )
    art.rounded((36, 102, 140, 54), 20, (55, 65, 81, 255))
    art.rounded((100, 50, 38, 56), 12, ORANGE)
    art.rounded((174, 116, 48, 25), 10, GRAY)
    art.rounded((92, 148, 32, 21), 7, (75, 85, 99, 255))
    art.star((226, 128), 22, 9, 9, fill=YELLOW)


def draw_saw(art: Art) -> None:
    art.ellipse((38, 38, 180, 180), LIGHT_GRAY)
    art.star((128, 128), 101, 79, 24, fill=(15, 23, 42, 255))
    art.ellipse((104, 104, 48, 48), ORANGE)
    art.ellipse((118, 118, 20, 20), (15, 23, 42, 255), outline=None)


def draw_water(art: Art) -> None:
    art.ellipse((34, 72, 80, 104), LIGHT_BLUE)
    art.rounded((50, 90, 124, 74), 30, BLUE)
    art.rounded((176, 114, 46, 25), 9, (51, 65, 85, 255))
    art.rounded((106, 46, 27, 49), 9, (15, 23, 42, 255))
    for point, radius in [((220, 152), 9), ((232, 114), 13), ((208, 84), 9)]:
        art.ellipse(
            (point[0] - radius, point[1] - radius, radius * 2, radius * 2),
            BLUE,
        )


def draw_flame(art: Art) -> None:
    art.polygon(
        [
            (128, 24),
            (158, 66),
            (196, 88),
            (176, 132),
            (188, 170),
            (128, 216),
            (72, 178),
            (84, 132),
            (62, 92),
            (100, 64),
        ],
        fill=ORANGE,
    )
    art.polygon(
        [
            (128, 70),
            (152, 104),
            (170, 126),
            (156, 154),
            (162, 180),
            (128, 202),
            (94, 178),
            (100, 152),
            (88, 126),
            (106, 104),
        ],
        fill=YELLOW,
        width=7,
    )
    art.ellipse((107, 130, 42, 58), WHITE, width=6)


def draw_bomb(art: Art) -> None:
    art.ellipse((66, 40, 124, 30), (0, 0, 0, 42), outline=None)
    art.ellipse((58, 58, 140, 140), (23, 23, 23, 255))
    art.ellipse((76, 138, 46, 30), (255, 255, 255, 72), outline=None)
    art.line([(124, 194), (170, 214)], BROWN, 13)
    art.star((188, 216), 24, 10, 8, fill=YELLOW)


def draw_eraser(art: Art) -> None:
    art.rounded((50, 80, 152, 88), 26, (244, 114, 182, 255))
    art.rounded((50, 122, 152, 44), 20, (59, 130, 246, 255))
    art.star((204, 190), 24, 9, 8, fill=YELLOW)


def draw_rocket(art: Art) -> None:
    art.star((128, 42), 28, 12, 10, fill=YELLOW)
    art.rounded((98, 62, 60, 120), 28, RED)
    art.polygon([(98, 178), (128, 222), (158, 178)], fill=RED)
    art.ellipse((111, 126, 34, 34), BLUE)
    art.polygon([(98, 74), (62, 42), (98, 42)], fill=DARK_RED)
    art.polygon([(158, 74), (194, 42), (158, 42)], fill=DARK_RED)


def draw_fist(art: Art) -> None:
    art.rounded((64, 78, 126, 88), 34, SKIN)
    for index in range(4):
        x = 70 + index * 32
        art.rounded((x, 148, 26, 58), 13, SKIN, width=8)
    art.rounded((42, 108, 34, 62), 17, SKIN, width=8)
    art.ellipse((92, 96, 70, 30), (255, 245, 220, 255), width=7)


def draw_insect(art: Art) -> None:
    art.ellipse((62, 64, 132, 118), GREEN)
    art.ellipse((94, 164, 68, 52), DARK_GREEN)
    for index in range(3):
        y = 78 + index * 34
        art.line([(66, y), (30, y + 18)], OUTLINE, 10)
        art.line([(190, y), (226, y + 18)], OUTLINE, 10)
    art.line([(110, 204), (88, 232)], OUTLINE, 9)
    art.line([(146, 204), (168, 232)], OUTLINE, 9)
    for point in [(106, 118), (150, 118), (128, 88)]:
        art.ellipse((point[0] - 11, point[1] - 11, 22, 22), OUTLINE, outline=None)


def draw_person(art: Art) -> None:
    art.rounded((76, 48, 104, 96), 34, ORANGE)
    art.ellipse((88, 130, 80, 80), SKIN)
    art.ellipse((84, 170, 88, 34), (30, 27, 24, 255))
    art.ellipse((106, 150, 12, 14), OUTLINE, outline=None)
    art.ellipse((138, 150, 12, 14), OUTLINE, outline=None)
    art.line([(112, 140), (144, 140)], OUTLINE, 7)


def draw_vehicle(art: Art) -> None:
    art.rounded((34, 74, 188, 64), 30, RED)
    art.polygon([(76, 138), (96, 184), (160, 184), (180, 138)], fill=DARK_RED)
    art.polygon([(88, 132), (102, 166), (122, 166), (122, 132)], fill=(191, 219, 254, 255), width=7)
    art.polygon([(134, 132), (134, 166), (154, 166), (168, 132)], fill=(191, 219, 254, 255), width=7)
    for center in [(82, 70), (174, 70)]:
        art.ellipse((center[0] - 30, center[1] - 30, 60, 60), OUTLINE, outline=None)
        art.ellipse((center[0] - 12, center[1] - 12, 24, 24), LIGHT_GRAY, width=5)
    art.ellipse((206, 94, 20, 18), YELLOW, width=6)


def draw_animal(art: Art) -> None:
    art.ellipse((78, 58, 100, 78), (180, 83, 9, 255))
    for point in [(68, 148), (106, 174), (150, 174), (188, 148)]:
        art.ellipse((point[0] - 22, point[1] - 26, 44, 52), (180, 83, 9, 255))


def draw_anything(art: Art) -> None:
    art.rounded((60, 60, 136, 136), 30, PURPLE)
    for point in [(94, 94), (162, 94), (128, 128), (94, 162), (162, 162)]:
        art.ellipse((point[0] - 12, point[1] - 12, 24, 24), WHITE, outline=None)


def draw_target(art: Art) -> None:
    art.ellipse((40, 40, 176, 176), RED)
    art.ellipse((67, 67, 122, 122), WHITE)
    art.ellipse((94, 94, 68, 68), RED)
    art.line([(128, 28), (128, 78)], OUTLINE, 10)
    art.line([(128, 178), (128, 228)], OUTLINE, 10)
    art.line([(28, 128), (78, 128)], OUTLINE, 10)
    art.line([(178, 128), (228, 128)], OUTLINE, 10)


def draw_sparkle(art: Art) -> None:
    art.star((128, 128), 100, 38, 8, fill=YELLOW)
    art.ellipse((108, 108, 40, 40), WHITE, width=5)


def draw_restore(art: Art) -> None:
    art.rounded((116, 108, 24, 116), 12, BROWN)
    art.polygon([(84, 112), (172, 112), (190, 48), (66, 48)], fill=YELLOW)
    art.rounded((80, 100, 96, 22), 10, ORANGE)
    for point in [(42, 178), (214, 178), (128, 226)]:
        art.star(point, 17, 7, 8, fill=YELLOW, width=6)


def draw_settings(art: Art) -> None:
    art.star((128, 128), 100, 72, 12, fill=GRAY)
    art.ellipse((88, 88, 80, 80), LIGHT_GRAY)
    art.ellipse((112, 112, 32, 32), OUTLINE, outline=None)


def draw_exit(art: Art) -> None:
    art.line([(68, 68), (188, 188)], OUTLINE, 38)
    art.line([(188, 68), (68, 188)], OUTLINE, 38)
    art.line([(68, 68), (188, 188)], RED, 26)
    art.line([(188, 68), (68, 188)], RED, 26)


def draw_explosion(art: Art) -> None:
    art.star((128, 128), 116, 54, 14, fill=ORANGE)
    art.star((128, 128), 78, 38, 12, fill=YELLOW, width=8)
    art.ellipse((96, 96, 64, 64), WHITE, width=6)


def draw_fire(art: Art) -> None:
    draw_flame(art)


def draw_smoke(art: Art) -> None:
    art.ellipse((44, 82, 82, 72), (107, 114, 128, 230))
    art.ellipse((104, 106, 96, 84), (148, 155, 166, 235))
    art.ellipse((72, 60, 92, 70), (178, 185, 195, 225))


def draw_spark(art: Art) -> None:
    draw_sparkle(art)


def draw_debris(art: Art) -> None:
    art.polygon(
        [(58, 104), (98, 178), (158, 194), (198, 138), (174, 62), (100, 48)],
        fill=DARK_BROWN,
    )
    art.polygon(
        [(100, 158), (140, 172), (164, 134), (134, 112)],
        fill=(146, 114, 74, 255),
        outline=None,
    )


def draw_glass_shard(art: Art) -> None:
    art.polygon(
        [(74, 56), (186, 92), (142, 200), (60, 144)],
        fill=(191, 219, 254, 230),
    )
    art.polygon(
        [(94, 82), (142, 100), (126, 152)],
        fill=(255, 255, 255, 170),
        outline=None,
    )


def draw_water_drop(art: Art) -> None:
    art.polygon(
        [
            (128, 224),
            (76, 132),
            (84, 92),
            (128, 54),
            (172, 92),
            (180, 132),
        ],
        fill=BLUE,
    )
    art.ellipse((88, 98, 28, 46), (255, 255, 255, 160), outline=None)


def draw_muzzle_flash(art: Art) -> None:
    art.star((128, 128), 112, 42, 10, fill=YELLOW)
    art.star((128, 128), 70, 27, 9, fill=WHITE, width=6)


def draw_shockwave(art: Art) -> None:
    art.ellipse((30, 30, 196, 196), (255, 255, 255, 60), outline=(255, 255, 255, 235), width=12)
    art.ellipse((62, 62, 132, 132), None, outline=(255, 255, 255, 100), width=7)


def draw_mushroom_cloud(art: Art) -> None:
    art.rounded((100, 30, 56, 92), 25, GRAY)
    art.ellipse((40, 92, 176, 112), GRAY)
    art.ellipse((66, 128, 124, 52), (178, 185, 195, 255), outline=None)
    art.star((128, 104), 52, 24, 12, fill=ORANGE, width=7)


def draw_blood_splat(art: Art) -> None:
    art.ellipse((52, 74, 152, 108), (185, 28, 28, 235))
    for point, radius in [
        ((44, 176), 18),
        ((92, 202), 16),
        ((150, 208), 20),
        ((204, 178), 17),
        ((220, 122), 14),
        ((200, 68), 16),
        ((58, 62), 13),
    ]:
        art.ellipse(
            (point[0] - radius, point[1] - radius, radius * 2, radius * 2),
            (153, 27, 27, 215),
            outline=None,
        )


def draw_steam(art: Art) -> None:
    art.ellipse((54, 86, 72, 62), (255, 255, 255, 205))
    art.ellipse((112, 108, 84, 70), (255, 255, 255, 225))
    art.ellipse((82, 62, 78, 60), (255, 255, 255, 195))


ASSETS: dict[str, Callable[[Art], None]] = {
    "tool-hammer": draw_hammer,
    "tool-machine-gun": draw_machine_gun,
    "tool-saw": draw_saw,
    "tool-water": draw_water,
    "tool-flame": draw_flame,
    "tool-bomb": draw_bomb,
    "tool-eraser": draw_eraser,
    "tool-rocket": draw_rocket,
    "tool-fist": draw_fist,
    "tool-insect": draw_insect,
    "tool-person": draw_person,
    "tool-vehicle": draw_vehicle,
    "tool-animal": draw_animal,
    "tool-anything": draw_anything,
    "tool-target": draw_target,
    "tool-sparkle": draw_sparkle,
    "ui-restore": draw_restore,
    "ui-settings": draw_settings,
    "ui-exit": draw_exit,
    "effect-explosion": draw_explosion,
    "effect-fire": draw_fire,
    "effect-smoke": draw_smoke,
    "effect-spark": draw_spark,
    "effect-debris": draw_debris,
    "effect-glass-shard": draw_glass_shard,
    "effect-water-drop": draw_water_drop,
    "effect-muzzle-flash": draw_muzzle_flash,
    "effect-shockwave": draw_shockwave,
    "effect-mushroom-cloud": draw_mushroom_cloud,
    "effect-blood-splat": draw_blood_splat,
    "effect-steam": draw_steam,
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "output",
        nargs="?",
        default="Sources/DesktopDestruction/Resources/Art",
        help="Directory in which PNG assets are written",
    )
    args = parser.parse_args()

    output = Path(args.output)
    for name, draw in sorted(ASSETS.items()):
        art = Art()
        draw(art)
        art.save(output / f"{name}.png")
        print(f"Generated {name}.png")


if __name__ == "__main__":
    main()
