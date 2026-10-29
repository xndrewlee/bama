#!/bin/zsh
# Creates a new iPhone app from the template next to this script.
# Usage: new-app.sh <AppName> <bundle-id> [parent-folder]
#   new-app.sh Reader com.yourname.reader ~/Developer
# Creates <parent-folder>/<AppName>. If that folder exists, it must not have a
# project.yml yet; existing files (like docs/BRIEF.md) are kept.
# AppName must be one word in UpperCamelCase (letters and digits only).
set -euo pipefail
name=${1:?usage: new-app.sh <AppName> <bundle-id> [parent-folder]}
bundle=${2:?usage: new-app.sh <AppName> <bundle-id> [parent-folder]}
parent=${3:-$PWD}
[[ "$name" =~ ^[A-Z][A-Za-z0-9]*$ ]] || { echo "AppName must be UpperCamelCase letters and digits, like Reader or DailyLog"; exit 1; }
[[ "$bundle" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]] || { echo "bundle id must be reverse DNS, like com.yourname.reader"; exit 1; }
template=${0:A:h:h}/template
dest="$parent/$name"
# An existing folder is fine if it has no project yet (for example only docs/BRIEF.md).
[[ ! -e "$dest/project.yml" ]] || { echo "$dest already has a project.yml"; exit 1; }

mkdir -p "$dest"
# Keep files that are already there. Not `cp -n`: on macOS it exits 1 when it
# skips a file, and set -e then stops the script halfway.
rsync -a --ignore-existing "$template/" "$dest/"
# A kept .gitignore gets the template lines it lacks.
if ! cmp -s "$template/.gitignore" "$dest/.gitignore"; then
  [[ -z $(tail -c1 "$dest/.gitignore") ]] || echo >> "$dest/.gitignore"
  grep -vxF -f "$dest/.gitignore" "$template/.gitignore" >> "$dest/.gitignore" || true
fi
mv "$dest/Sources/__APP_NAME__" "$dest/Sources/$name"
mv "$dest/Kit/Sources/__APP_NAME__Kit" "$dest/Kit/Sources/${name}Kit"
mv "$dest/Kit/Tests/__APP_NAME__KitTests" "$dest/Kit/Tests/${name}KitTests"
# Replace the placeholders in every text file.
grep -rlI "__APP_NAME__\|__BUNDLE_ID__" "$dest" | while read -r f; do
  sed -i '' -e "s/__APP_NAME__/$name/g" -e "s/__BUNDLE_ID__/$bundle/g" "$f"
done
chmod +x "$dest"/tools/*.sh "$dest/tools/check-layout.swift"

cd "$dest"
[[ -d .git ]] || git init -q
git add -A
git commit -qm "Create $name from the iPhone app template"
echo "created $dest"
echo "next: cd \"$dest\" && make run-sim"
