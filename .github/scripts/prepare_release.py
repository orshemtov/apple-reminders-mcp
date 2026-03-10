#!/usr/bin/env python3

# pyright: reportMissingImports=false

import argparse
import os
import re
from pathlib import Path

import semver


VERSION_PATTERN = re.compile(r'public static let version = "([^"]+)"')


def write_output(name: str, value: str) -> None:
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return
    with open(output_path, "a", encoding="utf-8") as handle:
        handle.write(f"{name}={value}\n")


def read_version(build_info_path: Path) -> str:
    match = VERSION_PATTERN.search(build_info_path.read_text(encoding="utf-8"))
    if not match:
        raise SystemExit("Could not find version in BuildInfo.swift")
    return match.group(1)


def bump_version(version: str, release_type: str) -> str:
    parsed = semver.Version.parse(version)
    if release_type == "patch":
        return str(parsed.bump_patch())
    if release_type == "minor":
        return str(parsed.bump_minor())
    if release_type == "major":
        return str(parsed.bump_major())
    raise SystemExit(f"Unsupported release type: {release_type}")


def update_build_info(build_info_path: Path, version: str) -> None:
    content = build_info_path.read_text(encoding="utf-8")
    updated = VERSION_PATTERN.sub(
        f'public static let version = "{version}"',
        content,
        count=1,
    )
    build_info_path.write_text(updated, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--event-name", required=True)
    parser.add_argument("--ref-name", required=True)
    parser.add_argument("--release-type")
    parser.add_argument("--build-info", required=True)
    args = parser.parse_args()

    build_info_path = Path(args.build_info)

    if args.event_name == "push":
        tag = args.ref_name
        version = tag.removeprefix("v")
        write_output("tag", tag)
        write_output("version", version)
        write_output("should_commit", "false")
        return

    current_version = read_version(build_info_path)
    new_version = bump_version(current_version, args.release_type or "patch")
    new_tag = f"v{new_version}"

    update_build_info(build_info_path, new_version)

    write_output("tag", new_tag)
    write_output("version", new_version)
    write_output("should_commit", "true")


if __name__ == "__main__":
    main()
