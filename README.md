# RV1126B-P SDK Docker Build Environment

Reproducible Docker build environment for the Rockchip RV1126B-P Linux SDK.

**Architecture:** Build tools in Docker, SDK mounted from host

## Features

- ✅ Based on Ubuntu 24.04 LTS (GCC 13.x - avoids libffi build errors)
- ✅ All build dependencies pre-installed
- ✅ Python 2.7.18 (required by SDK build system)
- ✅ lz4 v1.9.4 (compression utility)
- ✅ Non-root user support (files created with correct permissions)
- ✅ Buildroot download cache (speeds up rebuilds)
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
docker compose build
```

**Build time:** ~5-10 minutes (downloads and compiles Python 2.7.18 and lz4)

### Step 3: Run Container with SDK Mounted

```bash
# Recommended: Run with matching user ID for correct file permissions
UID=$(id -u) GID=$(id -g) docker compose run --rm rv1126b-builder

# Or use default (if SDK is in ../RV1126B-P-SDK)
docker compose run --rm rv1126b-builder

# Or specify custom SDK path
SDK_PATH=/path/to/RV1126B-P-SDK docker compose run --rm rv1126b-builder
```

### Step 4: Build the Firmware (Inside Container)

```bash
cd rv1126b_linux6.1_sdk_v1.1.0
./build.sh lunch
# Select option 9: rockchip_rv1126bp_evb1_v10_defconfig
./build.sh
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

### Permission Denied Errors

Files created by container owned by wrong user? Run with matching UID/GID:

```bash
UID=$(id -u) GID=$(id -g) docker compose run --rm rv1126b-builder
```

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

## Environment Details

- **Base Image:** ubuntu:24.04
- **GCC Version:** 13.x (compatible with SDK, avoids GCC 14.2 libffi errors)
- **Python 2.7:** 2.7.18 (built from source)
- **lz4:** v1.9.4
- **Locale:** en_US.UTF-8
- **Timezone:** Asia/Hong_Kong (configurable)
- **Image Size:** ~2GB (build tools only)
- **SDK Location:** Mounted from host (not in image)

## Related Links

- [SDK Repository](https://github.com/Fanconn-RV1126B-P/RV1126B-P-SDK)
- [SDK Release v1.1.0](https://github.com/Fanconn-RV1126B-P/RV1126B-P-SDK/releases/tag/v1.1.0)
- [Rockchip Documentation](https://github.com/Fanconn-RV1126B-P/RV1126B-P-SDK/tree/main/rv1126b_linux6.1_sdk_v1.1.0/docs)

## License

This Docker environment setup is provided as-is for building the Rockchip RV1126B-P SDK.
See the SDK repository for SDK-specific licensing.
