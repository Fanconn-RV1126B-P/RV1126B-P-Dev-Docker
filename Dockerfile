FROM ubuntu:24.04

LABEL maintainer="frankie.yuen@me.com"
LABEL description="Build environment for Rockchip RV1126B-P SDK v1.1.0 (Buildroot + Debian)"
LABEL version="1.1"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Hong_Kong

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core build tools
    rsync \
    gcc \
    g++ \
    make \
    build-essential \
    # Libraries
    libsqlite3-dev \
    libssl-dev \
    libgmp-dev \
    libmpc-dev \
    libncurses-dev \
    # Build utilities
    device-tree-compiler \
    flex \
    bison \
    bc \
    gettext \
    file \
    fakeroot \
    # Archive tools
    unzip \
    bzip2 \
    tar \
    xz-utils \
    gawk \
    cpio \
    xxd \
    # Version control & download
    git \
    wget \
    curl \
    ca-certificates \
    # Python 3 (for some build scripts)
    python3 \
    python3-pip \
    # Additional utilities
    vim \
    tmux \
    locales \
    # ── Debian rootfs build dependencies ──────────────────────────────────
    # Required by check-debian.sh and the live-build / debootstrap pipeline.
    sudo \
    qemu-user-static \
    binfmt-support \
    debootstrap \
    # e2fsprogs: mke2fs needs the -d flag (pack rootfs into ext4 image).
    # Ubuntu 24.04 ships a new enough version; pin to ensure it stays current.
    e2fsprogs \
    && rm -rf /var/lib/apt/lists/*

# ── live-build: pinned to the version the SDK's check-debian.sh requires ──
# Needs /usr/share/live/build/data/debian-cd/bookworm to exist.
# Ubuntu 24.04's packaged live-build is too old, so we install from source.
RUN apt-get update && apt-get remove -y live-build 2>/dev/null || true && \
    git clone https://salsa.debian.org/live-team/live-build.git \
        --depth 1 -b debian/1%20230131 /tmp/live-build && \
    cd /tmp/live-build && \
    rm -rf manpages/po/ && \
    make install -j$(nproc) && \
    rm -rf /tmp/live-build && \
    rm -rf /var/lib/apt/lists/*

# ── debootstrap: ensure bookworm script is present ────────────────────────
# Ubuntu 24.04's debootstrap supports bookworm, but verify and upgrade if not.
RUN if [ ! -e "/usr/share/debootstrap/scripts/bookworm" ]; then \
        apt-get update && apt-get remove -y debootstrap && \
        git clone https://salsa.debian.org/installer-team/debootstrap.git \
            --depth 1 -b debian/1.0.123+deb11u2 /tmp/debootstrap && \
        cd /tmp/debootstrap && \
        make install -j$(nproc) && \
        rm -rf /tmp/debootstrap && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Build and Install Python 2.7.18 (required by SDK build system)
WORKDIR /tmp
RUN wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz && \
    tar xf Python-2.7.18.tgz && \
    cd Python-2.7.18 && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf Python-2.7.18 Python-2.7.18.tgz

# Build and Install lz4 v1.9.4 (required for compression)
WORKDIR /tmp
RUN git clone https://github.com/lz4/lz4.git --depth 1 -b v1.9.4 && \
    cd lz4 && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf lz4

# Update dynamic linker cache
RUN ldconfig

# Create workspace directory
WORKDIR /workspace

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Add build user (non-root builds)
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN (groupadd -g ${GROUP_ID} builder 2>/dev/null || true) && \
    (useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash builder 2>/dev/null || usermod -aG ${GROUP_ID} $(id -nu ${USER_ID})) && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers || \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to non-root user (use builder if created, otherwise use ubuntu/existing user)
USER ${USER_ID}
WORKDIR /workspace

# Environment variables to help fakeroot work in Docker
ENV FAKEROOTDONTTRYCHOWN=1

# Print environment info on container start
CMD ["bash", "-c", "echo '========================================' && \
    echo 'RV1126B-P Build Environment' && \
    echo '========================================' && \
    echo 'GCC:      '$(gcc --version | head -1) && \
    echo 'Python2:  '$(python2.7 --version 2>&1) && \
    echo 'lz4:      '$(lz4 --version 2>&1 | head -1) && \
    echo '========================================' && \
    echo 'SDK is mounted at:        /workspace' && \
    echo 'Host workspace mounted at: /workspace-host' && \
    echo '' && \
    echo 'Quick Start:' && \
    echo '  cd rv1126b_linux6.1_sdk_v1.1.0' && \
    echo '  ./build.sh lunch    # Select option 9' && \
    echo '  ./build.sh          # Build firmware' && \
    echo '' && \
    echo 'Other repos:' && \
    echo '  cd /workspace-host/RV1126B-P-Camera-Pipeline' && \
    echo '========================================' && \
    exec bash"]
