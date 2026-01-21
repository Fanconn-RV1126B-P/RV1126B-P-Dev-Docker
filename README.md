# RV1126B-P SDK Docker Build Environment

Reproducible Docker build environment for the Rockchip RV1126B-P Linux SDK.

**Architecture:** Build tools in Docker, SDK mounted from host

**Compatible with:** [SDK v1.1.0](https://github.com/Fanconn-RV1126B-P/RV1126B-P-SDK/releases/tag/v.1.1.0-setup-build-env)

## Features

- ✅ Based on Ubuntu 24.04 LTS (GCC 13.x - avoids libffi build errors)
- ✅ All build dependencies pre-installed
- ✅ Python 2.7.18 (required by SDK build system)
- ✅ lz4 v1.9.4 (compression utility)
- ✅ tmux terminal multiplexer (persistent build sessions with scrollback)
- ✅ Runs as root (bypasses fakeroot semaphore issues in Docker)
- ✅ Privileged mode enabled (full host kernel access)
- ✅ SDK mounted from host (editable, persistent)

## Requirements

- Docker Engine 20.10+
- Docker Compose 2.0+ (plugin or standalone)
- 50GB+ free disk space (20GB SDK + 30GB build outputs)
- 8GB+ RAM recommended (16GB ideal)

## Quick Start

### Step 0: Get the SDK

Clone the SDK repository (requires access to private repository):

```bash
# Clone to your preferred location
cd ~
git clone https://github.com/Fanconn-RV1126B-P/RV1126B-P-SDK.git

# Or clone specific release (recommended, smaller/faster)
git clone --depth 1 --branch v1.1.0 https://github.com/Fanconn-RV1126B-P/RV1126B-P-SDK.git
```

**Note:** The SDK repository is ~16GB with Git LFS files. Ensure you have sufficient disk space and a stable internet connection.

### Step 1: Clone the Docker Environment

```bash
git clone https://github.com/Fanconn-RV1126B-P/RV1126B-P-Dev-Docker.git
cd RV1126B-P-Dev-Docker
```

### Step 2: Build the Docker Image

```bash
# Build with default tag (v0.1.0)
docker compose build

# Or specify custom version tag
IMAGE_TAG=v1.0.0 docker compose build
```

**Build time:** ~5-10 minutes (downloads and compiles Python 2.7.18 and lz4)

### Step 3: Run Container with SDK Mounted

```bash
# Default (if SDK is in ../RV1126B-P-SDK)
docker compose run --rm rv1126b-builder

# Or specify custom SDK path
SDK_PATH=/path/to/RV1126B-P-SDK docker compose run --rm rv1126b-builder
```

**Note:** Container runs as root to bypass fakeroot semaphore issues. After build completes, you may need to fix file permissions (see Troubleshooting section).

### Step 4: Build the Firmware (Inside Container)

```bash
# Start a tmux session for persistent build
tmux new -s build

# Inside tmux:
cd rv1126b_linux6.1_sdk_v1.1.0
./build.sh lunch
# Select option 9: rockchip_rv1126bp_evb1_v10_defconfig
./build.sh

# Detach from tmux: Ctrl+B, then d
# Reattach later: tmux attach -t build
# Scroll build log: Ctrl+B, then [ (arrow keys to scroll, q to exit)
```

**Build time:** ~30-60 minutes depending on CPU cores

### Step 5: Verify Build Success

**Check build completion:**
```bash
# On host machine (in another terminal)
grep -E "succeeded|OK|Ready" ~/RV1126B-P/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/output/sessions/latest/build.log | tail -5

# Should show:
# Running mk-updateimg.sh - build_updateimg succeeded.
# Running mk-firmware.sh - build_firmware succeeded.
# Running 99-all.sh - build_all succeeded.
```

**Verify generated firmware:**
```bash
# Check firmware image exists
ls -lh ~/RV1126B-P/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/output/update/Image/update.img

# Should show: update.img (~673MB)

# List all generated partition images
ls -lh ~/RV1126B-P/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/output/firmware/

# Should include:
# - MiniLoaderAll.bin (441KB)   - SPL bootloader
# - uboot.img (4.0MB)            - U-Boot
# - boot.img (39MB)              - Linux kernel + DTB
# - rootfs.img (560MB)           - Root filesystem
# - recovery.img (44MB)          - Recovery system
# - oem.img (18MB)               - OEM partition
# - userdata.img (8.0MB)         - User data
# - update.img (673MB)           - Complete firmware package
```

**Build artifacts locations:**
- **Final firmware**: `output/update/Image/update.img` (flash this to device)
- **Build logs**: `output/sessions/latest/build.log`
- **Individual images**: `output/firmware/`
- **Kernel**: `kernel-6.1/boot.img`
- **U-Boot**: `u-boot/uboot.img`
- **Rootfs**: `buildroot/output/rockchip_rv1126b/images/rootfs.ext2`

### Step 6: Fix File Permissions (Optional)

Since the container runs as root, output files are owned by root. Fix permissions on host:

```bash
sudo chown -R $(id -u):$(id -g) ~/RV1126B-P/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/output
sudo chown -R $(id -u):$(id -g) ~/RV1126B-P/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/buildroot/output
```

## Advanced Usage

### Interactive Shell
```bash
UID=$(id -u) GID=$(id -g) docker compose run --rm rv1126b-builder
```

### Run Specific Build Commands
```bash
# Just configure
docker compose run --rm rv1126b-builder bash -c "cd rv1126b_linux6.1_sdk_v1.1.0 && ./build.sh lunch"

# Full build
docker compose run --rm rv1126b-builder bash -c "cd rv1126b_linux6.1_sdk_v1.1.0 && ./build.sh"
```

### Use Different SDK Path
```bash
SDK_PATH=/mnt/data/RV1126B-P-SDK docker compose run --rm rv1126b-builder
```

### Keep Container Running (for Development)
```bash
# Start in background
docker compose up -d

# Attach to running container
docker exec -it rv1126b-build-env bash

# When done
docker compose down
```

### Tmux Session Management
```bash
# Create new session
tmux new -s build

# Detach from session (build continues)
Ctrl+B, then d

# List sessions
tmux ls

# Reattach to session
tmux attach -t build

# Scroll mode (view build log history)
Ctrl+B, then [
# Use arrow keys, Page Up/Down, or mouse wheel
# Press q to exit scroll mode

# Kill session
tmux kill-session -t build
```

## Directory Structure

```
# Host machine:
~/RV1126B-P-SDK/               # SDK repository (on host)
└── rv1126b_linux6.1_sdk_v1.1.0/
    ├── build.sh
    ├── app/
    ├── buildroot/
    ├── kernel-6.1/
    ├── output/               # Build outputs (persists on host)
    └── ...

~/RV1126B-P-Dev-Docker/        # Docker environment (on host)
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
└── README.md

# Inside Docker container:
/workspace/                    # Mounted from ~/RV1126B-P-SDK
└── rv1126b_linux6.1_sdk_v1.1.0/
```

## Build Logs & Outputs

All build artifacts persist on the **host** in the mounted SDK directory:

```bash
# On host machine (example paths):
~/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/output/log/latest/    # Latest build log
~/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/output/sessions/      # Session logs
~/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/rockdev/             # Firmware images
```

You can view logs, edit files, and access build outputs **directly on your host** - no need to copy from container.

## Troubleshooting

### Permission Errors on Build Artifacts

Output files owned by root after build? This is expected since the container runs as root.

**Fix:** Change ownership on host:

```bash
# Fix output directory permissions
sudo chown -R $(id -u):$(id -g) ~/RV1126B-P/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/output

# Fix buildroot output if needed
sudo chown -R $(id -u):$(id -g) ~/RV1126B-P/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/buildroot/output
```

**Why run as root?** The container runs as root (`user: "0:0"`) to bypass fakeroot semaphore issues that occur in Docker environments. This is a known limitation where fakeroot's IPC semaphores don't work properly even with privileged mode.

### SDK Not Found

Error: `SDK should be mounted at /workspace`

Fix: Verify SDK path and mount:

```bash
# Check SDK exists
ls ~/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0

# Specify correct path
SDK_PATH=~/RV1126B-P-SDK docker compose run --rm rv1126b-builder
```

### Out of Disk Space

Build outputs are large. Clean up on host:

```bash
# Remove build artifacts (on host)
cd ~/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0
rm -rf output/ rockdev/

# Clean Docker build cache
docker system prune -a
```

### Slow Build Performance

- Increase Docker resources (CPU/RAM) in Docker Desktop settings
- Use SSD for SDK directory
- Enable buildroot cache (already configured in docker-compose.yml)

### Fakeroot Semaphore Errors

Error: `fakeroot internal error #43: Identifier removed` or `semop(2): Invalid argument`

**Cause:** Fakeroot requires IPC semaphores which don't work properly in Docker containers, even with `privileged: true`.

**Solution:** Container runs as root (`user: "0:0"` in docker-compose.yml) to bypass fakeroot entirely. When running as root, buildroot doesn't need fakeroot to simulate permissions.

**Impact on firmware:** None. The generated firmware is identical whether built with fakeroot or as root. This only affects the build process, not the output.

**Trade-off:** Output files will be owned by root. After build, run: `sudo chown -R $(id -u):$(id -g) ~/RV1126B-P/RV1126B-P-SDK/rv1126b_linux6.1_sdk_v1.1.0/output`

### Network/Download Timeouts

Error: `Failed to download host-autoconf-2.71.tar.xz` or similar download failures.

**Cause:** Slow or unreliable download mirrors (e.g., Princeton University mirror timeouts).

**Solution 1: Modify buildroot mirror configuration**

Edit the buildroot config to use faster mirrors:

```bash
# Inside container, edit the config file
vi /workspace/rv1126b_linux6.1_sdk_v1.1.0/buildroot/output/rockchip_rv1126b/.config

# Find and change these lines (around line 420-428):
BR2_PRIMARY_SITE="https://buildroot.org/downloads/"
BR2_BACKUP_SITE="https://ftp.gnu.org/gnu/ https://sources.buildroot.net"
BR2_GNU_MIRROR="https://ftp.gnu.org/gnu"

# Save and rebuild
cd /workspace/rv1126b_linux6.1_sdk_v1.1.0
./build.sh
```

**Note:** This file is in `buildroot/output/` (generated during build) and changes are **temporary**. They will be lost if you run `make clean` in buildroot. For permanent changes, modify the defconfig file: `buildroot/configs/rockchip_rv1126bp_evb1_v10_defconfig`

**Solution 2: Manually download failing packages**

```bash
# Manually download the failing package
cd buildroot/dl
wget https://ftp.gnu.org/gnu/PACKAGE/PACKAGE-VERSION.tar.xz
cd /workspace/rv1126b_linux6.1_sdk_v1.1.0
./build.sh
```

## Environment Details

- **Base Image:** ubuntu:24.04
- **GCC Version:** 13.x (compatible with SDK, avoids GCC 14.2 libffi errors)
- **Python 2.7:** 2.7.18 (built from source)
- **lz4:** v1.9.4
- **tmux:** Latest (persistent terminal sessions)
- **Container User:** root (UID 0) - bypasses fakeroot semaphore issues
- **Container Mode:** Privileged (full host kernel access)
- **Image Tag:** Configurable via IMAGE_TAG env var (default: v0.1.0)
- **Locale:** en_US.UTF-8
- **Timezone:** Asia/Hong_Kong (configurable)
- **Image Size:** ~2GB (build tools only)
- **SDK Location:** Mounted from host (not in image)

## Related Links

- [SDK Repository](https://github.com/Fanconn-RV1126B-P/RV1126B-P-SDK)
- [SDK Release v1.1.0](https://github.com/Fanconn-RV1126B-P/RV1126B-P-SDK/releases/tag/v.1.1.0-setup-build-env) - **Tested and compatible**
- [Rockchip Documentation](https://github.com/Fanconn-RV1126B-P/RV1126B-P-SDK/tree/main/rv1126b_linux6.1_sdk_v1.1.0/docs)

## License

This Docker environment setup is provided as-is for building the Rockchip RV1126B-P SDK.
See the SDK repository for SDK-specific licensing.
