#!/usr/bin/env bash

set -oue pipefail

# Set the Windows 95 Plymouth theme as default and rebuild the initramfs
# so the new theme is actually picked up at boot.
# (win95-startup-sound.service is enabled via its graphical-session.target.wants symlink in files/system.)
plymouth-set-default-theme -R win95boot
