#!/usr/bin/env bash
# Build evdi kernel module from source during image build.
# Compiles against the image's kernel headers so it always matches.

set -eoux pipefail

EVDI_VERSION="${EVDI_VERSION:-v1.14.15}"

# Determine kernel version from the image (not the build host)
KERNEL_VERSION=$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')
echo "Building evdi ${EVDI_VERSION} for kernel: ${KERNEL_VERSION}"

# Install build dependencies temporarily
# rpm-ostree install \
#     kernel-devel-matched \
#     git \
#     gcc \
#     make \
#     libdrm-devel

dnf5 install -y \
    kernel-devel-matched \
    gcc \
    make \
    libdrm-devel

# Clone evdi source
git clone --depth 1 --branch "${EVDI_VERSION}" \
    https://github.com/DisplayLink/evdi.git /tmp/evdi

# Build the kernel module
cd /tmp/evdi/module
make KVER="${KERNEL_VERSION}"

# Install the kernel module
INSTALL_DIR="/usr/lib/modules/${KERNEL_VERSION}/extra/evdi"
mkdir -p "${INSTALL_DIR}"
install -m 644 evdi.ko "${INSTALL_DIR}/evdi.ko"

# Build and install libevdi (userspace library needed by DisplayLink manager)
cd /tmp/evdi/library
make
install -m 755 libevdi.so.* /usr/lib64/
ln -sf libevdi.so.${EVDI_VERSION#v} /usr/lib64/libevdi.so
ln -sf libevdi.so.${EVDI_VERSION#v} /usr/lib64/libevdi.so.1
ldconfig

# Run depmod to register module
depmod "${KERNEL_VERSION}"

#TODO move following files to files?
# Set up modprobe config
mkdir -p /usr/lib/modprobe.d
cat > /usr/lib/modprobe.d/evdi.conf << 'EOF'
options evdi initial_device_count=4
EOF

# Set up module autoload on boot
mkdir -p /usr/lib/modules-load.d
cat > /usr/lib/modules-load.d/evdi.conf << 'EOF'
evdi
EOF

# Remove build dependencies to keep image small
# rpm-ostree uninstall \
    # kernel-devel-matched \
    # git \
    # gcc \
    # make \
    # libdrm-devel

dnf5 remove -y \
    kernel-devel-matched \
    gcc \
    make \
    libdrm-devel

# Clean up source and caches
rm -rf /tmp/evdi
# rpm-ostree cleanup -m

echo "evdi ${EVDI_VERSION} built and installed successfully for kernel ${KERNEL_VERSION}"