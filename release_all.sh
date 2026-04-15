#!/usr/bin/env bash

set -e

DRY_RUN=false

for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

# Get current version from pyproject.toml
CURRENT_VERSION=$(grep '#VCHANGE' pyproject.toml | grep -oE '[0-9]+\.[0-9]+')
echo "Current package version: $CURRENT_VERSION"

# Fetch all available Olson versions
ALL_VERSIONS=$(curl -s https://data.iana.org/time-zones/releases/ | grep -oE "tzdata[0-9]{4}[a-z]" | sed 's/tzdata//' | sort -u)

# Convert current package version back to Olson version for comparison
CURRENT_YEAR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
CURRENT_MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
CURRENT_LETTER=$(python3 -c "import string; print(string.ascii_lowercase[$CURRENT_MINOR - 1])")
CURRENT_OLSON="${CURRENT_YEAR}${CURRENT_LETTER}"
echo "Current Olson version: $CURRENT_OLSON"

# Filter to only versions after the current one
MISSING_VERSIONS=()
FOUND_CURRENT=false
for v in $ALL_VERSIONS; do
    if [ "$v" = "$CURRENT_OLSON" ]; then
        FOUND_CURRENT=true
        continue
    fi
    if $FOUND_CURRENT; then
        MISSING_VERSIONS+=("$v")
    fi
done

if [ ${#MISSING_VERSIONS[@]} -eq 0 ]; then
    echo "Already up to date!"
    exit 0
fi

echo "Versions to release: ${MISSING_VERSIONS[*]}"
echo "Total: ${#MISSING_VERSIONS[@]} versions"

if $DRY_RUN; then
    echo "(dry run — exiting)"
    exit 0
fi

echo ""
read -p "Proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

for VERSION in "${MISSING_VERSIONS[@]}"; do
    PACKAGE_VERSION=$(echo "$VERSION" | python3 -c "import sys; import string; i=sys.stdin.read().strip(); print(f'{i[:4]}.{string.ascii_lowercase.index(i[4])+1}')")
    echo ""
    echo "========================================"
    echo "Building $VERSION (package $PACKAGE_VERSION)"
    echo "========================================"

    # Clean previous build artifacts
    rm -rf tmp/vzic tmp/cldr dist/

    # Run update
    ./update.sh "$VERSION"

    # Build
    python3 -m build

    # Commit and tag
    git add -A
    git commit -m "Version $PACKAGE_VERSION"
    git tag "$PACKAGE_VERSION"

    echo "Done: $PACKAGE_VERSION"
done

echo ""
echo "========================================"
echo "All ${#MISSING_VERSIONS[@]} versions released!"
echo "Don't forget to push:"
echo "  git push && git push --tags"
echo "========================================"
