# How to maintain ics_vtimezones ?

## Setup
```shell
pip install --upgrade build twine
```
## Release a version
Every time a new version of the Olson database is published, do the following:

Choose a version with 
```shell
./update.sh --list
export VERSION=2023d
```
```shell
rm -rf tmp/tzdata tmp/zoneinfo tmp/tzdata.tar.gz
./update.sh $VERSION
export PACKAGE_VERSION=$(echo "$VERSION" | python -c "import sys; import string; i=sys.stdin.read().strip(); print(f'{i[:4]}.{string.ascii_lowercase.index(i[4])+1}')")
python -m build
python3 -m twine upload dist/*
git commit -a -m "Version $PACKAGE_VERSION"
git tag $PACKAGE_VERSION
git push
git push --tag
```

Please do not skip a version: if time has passed and multiple versions have been created
and ics_vtimezones is lagging behind, please generate and publish all the intermediate versions first.
