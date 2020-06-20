import json
from os import PathLike
from pathlib import Path
from typing import Dict, Optional, List

import importlib_resources  # type: ignore

from .__config__ import *

__all__ = ["PACKAGE_DIR", "ZONEINFO_DIR", "WINDOWS_ZONE_MAPPING", "ZONEINFO_LIST",
           "windows_to_olson", "is_vtimezone_ics_file", "find_vtimezone_ics_file",
           "VERSION", "BUILTIN_TZID_PREFIX", "TZID_PREFIX"]

PACKAGE_DIR: Path = importlib_resources.files(__name__)
ZONEINFO_DIR: Path = PACKAGE_DIR.joinpath("data/zoneinfo")
with PACKAGE_DIR.joinpath("data/windows_zone_mapping.json").open("rt") as f:
    WINDOWS_ZONE_MAPPING: Dict[str, str] = json.load(f)
with PACKAGE_DIR.joinpath("data/zoneinfo_index.json").open("rt") as f:
    ZONEINFO_LIST: List[Path] = json.load(f)


def windows_to_olson(win: str) -> Optional[str]:
    return WINDOWS_ZONE_MAPPING.get(win, None)


def is_vtimezone_ics_file(file: Path) -> bool:
    return file.exists() and file.is_file() and file.name.endswith(".ics")


def find_vtimezone_ics_file(file_path: PathLike, root_dir: Optional[Path] = ZONEINFO_DIR) -> Optional[Path]:
    if not isinstance(file_path, Path):
        file_path = Path(file_path)
    parts = file_path.parts
    for i in range(len(parts)):
        file = root_dir.joinpath("/".join(parts[i:]) + ".ics")
        if root_dir in file.parents and is_vtimezone_ics_file(file):
            return file
    return None
