---
description: Copy a file to a target directory with Unix epoch in the filename
allowed-tools: Bash(cp:*), Bash(mkdir:*)
argument-hint: [source-file] [target-dir]
---
f="$1"; dir="$2"; ext="${f##*.}"; name="${f##*/}"; base="${name%.*}"; mkdir -p "$dir" && cp "$f" "${dir}/${base}.$(date +%s).${ext}"
