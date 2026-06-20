# shellcheck shell=bash
# Source the Nerves build environment for this project.
#
# After `mix firmware` Nerves writes one or more `nerves-env.sh` files under
# `.nerves/` that export NERVES_SYSTEM, NERVES_SDK_IMAGES, NERVES_TOOLCHAIN, etc.
# This script sources all of them so the QEMU harness can find little_loader.elf
# and the system images. It is meant to be `source`d, not executed:
#
#     source bin/nerves-env.sh
#
# If no env file is found it falls back to locating little_loader.elf under the
# build outputs, which is all the harness actually needs to boot QEMU.

# Resolve the project root (the directory containing this script's parent).
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  _ne_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
else
  _ne_root="$(pwd)"
fi

# Source every generated env file (avoids needing bash 4 `globstar`).
if [ -d "$_ne_root/.nerves" ]; then
  while IFS= read -r _ne_file; do
    # shellcheck disable=SC1090
    source "$_ne_file"
  done < <(find "$_ne_root/.nerves" -name 'nerves-env.sh' 2>/dev/null)
fi

# Fallback: derive NERVES_SDK_IMAGES from the built system artifact if it is
# still unset. This keeps the harness working even if no env file was written.
if [ -z "${NERVES_SDK_IMAGES:-}" ]; then
  # Prefer the artifact matching this system's VERSION. The system is the path
  # dep at ../.. (see mix.exs), so its VERSION pins which artifact this firmware
  # was built against. Several versions may be cached under ~/.nerves/artifacts.
  if [ -f "$_ne_root/../../VERSION" ]; then
    _ne_ver="$(tr -d '[:space:]' < "$_ne_root/../../VERSION")"
    for _ne_dir in "$HOME"/.nerves/artifacts/nerves_system_qemu_aarch64-*-"$_ne_ver"; do
      if [ -f "$_ne_dir/images/little_loader.elf" ]; then
        NERVES_SDK_IMAGES="$_ne_dir/images"
        break
      fi
    done
  fi

  # Last resort: the most recently built little_loader.elf.
  if [ -z "${NERVES_SDK_IMAGES:-}" ]; then
    _ne_loader="$(find "$_ne_root/_build" "$HOME/.nerves" -name 'little_loader.elf' -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -n1)"
    [ -n "$_ne_loader" ] && NERVES_SDK_IMAGES="$(dirname "$_ne_loader")"
  fi

  if [ -n "${NERVES_SDK_IMAGES:-}" ]; then
    export NERVES_SDK_IMAGES
    : "${NERVES_SYSTEM:=$(dirname "$NERVES_SDK_IMAGES")}"
    export NERVES_SYSTEM
  fi
fi

if [ -n "${NERVES_SDK_IMAGES:-}" ]; then
  echo "nerves-env: NERVES_SDK_IMAGES=$NERVES_SDK_IMAGES" >&2
else
  echo "nerves-env: could not locate the Nerves build environment." >&2
  echo "nerves-env: build the firmware first with: bin/build" >&2
fi

unset _ne_root _ne_file _ne_loader
