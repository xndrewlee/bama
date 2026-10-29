#!/bin/zsh
# Links every skill in this repo into ~/.claude/skills and ~/.agents/skills,
# so edits in the repo show up in Claude Code and Codex at once.
# Replaces only links that point into this repo. Anything else with the same
# name stays as it is: the script names it and exits 1.
# Usage: scripts/link-skills.sh
set -euo pipefail
repo=${0:A:h:h}
skipped=0
for target in ~/.claude/skills ~/.agents/skills; do
  mkdir -p "$target"
  # Drop links into this repo whose skill is gone (names before bama-).
  for link in "$target"/*(N@); do
    dest=$(readlink "$link")
    if [[ $dest == "$repo"/skills/* && ! -e $dest ]]; then
      rm "$link"
      echo "removed $link (its skill is gone)"
    fi
  done
  for skill in "$repo"/skills/*/*/; do
    skill=${skill%/}
    link=$target/${skill:t}
    if [[ -L $link ]]; then
      dest=$(readlink "$link")
      if [[ $dest != "$repo"/* ]]; then
        echo "skipped $link: it links to $dest, outside this repo." \
          "Remove it and run again." >&2
        skipped=1
        continue
      fi
    elif [[ -e $link ]]; then
      echo "skipped $link: it is not a link. Move it and run again." >&2
      skipped=1
      continue
    fi
    ln -sfn "$skill" "$link"
    echo "$link"
  done
done
exit $skipped
