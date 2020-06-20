import argparse
import itertools
import json
import os
import shutil
import sys

from ics.grammar import string_to_container
from ics.timezone import Timezone


def read_tz(path):
    with open(path, "rt") as f:
        ics_cal = string_to_container(f.read())
        if not (len(ics_cal) == 1 and len(ics_cal[0]) == 3 and ics_cal[0][2].name == "VTIMEZONE"):
            raise ValueError("vTimezone.ics file %s has invalid content" % path)
        return Timezone.from_container(ics_cal[0][2])


def list_files(dir):
    for dp, dn, fs in os.walk(dir):
        for f in fs:
            yield os.path.join(os.path.relpath(dp, dir), f)


parser = argparse.ArgumentParser()
parser.add_argument("new_dir")
parser.add_argument("old_dir")
parser.add_argument("--index")
parser.add_argument("-n", "--dry_run", action="store_true")
parser.add_argument("-q", "--quiet", action="store_true")
parser.add_argument("-v", "--verbose", action="store_true")

args = parser.parse_args()

files = set(itertools.chain(list_files(args.new_dir), list_files(args.old_dir)))
zoneinfo_index = []

for file in files:
    if not file.endswith(".ics"):
        if args.verbose:
            print("Ignoring %s" % file)
        continue

    zoneinfo_index.append(os.path.normpath(file)[:-4])
    new_path = os.path.join(args.new_dir, file)
    old_path = os.path.join(args.old_dir, file)
    if args.verbose:
        print(file, old_path, new_path)

    if not os.path.isfile(new_path):
        print("vTimezone.ics file %s is not present in new dataset" % old_path, file=sys.stderr)
    elif not os.path.isfile(old_path):
        if not args.quiet:
            print("vTimezone.ics file %s is new" % new_path)
        if not args.dry_run:
            shutil.copyfile(new_path, old_path)
    else:
        new_ics = read_tz(new_path)
        old_ics = read_tz(old_path)
        old_tzid, old_modified = old_ics.tzid, old_ics.last_modified
        object.__setattr__(old_ics, "tzid", new_ics.tzid)
        object.__setattr__(old_ics, "last_modified", new_ics.last_modified)
        if old_ics != new_ics:
            if not args.quiet:
                print("vTimezone.ics files %s and %s with TZIDs %s and %s differ"
                      % (old_path, new_path, old_tzid, new_ics.tzid))
            if not args.dry_run:
                shutil.copyfile(new_path, old_path)
        elif args.verbose:
            print("vTimezone.ics files %s and %s with TZIDs %s and %s are the same"
                  % (old_path, new_path, old_tzid, new_ics.tzid))

if args.index:
    with open(args.index, "wt") as f:
        json.dump(zoneinfo_index, f)
