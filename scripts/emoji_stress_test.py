#!/usr/bin/env python3
"""Stress the Anything-emoji tool through the real overlay UI."""

import argparse
import ctypes
import random
import time


class CGPoint(ctypes.Structure):
    _fields_ = [("x", ctypes.c_double), ("y", ctypes.c_double)]


class CGRect(ctypes.Structure):
    _fields_ = [("origin", CGPoint), ("size", CGPoint)]


core_graphics = ctypes.CDLL(
    "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics"
)
core_graphics.CGMainDisplayID.restype = ctypes.c_uint32
core_graphics.CGDisplayBounds.argtypes = [ctypes.c_uint32]
core_graphics.CGDisplayBounds.restype = CGRect
core_graphics.CGEventCreateMouseEvent.argtypes = [
    ctypes.c_void_p,
    ctypes.c_uint32,
    CGPoint,
    ctypes.c_uint32,
]
core_graphics.CGEventCreateMouseEvent.restype = ctypes.c_void_p
core_graphics.CGEventCreateKeyboardEvent.argtypes = [
    ctypes.c_void_p,
    ctypes.c_uint16,
    ctypes.c_bool,
]
core_graphics.CGEventCreateKeyboardEvent.restype = ctypes.c_void_p
core_graphics.CGEventKeyboardSetUnicodeString.argtypes = [
    ctypes.c_void_p,
    ctypes.c_ulong,
    ctypes.POINTER(ctypes.c_uint16),
]
core_graphics.CGEventSetFlags.argtypes = [ctypes.c_void_p, ctypes.c_uint64]
core_graphics.CGEventPost.argtypes = [ctypes.c_uint32, ctypes.c_void_p]
core_graphics.CGEventPostToPid.argtypes = [ctypes.c_int, ctypes.c_void_p]

COMMAND_FLAG = 1 << 20
TARGET_PID = None


def post_event(event):
    if TARGET_PID is None:
        core_graphics.CGEventPost(0, event)
    else:
        core_graphics.CGEventPostToPid(TARGET_PID, event)


def keyboard_event(keycode, down, flags=0):
    event = core_graphics.CGEventCreateKeyboardEvent(None, keycode, down)
    if not event:
        raise RuntimeError("CGEventCreateKeyboardEvent failed")
    if flags:
        core_graphics.CGEventSetFlags(event, flags)
    return event


def press_key(keycode, flags=0):
    post_event(keyboard_event(keycode, True, flags))
    time.sleep(0.04)
    post_event(keyboard_event(keycode, False, flags))
    time.sleep(0.04)


def type_text(text, chunk_size=24):
    for offset in range(0, len(text), chunk_size):
        chunk = text[offset : offset + chunk_size]
        encoded = chunk.encode("utf-16-le")
        length = len(encoded) // 2
        buffer = (ctypes.c_uint16 * length).from_buffer_copy(encoded)

        for down in (True, False):
            event = keyboard_event(0, down)
            core_graphics.CGEventKeyboardSetUnicodeString(event, length, buffer)
            post_event(event)
            time.sleep(0.015)
        time.sleep(0.02)


def mouse_event(event_type, point):
    event = core_graphics.CGEventCreateMouseEvent(
        None, event_type, point, 0
    )
    if not event:
        raise RuntimeError("CGEventCreateMouseEvent failed")
    post_event(event)


def click(point):
    mouse_event(5, point)
    time.sleep(0.015)
    mouse_event(1, point)
    time.sleep(0.015)
    mouse_event(2, point)
    time.sleep(0.015)


def default_emoji_text():
    codepoints = []
    codepoints.extend(range(0x1F600, 0x1F64F))
    codepoints.extend(range(0x1F40C, 0x1F42F))
    codepoints.extend(range(0x1F680, 0x1F6A8))
    codepoints.extend(range(0x1F330, 0x1F350))
    return "".join(chr(codepoint) for codepoint in codepoints)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--clicks", type=int, default=260)
    parser.add_argument("--emoji", default=default_emoji_text())
    parser.add_argument("--seed", type=int, default=1509)
    parser.add_argument(
        "--pid",
        type=int,
        help="Post events to this process instead of the foreground app",
    )
    parser.add_argument(
        "--skip-setup",
        action="store_true",
        help="Assume the app was launched with DD_STRESS_EMOJI already set",
    )
    parser.add_argument(
        "--keep-open",
        action="store_true",
        help="Do not restore the desktop or ask the app to quit",
    )
    parser.add_argument(
        "--fixed-point",
        help="Click this x,y coordinate instead of random screen points",
    )
    args = parser.parse_args()
    globals()["TARGET_PID"] = args.pid

    random.seed(args.seed)
    fixed_point = None
    if args.fixed_point:
        parts = [part.strip() for part in args.fixed_point.split(",")]
        if len(parts) != 2:
            raise SystemExit("--fixed-point must look like x,y")
        fixed_point = CGPoint(float(parts[0]), float(parts[1]))
    display = core_graphics.CGMainDisplayID()
    bounds = core_graphics.CGDisplayBounds(display)
    print(f"emoji_count={len(args.emoji)} clicks={args.clicks}")

    if not args.skip_setup:
        # E selects the Anything-emoji tool. Cmd+A replaces the sample field value.
        press_key(14)
        time.sleep(0.35)
        press_key(0, COMMAND_FLAG)
        type_text(args.emoji)
        press_key(36)
        time.sleep(0.25)

    for index in range(args.clicks):
        point = fixed_point or CGPoint(
            x=bounds.origin.x + bounds.size.x * random.uniform(0.12, 0.88),
            y=bounds.origin.y + bounds.size.y * random.uniform(0.22, 0.78),
        )
        click(point)
        if (index + 1) % 40 == 0:
            print(f"placed_clicks={index + 1}")

    print("waiting_for_simulation")
    time.sleep(3)

    if not args.keep_open:
        press_key(15)  # R restores the captured background.
        time.sleep(0.8)
        press_key(53)
        time.sleep(0.16)
        press_key(53)
    print("stress_sequence_complete")


if __name__ == "__main__":
    main()
