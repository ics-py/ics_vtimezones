#!/usr/bin/env bash

set -e

if [ "$1" == "" ]
then
    echo "Usage:"
    echo "    $0 OLSON_VERSION"
    echo ""
    echo "Please specify the version of the Olson database you want to use."
    echo "Use --list to list available versions"
    exit 1
elif [ "$1" == "--list" ]
then
  VERSIONS=$(curl ftp://ftp.iana.org/tz/ --list-only --silent | grep -E "tzdb-\d{4}\w" | sed s/tzdb-// | sort -r)
  LATEST=$(echo "$VERSIONS" | head -n 1)
  echo "Latest version: $LATEST"
  echo "Available versions of the Olson database:"
  echo "$VERSIONS" | column
  exit 0
fi

OLSON_VERSION=$1
OLSON_URL=ftp://ftp.iana.org/tz/releases/tzdata$OLSON_VERSION.tar.gz

if curl -I "$OLSON_URL" --silent
then
    echo "Generating the ics_vtimezones package with Olson version $OLSON_VERSION"
else
    echo "Version $OLSON_VERSION of the Olson database does not exist"
    exit 2
fi

PACKAGE_VERSION=$(echo "$OLSON_VERSION" | python -c "import sys; import string; i=sys.stdin.read().strip(); print(f'{i[:4]}.{string.ascii_lowercase.index(i[4])+1}')")
echo "Python package version will be ics_vtimezones==$PACKAGE_VERSION"
echo "============================"
echo ""
echo ""

update_zoneinfo=$(realpath ./update_zoneinfo.py)
update_windows=$(realpath ./update_windows.py)

mkdir -p ./tmp/vzic
mkdir -p ./tmp/cldr
tmp_vzic=$(realpath ./tmp/vzic)
tmp_cldr=$(realpath ./tmp/cldr)

sed -i "" 's#^version\s*=.*$#version = "'$PACKAGE_VERSION'"#' pyproject.toml

pushd "src/ics_vtimezones"
echo -e 'VERSION = "'$PACKAGE_VERSION'"\nBUILTIN_TZID_PREFIX = "/ics.py/"\nTZID_PREFIX = "/ics.py/'$PACKAGE_VERSION'/"' > "__config__.py"
mkdir -p ./data

touch ./data/windows_zone_mapping.json
windows_zone_mapping=$(realpath ./data/windows_zone_mapping.json)

touch ./data/zoneinfo_index.json
zoneinfo_index=$(realpath ./data/zoneinfo_index.json)

mkdir -p ./data/zoneinfo/
zoneinfo_dir=$(realpath ./data/zoneinfo/)


git clone https://github.com/libical/vzic.git "$tmp_vzic" || echo "$tmp_vzic already exists"
pushd "$tmp_vzic"
rm -rf ./tzdata*
curl -R $OLSON_URL -o tzdata.tar.gz
mkdir tzdata
pushd tzdata
tar -xf ../tzdata.tar.gz
popd
make -B PRODUCT_ID="ics.py - http://git.io/lLljaA - iCal vTZ" TZID_PREFIX=/ics.py/$PACKAGE_VERSION/
./vzic --olson-dir tzdata
python3 "$update_zoneinfo" "$tmp_vzic/zoneinfo" "$zoneinfo_dir" --index="$zoneinfo_index"
popd


pushd "$tmp_cldr"
cldr_tag=$(curl https://api.github.com/repos/unicode-org/cldr/releases/latest | jq ".tag_name" -r)
curl "https://raw.githubusercontent.com/unicode-org/cldr/$cldr_tag/common/supplemental/windowsZones.xml" -o windowsZones.xml
python3 "$update_windows" "$tmp_cldr/windowsZones.xml" "$windows_zone_mapping"
popd

popd
