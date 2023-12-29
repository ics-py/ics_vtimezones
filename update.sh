#!/usr/bin/env bash

set -ex

if [ "$1" == "" ]; then
    echo "Version required"
    exit 1
fi


update_zoneinfo=$(realpath ./update_zoneinfo.py)
update_windows=$(realpath ./update_windows.py)

mkdir -p ./tmp/vzic
mkdir -p ./tmp/cldr
tmp_vzic=$(realpath ./tmp/vzic)
tmp_cldr=$(realpath ./tmp/cldr)

sed -i .bak 's#^version\s*=.*$#version = "'$1'"#' pyproject.toml

pushd "src/ics_vtimezones"
echo -e 'VERSION = "'$1'"\nBUILTIN_TZID_PREFIX = "/ics.py/"\nTZID_PREFIX = "/ics.py/'$1'/"' > "__config__.py"
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
curl -R ftp://ftp.iana.org/tz/tzdata-latest.tar.gz -o tzdata-latest.tar.gz
mkdir tzdata
pushd tzdata
tar -xf ../tzdata-latest.tar.gz
popd
sed -i .bak 's#^OLSON_DIR\s*=.*$#OLSON_DIR = tzdata#' Makefile
sed -i .bak 's#^PRODUCT_ID\s*=.*$#PRODUCT_ID = ics.py - http://git.io/lLljaA - vTimezone.ics#' Makefile
sed -i .bak 's#^TZID_PREFIX\s*=.*$#TZID_PREFIX = /ics.py/'$1'/#' Makefile
make -B
./vzic --olson-dir tzdata
python3 "$update_zoneinfo" "$tmp_vzic/zoneinfo" "$zoneinfo_dir" --index="$zoneinfo_index"
popd


pushd "$tmp_cldr"
cldr_tag=$(curl https://api.github.com/repos/unicode-org/cldr/releases/latest | jq ".tag_name" -r)
curl "https://raw.githubusercontent.com/unicode-org/cldr/$cldr_tag/common/supplemental/windowsZones.xml" -o windowsZones.xml
python3 "$update_windows" "$tmp_cldr/windowsZones.xml" "$windows_zone_mapping"
popd

popd
