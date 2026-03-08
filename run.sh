#!/usr/bin/env bash
# =============================================================================
#  🍎  MacCleaner — run.sh
#  All-in-one entry point for macOS diagnostics, repair, and deep cleanup.
#
#  Runs the full pipeline:
#    Phase 1 → mac_repair.sh    (Diagnose & safe auto-fix)
#    Phase 2 → mac_fix_v2.sh    (Aggressive cleanup: Trash, xattr, crash logs)
#    Phase 3 → mac_fix_v3.sh    (Deep remediation: caches, Homebrew, temp files)
#
#  Usage:
#    sudo ./run.sh                  # Full pipeline (recommended)
#    sudo ./run.sh --dry-run        # Preview only — zero changes
#    sudo ./run.sh --skip-brew      # Skip Homebrew upgrade step in Phase 3
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Colours ───────────────────────────────────────────────────────────────────
BOLD='\033[1m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'

# ── Forward flags ─────────────────────────────────────────────────────────────
EXTRA_FLAGS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run|--skip-brew|--skip-xcode) EXTRA_FLAGS+=("$arg") ;;
    -h|--help)
      echo "Usage: sudo ./run.sh [--dry-run] [--skip-brew] [--skip-xcode]"
      echo ""
      echo "Runs the full MacCleaner pipeline in 3 phases:"
      echo "  Phase 1: mac_repair.sh    — Full system diagnostics & safe repair"
      echo "  Phase 2: mac_fix_v2.sh    — Trash, xattr bloat, crash logs, DNS"
      echo "  Phase 3: mac_fix_v3.sh    — Xcode, Homebrew, caches, temp files"
      echo ""
      echo "Flags:"
      echo "  --dry-run      Preview all phases without making changes"
      echo "  --skip-brew    Skip Homebrew update/upgrade in Phase 3"
      echo "  --skip-xcode   Skip Xcode DerivedData cleanup in Phase 3"
      exit 0 ;;
  esac
done

# ── Root check ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}${BOLD}Error:${RESET} MacCleaner needs root privileges for full access."
  echo -e "Re-run with: ${BOLD}sudo $0 $*${RESET}"
  exit 1
fi

# ── Banner ────────────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║                                                          ║"
echo "  ║        🍎  MacCleaner  v1.0                              ║"
echo "  ║        All-in-One macOS Repair & Optimization            ║"
echo "  ║                                                          ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

if printf '%s\n' "${EXTRA_FLAGS[@]}" 2>/dev/null | grep -q "dry-run"; then
  echo -e "  ${YELLOW}${BOLD}⚠  DRY-RUN MODE — no changes will be made${RESET}"
fi
echo ""

# ── Phase runner ──────────────────────────────────────────────────────────────
run_phase() {
  local phase_num="$1"
  local phase_name="$2"
  local script="$3"
  shift 3

  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}${CYAN}  PHASE ${phase_num}/3 — ${phase_name}${RESET}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""

  if [[ ! -x "$script" ]]; then
    echo -e "  ${RED}✖${RESET}  Script not found or not executable: $script"
    return 1
  fi

  "$script" "$@"
  local exit_code=$?

  if (( exit_code == 0 )); then
    echo -e "  ${GREEN}${BOLD}✔  Phase $phase_num complete${RESET}"
  else
    echo -e "  ${YELLOW}${BOLD}⚠  Phase $phase_num finished with exit code $exit_code${RESET}"
  fi

  return 0
}

# ── Execute pipeline ──────────────────────────────────────────────────────────
STARTED_AT=$(date)

run_phase 1 "System Diagnostics & Safe Repair" \
  "$SCRIPT_DIR/mac_repair.sh" "${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"}"

run_phase 2 "Aggressive Cleanup (Trash / xattr / Crash Logs)" \
  "$SCRIPT_DIR/mac_fix_v2.sh" "${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"}"

run_phase 3 "Deep Remediation (Caches / Homebrew / Temp Files)" \
  "$SCRIPT_DIR/mac_fix_v3.sh" "${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"}"

# ── Final summary ────────────────────────────────────────────────────────────
ENDED_AT=$(date)

echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║                                                          ║"
echo "  ║        ✅  MacCleaner Pipeline Complete                  ║"
echo "  ║                                                          ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  ${BOLD}Started :${RESET} $STARTED_AT"
echo -e "  ${BOLD}Finished:${RESET} $ENDED_AT"
echo -e "  ${BOLD}Reports :${RESET} ~/Desktop/mac_repair_logs/"
echo ""
echo -e "  ${CYAN}Open the latest report:${RESET}"
echo -e "  ${BOLD}open ~/Desktop/mac_repair_logs/${RESET}"
echo ""
