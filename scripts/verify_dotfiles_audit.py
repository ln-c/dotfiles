
#!/usr/bin/env python3
"""Verify repository-audit claims without modifying project files."""

from pathlib import Path
import re
import subprocess
import sys

COMPONENT_DIRS = (
    ".config/hypr",
    ".config/waybar",
    ".config/foot",
    ".config/wallust",
    ".scripts",
    "scripts",
    ".themes",
)

CANDIDATE_PATHS = (
    "install.sh",
    ".scripts/install.sh",
    "scripts/install.sh",
    ".config/hypr/hyprland.conf",
    ".config/waybar/config",
    ".config/waybar/config.json",
    ".config/waybar/config.jsonc",
    ".config/foot/foot.ini",
    ".config/foot/foot.conf",
    ".config/wallust/wallust.toml",
    ".config/wallust/config.toml",
    ".config/wallust/config.lua",
)

README_PATTERN = re.compile(
    r"install\.sh|wallust|hyprland\.conf|foot\.conf|"
    r"config\.jsonc?|waybar|pywal|\{color0\}",
    re.IGNORECASE,
)

RELEVANT_SUFFIXES = {
    ".conf", ".ini", ".toml", ".lua", ".json", ".jsonc",
    ".css", ".sh", ".yaml", ".yml",
}


def git_output(root: Path, *args: str) -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return []
    return result.stdout.splitlines()


def main() -> int:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        print("ERROR: Run this script inside a Git repository.")
        return 1

    root = Path(result.stdout.strip()).resolve()
    tracked = set(git_output(root, "ls-files"))

    print(f"Repository: {root}")

    print("\n=== Git status ===")
    status = git_output(root, "status", "--short")
    print("\n".join(status) if status else "Working tree has no reported changes.")

    print("\n=== Expected paths ===")
    for relative in CANDIDATE_PATHS:
        path = root / relative
        state = "EXISTS" if path.exists() else "MISSING"
        tracked_state = "tracked" if relative in tracked else "not tracked"
        print(f"{state:7} | {tracked_state:11} | {relative}")

    print("\n=== Component directories and config files ===")
    for relative in COMPONENT_DIRS:
        directory = root / relative
        print(f"\n[{relative}]")
        if not directory.is_dir():
            print("  Directory not found")
            continue

        files = sorted(
            path for path in directory.rglob("*")
            if path.is_file()
            and ".git" not in path.parts
            and path.suffix.lower() in RELEVANT_SUFFIXES
        )

        if files:
            for path in files:
                rel = path.relative_to(root).as_posix()
                state = "tracked" if rel in tracked else "untracked/ignored"
                print(f"  {rel} [{state}]")
        else:
            print("  No matching config or script files found")

    print("\n=== Shell scripts in working tree ===")
    scripts = sorted(
        path for path in root.rglob("*.sh")
        if path.is_file() and ".git" not in path.parts
    )
    if scripts:
        for path in scripts:
            print(f"  {path.relative_to(root).as_posix()}")
    else:
        print("  No shell scripts found")

    print("\n=== Relevant README evidence ===")
    readme = root / "README.md"
    if not readme.is_file():
        print("README.md not found")
    else:
        lines = readme.read_text(
            encoding="utf-8", errors="replace"
        ).splitlines()
        matches = [
            (number, line.strip())
            for number, line in enumerate(lines, start=1)
            if README_PATTERN.search(line)
        ]
        for number, line in matches:
            print(f"  README.md:{number}: {line}")

    print("\n=== Verification limits ===")
    print("- This script does not execute any repository scripts.")
    print("- Missing candidate names do not prove a component is broken.")
    print("- Untracked or ignored files may need separate review.")
    print("- File presence does not prove runtime behavior.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
