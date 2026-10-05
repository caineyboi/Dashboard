#!/usr/bin/env bash
#
# Configure an open source TV browser as the Chromecast's home app so the
# BOM radar dashboard starts on power-up with no sender device needed.
#
# This targets Chromecast with Google TV (NC2-6A5). Google's stock Google TV
# interface does not expose a home-app switch in Settings, so we set it over
# ADB instead.
#
# Usage:
#   ./chromecast-setup.sh setup      configure the Chromecast
#   ./chromecast-setup.sh rollback   undo everything this script changed
#
# Prerequisites:
#   1. Install a TV browser on the Chromecast from the Play Store.
#      TV Bro (GPL, https://github.com/truefedex/tv-bro) is the recommendation.
#   2. Set that browser's start page to the dashboard URL, inside the browser.
#
# Reverting is important. The rollback command is printed at the end of setup
# and restoring the stock launcher is a single command.

set -euo pipefail

DASHBOARD_URL="https://caineyboi.github.io/Dashboard/"

# Stock Google TV launcher. Disabling it is what forces the browser to start.
GOOGLE_TV_LAUNCHER="com.google.android.apps.tv.launcherx"
GOOGLE_TV_HOME_ACTIVITY="${GOOGLE_TV_LAUNCHER}/${GOOGLE_TV_LAUNCHER}.home.HomeActivity"

# TV Bro. Override with: BROWSER_PKG=com.example.browser ./chromecast-setup.sh
BROWSER_PKG="${BROWSER_PKG:-com.phlox.tvwebbrowser}"

# The Chromecast exposes ADB over TCP on 4321 rather than 5555.
ADB_PORT="${ADB_PORT:-4321}"

log()  { printf '\n==> %s\n' "$1"; }
info() { printf '    %s\n' "$1"; }
die()  { printf '\nERROR: %s\n' "$1" >&2; exit 1; }

require_adb() {
  if ! command -v adb >/dev/null 2>&1; then
    die "adb not found. Install it with: sudo dnf install android-tools"
  fi
}

require_device_ip() {
  if [[ -z "${CHROMECAST_IP:-}" ]]; then
    die "Set the Chromecast's IP first:
    CHROMECAST_IP=10.0.0.123 $0 ${1:-setup}

  Find it on the Chromecast under Settings > Network."
  fi
}

connect() {
  log "Connecting to Chromecast at ${CHROMECAST_IP}:${ADB_PORT}"
  if ! adb connect "${CHROMECAST_IP}:${ADB_PORT}"; then
    die "Could not connect over ADB.

  The Chromecast must be on the same network and awake. If this fails,
  enable Developer options then Wireless debugging on the Chromecast
  (Settings > System > About > Build, press it 7 times) and pair:

    adb pair ${CHROMECAST_IP}
    adb connect ${CHROMECAST_IP}:${ADB_PORT}"
  fi
}

verify_browser_installed() {
  log "Checking for ${BROWSER_PKG}"
  if adb shell pm list packages | grep -q "package:${BROWSER_PKG}"; then
    info "found"
  else
    die "${BROWSER_PKG} is not installed on the Chromecast.

  Install TV Bro from the Play Store on the TV, then re-run this script."
  fi
}

# TV browsers can expose more than one home-capable activity. Ask the device
# which activity actually handles HOME inside this package rather than
# guessing at a name that changes between releases.
resolve_home_activity() {
  log "Resolving the browser's home activity"
  local resolved
  resolved="$(adb shell cmd package resolve-activity --brief \
    -c android.intent.category.HOME "${BROWSER_PKG}" 2>/dev/null | tr -d '\r' | tail -1)"

  if [[ -z "${resolved}" || "${resolved}" == *"No activity found"* ]]; then
    die "Could not resolve a home activity for ${BROWSER_PKG}.

  List candidates yourself with:

    adb shell dumpsys package ${BROWSER_PKG} | grep -A2 android.intent.category.HOME"
  fi

  printf '%s' "${resolved}"
}

do_setup() {
  require_adb
  require_device_ip setup
  connect
  verify_browser_installed

  local home_activity
  home_activity="$(resolve_home_activity)"
  info "home activity: ${home_activity}"

  log "Making ${BROWSER_PKG} the home app"
  adb shell cmd package set-home-activity "${home_activity}"
  info "set"

  log "Disabling the stock Google TV launcher"
  adb shell pm disable-user --user 0 "${GOOGLE_TV_LAUNCHER}"
  info "disabled"

  cat <<EOF

Done. The Chromecast will now start ${BROWSER_PKG} on power-up.

Make sure the browser's own start page is set to:
  ${DASHBOARD_URL}

The page refreshes its own BOM data every five minutes. Once the browser is
saving and restoring its last session, the dashboard comes back on its own
after a reboot.

TO ROLL BACK, run:
  CHROMECAST_IP=${CHROMECAST_IP} $0 rollback

Note: powering the TV back on is a separate problem the Chromecast cannot
solve on its own. Enable HDMI-CEC on your TV, or use a smart plug, or a Google
Home routine to send the power-on command.
EOF
}

do_rollback() {
  require_adb
  require_device_ip rollback
  connect

  log "Re-enabling the stock Google TV launcher"
  adb shell pm enable --user 0 "${GOOGLE_TV_LAUNCHER}"
  info "enabled"

  log "Restoring the default home activity"
  adb shell cmd package set-home-activity "${GOOGLE_TV_HOME_ACTIVITY}"
  info "restored"

  printf '\nRolled back. The Google TV interface is back.\n'
}

case "${1:-}" in
  setup)    do_setup ;;
  rollback) do_rollback ;;
  *)
    die "Usage: $0 {setup|rollback}

  CHROMECAST_IP=<ip> $0 setup
  CHROMECAST_IP=<ip> $0 rollback"
    ;;
esac
