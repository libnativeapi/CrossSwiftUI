#!/usr/bin/env python3
"""Exercise the installed APK through Android's accessibility tree and touch input."""

import os
from pathlib import Path
import re
import subprocess
import time
from xml.etree import ElementTree


SDK = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
ADB = str(Path(SDK) / "platform-tools" / "adb") if SDK else "adb"
PACKAGE = "dev.swiftuiport.android.counter"
DUMP = "/data/local/tmp/swiftuiport-counter.xml"


def adb(*args):
    return subprocess.check_output([ADB, *args], encoding="utf-8", timeout=30)


def find(text, *, clickable=False):
    for _ in range(5):
        adb("shell", "uiautomator", "dump", DUMP)
        tree = ElementTree.fromstring(adb("exec-out", "cat", DUMP))
        nodes = [node for node in tree.iter("node") if node.get("package") == PACKAGE]
        if any(node.get("class") == "androidx.compose.ui.platform.ComposeView" for node in nodes):
            for node in nodes:
                if clickable and node.get("clickable") != "true":
                    continue
                # Compose can expose a button's label as a child of the clickable semantics node.
                labels = node.iter("node") if clickable else (node,)
                if any(label.get("text") == text for label in labels):
                    return node
        time.sleep(0.25)
    raise AssertionError(f"Compose {'button' if clickable else 'label'} {text!r} did not appear")


def tap(text):
    node = find(text, clickable=True)
    left, top, right, bottom = map(int, re.findall(r"-?\d+", node.attrib["bounds"]))
    assert right > left and bottom > top, text
    adb("shell", "input", "tap", str((left + right) // 2), str((top + bottom) // 2))


def check_count(value):
    find(f"Count: {value}")


def main():
    adb("shell", "am", "start", "-W", "-S", "-n", f"{PACKAGE}/.CounterActivity")
    check_count(0)
    tap("Increment")
    check_count(1)
    tap("Increment")
    check_count(2)
    tap("Reset")
    check_count(0)
    print("Android Counter passed: 0 → 1 → 2 → 0")


if __name__ == "__main__":
    main()
