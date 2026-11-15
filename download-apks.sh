#!/usr/bin/env bash
# Download the APKs of this setup into apks/ (ignored by git).
# F-Droid apps: the version that F-Droid suggests, checked against the SHA-256 in the F-Droid index.
# Magisk: GitHub release. It gives root: it patches boot-docker.img (docs/02).
# Total Commander is not on F-Droid: get it from https://www.ghisler.com/android.htm
set -euo pipefail

cd "$(dirname "$0")"
OUT=apks
FDROID_APPS=(mattecarra.accapp org.fdroid.fdroid)
MAGISK_TAG=v31.1
MAGISK_APK=Magisk-v31.1.apk

for cmd in curl jq sha256sum; do
    command -v "$cmd" >/dev/null || { echo "ERROR: $cmd is required"; exit 1; }
done
mkdir -p "$OUT"

# check_sha256 <file in $OUT> <expected sha256>: delete the file and stop when it does not match
check_sha256() {
    if [ -z "$2" ] || ! echo "$2  $1" | (cd "$OUT" && sha256sum -c --quiet); then
        rm -f "$OUT/$1"
        echo "ERROR: SHA-256 of $1 does not match the published value"
        exit 1
    fi
    echo "ok  $1"
}

echo "=== F-Droid index (about 75 MB) ==="
INDEX="$OUT/.index-v2.json"
curl -fsSL https://f-droid.org/repo/index-v2.json -o "$INDEX"

for pkg in "${FDROID_APPS[@]}"; do
    code=$(curl -fsSL "https://f-droid.org/api/v1/packages/$pkg" | jq -r .suggestedVersionCode)
    file="${pkg}_${code}.apk"
    want=$(jq -r --arg p "$pkg" --arg f "/$file" '.packages[$p].versions[] | select(.file.name == $f) | .file.sha256' "$INDEX")
    curl -fsSL "https://f-droid.org/repo/$file" -o "$OUT/$file"
    check_sha256 "$file" "$want"
done
rm -f "$INDEX"

echo "=== Magisk $MAGISK_TAG (GitHub) ==="
want=$(curl -fsSL "https://api.github.com/repos/topjohnwu/Magisk/releases/tags/$MAGISK_TAG" \
    | jq -r --arg n "$MAGISK_APK" '.assets[] | select(.name == $n) | .digest // empty' | sed 's/^sha256://')
curl -fsSL "https://github.com/topjohnwu/Magisk/releases/download/$MAGISK_TAG/$MAGISK_APK" -o "$OUT/$MAGISK_APK"
check_sha256 "$MAGISK_APK" "$want"

(cd "$OUT" && sha256sum ./*.apk > SHA256SUMS)
echo "=== Done: $OUT/ ==="
