#!/usr/bin/env bash
# Xcode Run Script: sync Maps API key before iOS build (same sources as Android).
set -euo pipefail
ROOT="${SRCROOT}/.."
OUT="${SRCROOT}/Flutter/Maps.local.xcconfig"
KEY=""

if [[ -f "${ROOT}/android/local.properties" ]]; then
  KEY="$(grep -E '^MAPS_API_KEY=' "${ROOT}/android/local.properties" | head -1 | cut -d= -f2- | tr -d '[:space:]')"
fi

if [[ -z "${KEY}" && -f "${ROOT}/../masterfabric-go/.env" ]]; then
  KEY="$(grep -E '^GOOGLE_MAPS_API_KEY=' "${ROOT}/../masterfabric-go/.env" | head -1 | cut -d= -f2- | tr -d '[:space:]')"
fi

if [[ -n "${KEY}" ]]; then
  echo "MAPS_API_KEY=${KEY}" > "${OUT}"
  echo "generate_maps_xcconfig: wrote Maps.local.xcconfig"
else
  echo "warning: No Maps API key — ensure ios/Flutter/Maps.local.xcconfig exists"
fi
