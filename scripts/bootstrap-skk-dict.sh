#!/usr/bin/env bash
set -euo pipefail

# ==================================
# SKK dict installer (skk-dev official)
# - Downloads .gz and .md5
# - Verifies checksum
# - Decompresses to ~/.config/skk/
# - Atomic replace to avoid partial files
# ==================================

SKK_DIR="${HOME}/.config/skk"
BASE_URL="https://skk-dev.github.io/dict"

FORCE=0
QUIET=0

usage() {
  cat <<'USAGE'
Usage: bootstrap-skk.sh [options]

Options:
  --dir PATH     Install directory (default: ~/.config/skk)
  --force        Re-download and overwrite even if file exists
  --quiet        Less output
  -h, --help     Show this help

Dictionaries installed:
  - SKK-JISYO.L
  - SKK-JISYO.jinmei
  - SKK-JISYO.geo

Source:
  https://skk-dev.github.io/dict/
USAGE
}

log() { [ "$QUIET" -eq 0 ] && echo "==> $*"; }
die() { echo "error: $*" >&2; exit 1; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

md5_of_file() {
  local file="$1"
  if have_cmd md5sum; then
    md5sum "$file" | awk '{print $1}'
  elif have_cmd openssl; then
    openssl md5 "$file" | awk '{print $2}'
  else
    die "md5sum or openssl is required for checksum verification"
  fi
}

fetch() {
  local url="$1"
  local out="$2"
  curl -fsSL --retry 3 --retry-delay 1 --connect-timeout 10 --max-time 600 -o "$out" "$url"
}

install_one() {
  local name="$1"           # e.g. SKK-JISYO.L
  local gz="${name}.gz"     # e.g. SKK-JISYO.L.gz
  local md5="${gz}.md5"     # e.g. SKK-JISYO.L.gz.md5

  local target="${SKK_DIR}/${name}"
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  local gz_path="${tmpdir}/${gz}"
  local md5_path="${tmpdir}/${md5}"
  local out_path="${tmpdir}/${name}"

  # Skip if exists and not forced (best effort: verify by re-downloading md5 only)
  if [ "$FORCE" -eq 0 ] && [ -f "$target" ]; then
    log "$name already exists: $target"
    log "skip (use --force to overwrite)"
    return 0
  fi

  log "download: ${BASE_URL}/${gz}"
  fetch "${BASE_URL}/${gz}" "$gz_path"

  log "download: ${BASE_URL}/${md5}"
  fetch "${BASE_URL}/${md5}" "$md5_path"

  # md5 file format can vary; extract first hex token
  local expected
  expected="$(grep -Eo '([a-fA-F0-9]{32})' "$md5_path" | head -n 1 || true)"
  [ -n "$expected" ] || die "failed to parse md5 from ${md5_path}"

  local actual
  actual="$(md5_of_file "$gz_path")"

  if [ "${expected,,}" != "${actual,,}" ]; then
    die "checksum mismatch for ${gz}: expected=$expected actual=$actual"
  fi

  log "checksum OK: $name"

  if ! have_cmd gzip; then
    die "gzip is required to decompress ${gz}"
  fi

  gzip -dc "$gz_path" > "$out_path"

  mkdir -p "$SKK_DIR"

  # Atomic replace
  local tmp_target="${target}.tmp.$$"
  cp -f "$out_path" "$tmp_target"
  mv -f "$tmp_target" "$target"

  log "installed: $target"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)
      shift
      [ $# -gt 0 ] || die "--dir requires a path"
      SKK_DIR="$1"
      ;;
    --force) FORCE=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

log "install dir: $SKK_DIR"
log "source: ${BASE_URL}/"

install_one "SKK-JISYO.L"
install_one "SKK-JISYO.jinmei"
install_one "SKK-JISYO.geo"

log "done"
