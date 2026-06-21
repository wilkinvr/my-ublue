#!/usr/bin/env bash

set -eoux pipefail

ARTIFACTS_DIR="/tmp/evdi-artifacts"

if [[ ! -d "${ARTIFACTS_DIR}" ]]; then
    echo "ERROR: ${ARTIFACTS_DIR} not found. The 'copy' module must run before this one."
    exit 1
fi

KERNEL_VERSION=$(cat "${ARTIFACTS_DIR}/meta/kernel-version")
echo "Installing evdi for kernel ${KERNEL_VERSION}"

# Install the kernel module
mkdir -p "/usr/lib/modules/${KERNEL_VERSION}/extra/evdi"
install -m 644 "${ARTIFACTS_DIR}/modules/evdi.ko" \
    "/usr/lib/modules/${KERNEL_VERSION}/extra/evdi/evdi.ko"

# Install libevdi
cp -P "${ARTIFACTS_DIR}/lib/"libevdi.so* /usr/lib64/
ldconfig

# Register the module with the kernel
depmod "${KERNEL_VERSION}"

# Configure modprobe options and autoload on boot
mkdir -p /usr/lib/modprobe.d /usr/lib/modules-load.d
printf 'options evdi initial_device_count=4\n' > /usr/lib/modprobe.d/evdi.conf
printf 'evdi\n' > /usr/lib/modules-load.d/evdi.conf

# Clean up
rm -rf "${ARTIFACTS_DIR}"

echo "evdi installed successfully for kernel ${KERNEL_VERSION}"