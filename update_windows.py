import argparse
import json
import os
from xml.etree.ElementTree import ElementTree

parser = argparse.ArgumentParser()
parser.add_argument("indir")
parser.add_argument("outfile")
parser.add_argument("-n", "--dry_run", action="store_true")
parser.add_argument("-q", "--quiet", action="store_true")
parser.add_argument("-v", "--verbose", action="store_true")

args = parser.parse_args()

sup_windows_zones = ElementTree(file=os.path.join(args.indir, "supplemental", "windowsZones.xml"))
win_mapping = {}
for map_zone in sup_windows_zones.findall('.//windowsZones/mapTimezones/mapZone'):
    if args.verbose:
        print(map_zone.attrib)
    if map_zone.attrib.get('territory') == '001':
        key = map_zone.attrib['other']
        value = map_zone.attrib['type'].split()[0]
        if not args.quiet:
            print(key, value)
        win_mapping[key] = value
if not args.dry_run:
    with open(args.outfile, "wt") as f:
        json.dump(win_mapping, f)
