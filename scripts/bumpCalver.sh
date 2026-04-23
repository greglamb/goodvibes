#!/usr/bin/env bash
# bumpCalver — Universal CalVer version bumper for any JSON file
#
# Usage:
#   bumpCalver <file> [field] [options]
#
# Arguments:
#   file       Path to any JSON file (package.json, plugin.json, manifest.json, etc.)
#   field      Dot-notation path to version field (default: "version")
#
# Options:
#   --scheme <name>  Version scheme (default: "default"). See Schemes below.
#   --dry-run        Show what would change without writing
#   --get            Print current version and exit
#   --npm-lock       Sync package-lock.json after bumping (runs npm install --package-lock-only)
#
# Schemes:
#   default    0.YYMM.DDBB     Semver-compatible. Fixed 0 major, YYMM minor, DDBB patch.
#                               Up to 99 builds/day. Leading zeros stripped for semver.
#                               Example: 0.2602.1503
#
#   yy         YY.MMDD.BBBB    Year as major version. MMDD minor, build-only patch.
#                               Up to 9999 builds/day. Leading zeros stripped.
#                               Example: 26.215.3
#
#   short      YYMM.DDBB       Two-segment. YYMM major, DDBB minor.
#                               Up to 99 builds/day. Leading zeros stripped.
#                               Example: 2602.1503
#
# Examples:
#   bumpCalver package.json                                # default scheme
#   bumpCalver plugin.json version --dry-run               # preview without writing
#   bumpCalver marketplace.json metadata.version           # nested fields
#   bumpCalver manifest.json version --scheme yy           # YY.MMDD.BBBB
#   bumpCalver config.json version --scheme short          # YYMM.DDBB
#   bumpCalver manifest.json version --get                 # print current version
#   bumpCalver new-file.json config.ver                    # creates field if missing
#   bumpCalver package.json --npm-lock                     # bump + sync lockfile
#
# Behavior:
#   - If the field doesn't exist, it will be created
#   - If the current version doesn't match the active scheme, it will be overwritten
#   - If bumped multiple times on the same day, the build number increments
#   - JSON formatting (indentation) is preserved via jq
#
# Requires: jq
# License: MIT

set -Eeuo pipefail

SCRIPT_NAME=$(basename "$0")

# --- Defaults ----------------------------------------------------------------
FILE=""
FIELD="version"
SCHEME="default"
DRY_RUN=false
GET_ONLY=false
NPM_LOCK=false

# --- Parse args --------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --get)      GET_ONLY=true ;;
    --npm-lock) NPM_LOCK=true ;;
    --scheme)   NEXT_IS_SCHEME=true; continue ;;
    --help|-h)
      sed -n '2,/^set -/{ /^set -/d; s/^# \?//; p }' "$0" | sed "s/bumpCalver/$SCRIPT_NAME/g"
      exit 0
      ;;
    -*)
      echo "Error: unknown flag: $arg" >&2
      echo "Run '$SCRIPT_NAME --help' for usage" >&2
      exit 1
      ;;
    *)
      if [[ "${NEXT_IS_SCHEME:-}" == "true" ]]; then
        SCHEME="$arg"
        NEXT_IS_SCHEME=false
      elif [[ -z "$FILE" ]]; then
        FILE="$arg"
      else
        FIELD="$arg"
      fi
      ;;
  esac
done

# --- Validate ----------------------------------------------------------------
if [[ -z "$FILE" ]]; then
  echo "Usage: $SCRIPT_NAME <file> [field] [--scheme default|yy|short] [--dry-run] [--get] [--npm-lock]" >&2
  echo "Run '$SCRIPT_NAME --help' for details" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed" >&2
  echo "Install: brew install jq  (macOS) or apt install jq  (Linux)" >&2
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "Error: file not found: $FILE" >&2
  exit 1
fi

case "$SCHEME" in
  default|yy|short) ;;
  *)
    echo "Error: unknown scheme '$SCHEME' (expected: default, yy, short)" >&2
    exit 1
    ;;
esac

# --- Build jq path from dot notation -----------------------------------------
JQ_PATH=".$FIELD"

# --- Read current version (may not exist) ------------------------------------
CURRENT=$(jq -r "$JQ_PATH // empty" "$FILE" 2>/dev/null || true)
FIELD_EXISTS=true

if [[ -z "$CURRENT" ]]; then
  FIELD_EXISTS=false
  CURRENT="(none)"
fi

if $GET_ONLY; then
  if ! $FIELD_EXISTS; then
    echo "Error: field '$FIELD' not found in $FILE" >&2
    exit 1
  fi
  echo "$CURRENT"
  exit 0
fi

# --- Today's date components (single call to avoid midnight race) ------------
TODAY_DATE=$(date +%y:%m:%d)
TODAY_YY="${TODAY_DATE%%:*}"
TODAY_DD="${TODAY_DATE##*:}"
TODAY_MM="${TODAY_DATE#*:}"; TODAY_MM="${TODAY_MM%:*}"

# --- Parse current version (scheme-specific) ---------------------------------
BUILD=1
PARSED=false

if $FIELD_EXISTS; then
  case "$SCHEME" in
    default)
      # 0.YYMM.DDBB — e.g., 0.2602.1503
      if [[ $CURRENT =~ ^0\.([0-9]{4})\.([0-9]+)$ ]]; then
        OLD_YYMM="${BASH_REMATCH[1]}"
        OLD_PATCH="${BASH_REMATCH[2]}"
        if (( ${#OLD_PATCH} > 2 )); then
          OLD_DD="${OLD_PATCH:0:${#OLD_PATCH}-2}"
          OLD_BB="${OLD_PATCH: -2}"
        else
          OLD_DD="00"
          OLD_BB="$OLD_PATCH"
        fi
        if (( 10#$OLD_YYMM == 10#${TODAY_YY}${TODAY_MM} )) && (( 10#$OLD_DD == 10#$TODAY_DD )); then
          BUILD=$(( 10#$OLD_BB + 1 ))
        fi
        PARSED=true
      fi
      ;;
    yy)
      # YY.MMDD.BBBB — e.g., 26.215.3
      if [[ $CURRENT =~ ^([0-9]{1,2})\.([0-9]{1,4})\.([0-9]+)$ ]]; then
        OLD_YY="${BASH_REMATCH[1]}"
        OLD_MMDD="${BASH_REMATCH[2]}"
        OLD_BUILD="${BASH_REMATCH[3]}"
        if (( ${#OLD_MMDD} > 2 )); then
          OLD_MM="${OLD_MMDD:0:${#OLD_MMDD}-2}"
          OLD_DD="${OLD_MMDD: -2}"
        else
          OLD_MM="00"
          OLD_DD="$OLD_MMDD"
        fi
        if (( 10#$OLD_YY == 10#$TODAY_YY )) && (( 10#$OLD_MM == 10#$TODAY_MM )) && (( 10#$OLD_DD == 10#$TODAY_DD )); then
          BUILD=$(( 10#$OLD_BUILD + 1 ))
        fi
        PARSED=true
      fi
      ;;
    short)
      # YYMM.DDBB — e.g., 2602.1503
      if [[ $CURRENT =~ ^([0-9]{3,4})\.([0-9]+)$ ]]; then
        OLD_YYMM="${BASH_REMATCH[1]}"
        OLD_PATCH="${BASH_REMATCH[2]}"
        if (( ${#OLD_PATCH} > 2 )); then
          OLD_DD="${OLD_PATCH:0:${#OLD_PATCH}-2}"
          OLD_BB="${OLD_PATCH: -2}"
        else
          OLD_DD="00"
          OLD_BB="$OLD_PATCH"
        fi
        if (( 10#$OLD_YYMM == 10#${TODAY_YY}${TODAY_MM} )) && (( 10#$OLD_DD == 10#$TODAY_DD )); then
          BUILD=$(( 10#$OLD_BB + 1 ))
        fi
        PARSED=true
      fi
      ;;
  esac

  if ! $PARSED; then
    echo "⚠ Current version \"$CURRENT\" does not match '$SCHEME' scheme — will overwrite with fresh version" >&2
  fi
fi

if ! $FIELD_EXISTS; then
  echo "⚠ Field '$FIELD' not found in $FILE — will create it" >&2
fi

# --- Build overflow check ----------------------------------------------------
case "$SCHEME" in
  default|short)
    if (( BUILD > 99 )); then
      echo "Error: build number exceeded 99 for today (current: $CURRENT)" >&2
      echo "The '$SCHEME' scheme (BB) supports up to 99 builds per day" >&2
      exit 1
    fi
    ;;
  yy)
    if (( BUILD > 9999 )); then
      echo "Error: build number exceeded 9999 for today (current: $CURRENT)" >&2
      echo "The 'yy' scheme (BBBB) supports up to 9999 builds per day" >&2
      exit 1
    fi
    ;;
esac

# --- Generate new version (scheme-specific) ----------------------------------
BB=$(printf "%02d" "$BUILD")

case "$SCHEME" in
  default)
    # 0.YYMM.DDBB — strip leading zeros for semver compliance
    NEXT="0.${TODAY_YY}${TODAY_MM}.$(( 10#${TODAY_DD}${BB} ))"
    ;;
  yy)
    # YY.MMDD.BBBB — strip leading zeros per segment
    NEXT="$(( 10#$TODAY_YY )).$(( 10#${TODAY_MM}${TODAY_DD} )).${BUILD}"
    ;;
  short)
    # YYMM.DDBB — strip leading zeros per segment
    NEXT="$(( 10#${TODAY_YY}${TODAY_MM} )).$(( 10#${TODAY_DD}${BB} ))"
    ;;
esac

echo "${CURRENT} → ${NEXT}  (${FILE} → ${FIELD})  [scheme: ${SCHEME}]"

# --- Write -------------------------------------------------------------------
if $DRY_RUN; then
  echo "(dry run, no changes written)"
  exit 0
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

jq "$JQ_PATH = \"$NEXT\"" "$FILE" > "$TMP"

cat "$TMP" > "$FILE"

echo "✓ Updated $FILE"

# --- Sync package-lock.json if requested ------------------------------------
if $NPM_LOCK; then
  PKG_DIR=$(dirname "$FILE")
  if [[ -f "$PKG_DIR/package-lock.json" ]]; then
    echo "Syncing package-lock.json..."
    (cd "$PKG_DIR" && npm install --package-lock-only --silent)
    echo "✓ Synced package-lock.json"
  else
    echo "⚠ No package-lock.json found in $(cd "$PKG_DIR" && pwd) — skipped" >&2
  fi
fi