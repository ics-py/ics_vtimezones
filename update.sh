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

sed -i 's#^version\s*=.*$#version = "$1"#' pyproject.toml

pushd "src/ics_vtimezone"
echo 'VERSION = "$1"\nBUILTIN_TZID_PREFIX = "/ics.py/"\nTZID_PREFIX = "/ics.py/$1/"' > "__config__.py"
mkdir -p ./data

touch ./data/windows_zone_mapping.json
windows_zone_mapping=$(realpath ./data/windows_zone_mapping.json)

touch ./data/zoneinfo_index.json
zoneinfo_index=$(realpath ./data/zoneinfo_index.json)

mkdir -p ./data/zoneinfo/
zoneinfo_dir=$(realpath ./data/zoneinfo/)


git clone https://github.com/libical/vzic.git "$tmp_vzic"
pushd "$tmp_vzic"
rm -rf ./tzdata*
curl -R ftp://ftp.iana.org/tz/tzdata-latest.tar.gz -o tzdata-latest.tar.gz
mkdir tzdata
pushd tzdata
tar -xaf ../tzdata-latest.tar.gz
popd
sed -i 's#^OLSON_DIR\s*=.*$#OLSON_DIR = tzdata#' Makefile
sed -i 's#^PRODUCT_ID\s*=.*$#PRODUCT_ID = ics.py - http://git.io/lLljaA - vTimezone.ics#' Makefile
sed -i 's#^TZID_PREFIX\s*=.*$#TZID_PREFIX = /ics.py/$1/#' Makefile
make -B
./vzic
python3 "$update_zoneinfo" "$tmp_vzic/zoneinfo" "$zoneinfo_dir" --index="$zoneinfo_index"
popd


#cldr_url=$(curl https://api.github.com/repos/unicode-org/cldr/releases/latest | jq ".zipball_url" -r)
pushd "$tmp_cldr"
curl "https://unicode.org/Public/cldr/37/core.zip" -o core.zip
rm -rf ./common
unzip core.zip
python3 "$update_windows" "$tmp_dir/common" "$windows_zone_mapping"
popd

popd
