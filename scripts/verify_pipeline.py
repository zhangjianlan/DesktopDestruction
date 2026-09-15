#!/usr/bin/env python3
"""Drive one hammer hit, restore, and double-escape on the running overlay."""

import ctypes
import sys
import time


class CGPoint(ctypes.Structure):
    _fields_ = [("x", ctypes.c_double), ("y", ctypes.c_double)]


class CGRect(ctypes.Structure):
    _fields_ = [("origin", CGPoint), ("size", CGPoint)]


core_graphics = ctypes.CDLL("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")
core_graphics.CGMainDisplayID.restype = ctypes.c_uint32
core_graphics.CGDisplayBounds.argtypes = [ctypes.c_uint32]
core_graphics.CGDisplayBounds.restype = CGRect
core_graphics.CGEventCreateMouseEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint32, CGPoint, ctypes.c_uint32]
core_graphics.CGEventCreateMouseEvent.restype = ctypes.c_void_p
core_graphics.CGEventCreateKeyboardEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint16, ctypes.c_bool]
core_graphics.CGEventCreateKeyboardEvent.restype = ctypes.c_void_p
core_graphics.CGEventPost.argtypes = [ctypes.c_uint32, ctypes.c_void_p]


def post(event):
    core_graphics.CGEventPost(0, event)


def mouse_event(event_type, point):
    event = core_graphics.CGEventCreateMouseEvent(None, event_type, point, 0)
    if not event:
        raise RuntimeError("CGEventCreateMouseEvent failed")
    post(event)


def key_event(keycode, down):
    event = core_graphics.CGEventCreateKeyboardEvent(None, keycode, down)
    if not event:
        raise RuntimeError("CGEventCreateKeyboardEvent failed")
    post(event)


display = core_graphics.CGMainDisplayID()
bounds = core_graphics.CGDisplayBounds(display)
center = CGPoint(bounds.origin.x + bounds.size.x / 2, bounds.origin.y + bounds.size.y / 2)
print(f"clicking screen center {center.x:.1f},{center.y:.1f}")

mouse_event(5, center)
time.sleep(0.1)
mouse_event(1, center)
time.sleep(0.08)
mouse_event(2, center)
time.sleep(float(sys.argv[1]) if len(sys.argv) > 1 else 0.4)

key_event(15, True)
time.sleep(0.05)
key_event(15, False)
time.sleep(float(sys.argv[2]) if len(sys.argv) > 2 else 0.4)

for _ in range(2):
    key_event(53, True)
    time.sleep(0.05)
    key_event(53, False)
    time.sleep(0.12)
